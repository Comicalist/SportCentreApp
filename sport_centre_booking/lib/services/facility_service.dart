import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility.dart';

class FacilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all facilities for a specific club
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
          // Continue with other facilities instead of failing completely
        }
      }

      // Sort manually to avoid needing composite index
      facilities.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return facilities;
    } catch (e) {
      throw Exception('Failed to fetch facilities: $e');
    }
  }

  /// Get count of facilities for a club (for dashboard stats)
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

  /// Add a new facility to a club
  Future<Facility> addFacility({required Facility facility}) async {
    try {
      final docRef = await _firestore
          .collection('facilities')
          .add(facility.toJson());

      // Return the facility with the generated ID
      return facility.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to add facility: $e');
    }
  }

  /// Update an existing facility
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

  /// Delete a facility and all its activities (with validation)
  Future<void> deleteFacility({required String facilityId}) async {
    try {
      // 1️⃣ Check for active future bookings in facility's activities
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
              'Cannot delete facility: Activity "${activityData['name']}" has ${bookingsSnapshot.docs.length} active booking(s). '
              'Please cancel all future bookings first.',
            );
          }
        }
      }

      // 2️⃣ Delete all activities (no active future bookings at this point)
      final batch = _firestore.batch();

      for (final activityDoc in activitiesSnapshot.docs) {
        batch.delete(activityDoc.reference);
      }

      // 3️⃣ Delete the facility itself
      batch.delete(_firestore.collection('facilities').doc(facilityId));

      // Commit all deletions
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete facility: $e');
    }
  }

  /// Get single facility by ID
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

  /// Check if club has any facilities (for validation)
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
