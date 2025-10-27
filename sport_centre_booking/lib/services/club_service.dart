import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club.dart';

class ClubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== APPROVAL SYSTEM METHODS ==========

  /// Submit a club for approval (instead of directly adding)
  Future<void> submitClubForApproval({required Club club}) async {
    try {
      final docRef = _firestore.collection('clubs').doc();

      // Create club with pending approval status
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

  /// Admin: Get all pending clubs for approval
  Future<List<Club>> getPendingClubs() async {
    try {
    

      final snapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

    
      for (var doc in snapshot.docs) {
   
      }

      return snapshot.docs.map((doc) => Club.fromFirestore(doc)).toList();
    } catch (e) {
 

      // Fallback: try without ordering
      try {
     
        final snapshot = await _firestore
            .collection('clubs')
            .where('isApproved', isEqualTo: false)
            .get();

        final clubs = snapshot.docs
            .map((doc) => Club.fromFirestore(doc))
            .toList();
        clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

 
        return clubs;
      } catch (fallbackError) {

        return [];
      }
    }
  }

  /// Admin: Approve a club
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

  /// Admin: Reject a club
  Future<void> rejectClub(String clubId) async {
    try {
    
      await _firestore.collection('clubs').doc(clubId).delete();

    } catch (e) {
     
      rethrow;
    }
  }

  /// Get only approved clubs for normal users
  Future<List<Club>> getApprovedClubs() async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Club.fromFirestore(doc)).toList();
    } catch (e) {
     
      return [];
    }
  }

  // ========== EXISTING METHODS (UPDATED) ==========

  /// Fetch all clubs owned by a specific user (both approved and pending)
  Future<List<Club>> getOwnedClubs({required String ownerId}) async {
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final clubs = snapshot.docs
          .map((doc) => Club.fromFirestore(doc))
          .toList();
      
      // Sort manually to avoid needing composite index
      clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clubs;
    } catch (e) {
   
      return [];
    }
  }

  /// Fetch only approved clubs owned by a specific user
  Future<List<Club>> getApprovedOwnedClubs({required String ownerId}) async {
    
    // Use manual filtering approach to avoid composite index issues
    // Once the composite index is fully built, this can be optimized
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      final clubs = snapshot.docs
          .map((doc) => Club.fromFirestore(doc))
          .where((club) => club.isApproved && club.isActive)
          .toList();
      
      clubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return clubs;
    } catch (e) {
      return [];
    }
  }

  /// Count of owned clubs for dashboard stats (all statuses)
  Future<int> getOwnedClubCount({required String ownerId}) async {
    final clubs = await getOwnedClubs(ownerId: ownerId);
    return clubs.length;
  }

  /// Count of approved owned clubs for dashboard stats
  Future<int> getApprovedOwnedClubCount({required String ownerId}) async {
    final clubs = await getApprovedOwnedClubs(ownerId: ownerId);
    return clubs.length;
  }

  /// Count of pending owned clubs
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

  /// Add a new club directly (use only for admin or testing - prefer submitClubForApproval)
  Future<void> addClub({required Club club}) async {
    final docRef = club.id.isNotEmpty
        ? _firestore.collection('clubs').doc(club.id)
        : _firestore.collection('clubs').doc();

    await docRef.set(club.toMap());
  }

  // update Club method:
  Future<void> updateClub(Club club) async {
    try {
      // Prevent activating unapproved clubs on server side
      if (club.isActive && !club.isApproved) {
        throw Exception('Cannot activate club until approved by admin');
      }

      await _firestore.collection('clubs').doc(club.id).update(club.toMap());
    } catch (e) {
      throw Exception('Failed to update club: $e');
    }
  }

  /// Delete a club and all its facilities and activities (with validation)
  Future<void> deleteClub(String clubId) async {
    try {
      // 1️⃣ Check for active future bookings in club's activities
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('clubId', isEqualTo: clubId)
          .get();

      final now = DateTime.now();
      
      for (var activityDoc in activitiesSnapshot.docs) {
        final activityData = activityDoc.data();
        final activityDate = activityData['date'] is String
            ? DateTime.parse(activityData['date'])
            : (activityData['date'] as Timestamp).toDate();

        // Check if activity is in the future
        if (activityDate.isAfter(now)) {
          // Check for active bookings
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('activityId', isEqualTo: activityDoc.id)
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

          if (bookingsSnapshot.docs.isNotEmpty) {
            throw Exception(
              'Cannot delete club: Activity "${activityData['name']}" has ${bookingsSnapshot.docs.length} active booking(s). '
              'Please cancel all future bookings first.'
            );
          }
        }
      }

      // 2️⃣ Delete all activities (no active future bookings at this point)
      final batch = _firestore.batch();
      
      for (var activityDoc in activitiesSnapshot.docs) {
        batch.delete(activityDoc.reference);
      }

      // 3️⃣ Delete all facilities
      final facilitiesSnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .get();

      for (var facilityDoc in facilitiesSnapshot.docs) {
        batch.delete(facilityDoc.reference);
      }

      // 4️⃣ Delete the club itself
      batch.delete(_firestore.collection('clubs').doc(clubId));

      // Commit all deletions
      await batch.commit();
      
    } catch (e) {
      throw Exception('Failed to delete club: $e');
    }
  }

  /// Soft delete - deactivate a club
  Future<void> deactivateClub(String clubId) async {
    await _firestore.collection('clubs').doc(clubId).update({
      'isActive': false,
    });
  }

  /// Reactivate a club
  Future<void> reactivateClub(String clubId) async {
    await _firestore.collection('clubs').doc(clubId).update({'isActive': true});
  }

  // ========== UTILITY METHODS ==========

  /// Optional: Fetch number of activities in a club (for dashboard)
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

  /// Get club by ID
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

  /// Get pending clubs count for admin dashboard
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

  /// Get total clubs count (for admin)
  Future<int> getTotalClubsCount() async {
    try {
      final snapshot = await _firestore.collection('clubs').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
