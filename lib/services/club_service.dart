import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club.dart';

/// Club management service with administrative approval workflow
/// Handles club registration, approval process, ownership validation, and cascade deletion
class ClubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== APPROVAL SYSTEM METHODS ==========

  /// Submit new club for administrative approval instead of direct activation
  /// Prevents unauthorized clubs from appearing in public listings
  Future<void> submitClubForApproval({required Club club}) async {
    try {
      final docRef = _firestore.collection('clubs').doc();

      /// Create club in pending state requiring admin review
      final pendingClub = club.copyWith(
        id: docRef.id,
        isApproved: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(pendingClub.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Administrative interface: retrieve all clubs awaiting approval
  Future<List<Club>> getPendingClubs() async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Club.fromFirestore).toList();
    } catch (e) {
      /// Fallback for missing composite index during development
      try {
        final snapshot = await _firestore
            .collection('clubs')
            .where('isApproved', isEqualTo: false)
            .get();

        final clubs = snapshot.docs.map(Club.fromFirestore).toList();
        clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return clubs;
      } catch (fallbackError) {
        return [];
      }
    }
  }

  /// Administrative action: approve club for public visibility and booking
  Future<void> approveClub(String clubId) async {
    try {
      await _firestore.collection('clubs').doc(clubId).update({
        'isApproved': true,
        'isActive': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Administrative action: reject and remove club application
  Future<void> rejectClub(String clubId) async {
    try {
      await _firestore.collection('clubs').doc(clubId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Public club directory: only approved and active clubs for user discovery
  Future<List<Club>> getApprovedClubs() async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map(Club.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }

  // ========== CLUB OWNER MANAGEMENT ==========

  /// Club owner dashboard: retrieve all owned clubs regardless of approval status
  Future<List<Club>> getOwnedClubs({required String ownerId}) async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final clubs = snapshot.docs.map(Club.fromFirestore).toList();

      /// Manual sorting to avoid composite index requirement
      clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clubs;
    } catch (e) {
      return [];
    }
  }

  /// Club owner operations: only approved clubs for activity management
  Future<List<Club>> getApprovedOwnedClubs({required String ownerId}) async {
    /// Manual filtering approach to avoid composite index complexity
    /// Can be optimized once composite index is fully deployed
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final clubs = snapshot.docs
          .map(Club.fromFirestore)
          .where((club) => club.isApproved && club.isActive)
          .toList();

      clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clubs;
    } catch (e) {
      return [];
    }
  }

  /// Dashboard analytics: total clubs owned across all statuses
  Future<int> getOwnedClubCount({required String ownerId}) async {
    final clubs = await getOwnedClubs(ownerId: ownerId);
    return clubs.length;
  }

  /// Dashboard analytics: operational clubs available for activity management
  Future<int> getApprovedOwnedClubCount({required String ownerId}) async {
    final clubs = await getApprovedOwnedClubs(ownerId: ownerId);
    return clubs.length;
  }

  /// Dashboard analytics: clubs awaiting administrative approval
  Future<int> getPendingOwnedClubCount({required String ownerId}) async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('ownerId', isEqualTo: ownerId)
          .where('isApproved', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Direct club creation bypassing approval (administrative use only)
  Future<void> addClub({required Club club}) async {
    final docRef = club.id.isNotEmpty
        ? _firestore.collection('clubs').doc(club.id)
        : _firestore.collection('clubs').doc();

    await docRef.set(club.toMap());
  }

  /// Update existing club with approval status validation
  Future<void> updateClub(Club club) async {
    try {
      /// Business rule: prevent activation of unapproved clubs
      if (club.isActive && !club.isApproved) {
        throw Exception('Cannot activate club until approved by admin');
      }

      await _firestore.collection('clubs').doc(club.id).update(club.toMap());
    } catch (e) {
      throw Exception('Failed to update club: $e');
    }
  }

  /// Comprehensive club deletion with booking conflict prevention
  /// Validates no active future bookings exist before allowing deletion
  Future<void> deleteClub(String clubId) async {
    try {
      /// Check for active future bookings to prevent data integrity issues
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('clubId', isEqualTo: clubId)
          .get();

      final now = DateTime.now();

      for (final activityDoc in activitiesSnapshot.docs) {
        final activityData = activityDoc.data();
        final activityDate = activityData['date'] is String
            ? DateTime.parse(activityData['date'])
            : (activityData['date'] as Timestamp).toDate();

        /// Only check future activities for active bookings
        if (activityDate.isAfter(now)) {
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('activityId', isEqualTo: activityDoc.id)
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

          if (bookingsSnapshot.docs.isNotEmpty) {
            throw Exception(
              'Cannot delete club: Activity "${activityData['name']}" has ${bookingsSnapshot.docs.length} active booking(s). '
              'Please cancel all future bookings first.',
            );
          }
        }
      }

      /// Cascade deletion: remove all club-related data atomically
      final batch = _firestore.batch();

      /// Remove all club activities (safe after booking validation)
      for (final activityDoc in activitiesSnapshot.docs) {
        batch.delete(activityDoc.reference);
      }

      /// Remove all club facilities
      final facilitiesSnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .get();

      for (final facilityDoc in facilitiesSnapshot.docs) {
        batch.delete(facilityDoc.reference);
      }

      /// Remove the club record itself
      batch.delete(_firestore.collection('clubs').doc(clubId));

      /// Execute all deletions as atomic transaction
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete club: $e');
    }
  }

  /// Soft deletion: temporarily disable club without data loss
  Future<void> deactivateClub(String clubId) async {
    await _firestore.collection('clubs').doc(clubId).update({
      'isActive': false,
    });
  }

  /// Restore previously deactivated club to operational status
  Future<void> reactivateClub(String clubId) async {
    await _firestore.collection('clubs').doc(clubId).update({'isActive': true});
  }

  // ========== UTILITY METHODS ==========

  /// Dashboard metrics: count activities offered by specific club
  Future<int> getActivitiesCount(String clubId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('clubId', isEqualTo: clubId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Retrieve specific club details for management and display
  Future<Club?> getClubById(String clubId) async {
    try {
      final doc = await _firestore.collection('clubs').doc(clubId).get();
      if (doc.exists) {
        return Club.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Administrative dashboard: count clubs awaiting approval
  Future<int> getPendingClubsCount() async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Administrative dashboard: total clubs in system across all statuses
  Future<int> getTotalClubsCount() async {
    try {
      final snapshot = await _firestore.collection('clubs').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
