import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility.dart';

/// Facility management service for club infrastructure and resource allocation
/// Handles facility CRUD operations, booking conflict validation, and capacity management
class FacilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieve all facilities owned by a specific club for management interface
  /// Provides robust error handling for individual facility parsing failures
  Future<List<Facility>> getClubFacilities({required String clubId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .get();

      final facilities = <Facility>[];
      for (final doc in querySnapshot.docs) {
        try {
          final facility = Facility.fromJson(doc.data(), doc.id);
          facilities.add(facility);
        } catch (e) {
          /// Continue processing other facilities if individual parsing fails
        }
      }

      /// Manual sorting to avoid composite index requirements during development
      facilities.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return facilities;
    } catch (e) {
      throw Exception('Failed to fetch facilities: $e');
    }
  }

  /// Club dashboard metrics: count total facilities for capacity planning
  Future<int> getClubFacilityCount({required String clubId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Failed to count facilities: $e');
    }
  }

  /// Create new facility for club infrastructure expansion
  /// Returns facility with generated ID for immediate UI updates
  Future<Facility> addFacility({required Facility facility}) async {
    try {
      final docRef = await _firestore
          .collection('facilities')
          .add(facility.toJson());

      return facility.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to add facility: $e');
    }
  }

  /// Update existing facility configuration with automatic timestamp tracking
  Future<void> updateFacility({required Facility facility}) async {
    try {
      await _firestore
          .collection('facilities')
          .doc(facility.id)
          .update(facility.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update facility: $e');
    }
  }

  /// Comprehensive facility deletion with booking conflict prevention
  /// Validates no active future bookings exist before allowing removal
  Future<void> deleteFacility({required String facilityId}) async {
    try {
      /// Check for active future bookings to prevent data integrity issues
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('facilityId', isEqualTo: facilityId)
          .get();

      final now = DateTime.now();

      for (final activityDoc in activitiesSnapshot.docs) {
        final activityData = activityDoc.data();
        final activityDate = activityData['date'] is String
            ? DateTime.parse(activityData['date'])
            : (activityData['date'] as Timestamp).toDate();

        /// Only validate future activities for active booking conflicts
        if (activityDate.isAfter(now)) {
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('activityId', isEqualTo: activityDoc.id)
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

          if (bookingsSnapshot.docs.isNotEmpty) {
            throw Exception(
              'Cannot delete facility: Activity "${activityData['name']}" has ${bookingsSnapshot.docs.length} active booking(s). '
              'Please cancel all future bookings first.',
            );
          }
        }
      }

      /// Cascade deletion: remove all facility-related activities atomically
      final batch = _firestore.batch();

      /// Remove all activities hosted in this facility
      for (final activityDoc in activitiesSnapshot.docs) {
        batch.delete(activityDoc.reference);
      }

      /// Remove the facility record itself
      batch.delete(_firestore.collection('facilities').doc(facilityId));

      /// Execute all deletions as atomic transaction
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete facility: $e');
    }
  }

  /// Retrieve specific facility details for editing and activity management
  Future<Facility?> getFacility({required String facilityId}) async {
    try {
      final doc = await _firestore
          .collection('facilities')
          .doc(facilityId)
          .get();

      if (doc.exists) {
        return Facility.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch facility: $e');
    }
  }

  /// Business validation: ensure club has infrastructure before activity creation
  Future<bool> clubHasFacilities({required String clubId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
