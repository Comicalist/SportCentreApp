import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility.dart';

class FacilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all facilities for a specific club
  Future<List<Facility>> getClubFacilities({required String clubId}) async {
    try {
      print('Debug: Fetching facilities for clubId: $clubId');

      final querySnapshot = await _firestore
          .collection('facilities')
          .where('clubId', isEqualTo: clubId)
          .get();

      print('Debug: Found ${querySnapshot.docs.length} facility documents');

      final facilities = <Facility>[];
      for (var doc in querySnapshot.docs) {
        try {
          print('Debug: Processing facility doc ID: ${doc.id}');
          print('Debug: Document data: ${doc.data()}');

          final facility = Facility.fromJson(doc.data(), doc.id);
          facilities.add(facility);
          print('Debug: Successfully parsed facility: ${facility.title}');
        } catch (e) {
          print('Debug: Error parsing facility ${doc.id}: $e');
          // Continue with other facilities instead of failing completely
        }
      }

      // Sort manually to avoid needing composite index
      facilities.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      print('Debug: Successfully parsed ${facilities.length} facilities');
      return facilities;
    } catch (e) {
      print('Debug: Error in getClubFacilities: $e');
      print('Debug: Error type: ${e.runtimeType}');
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

  /// Delete a facility
  Future<void> deleteFacility({required String facilityId}) async {
    try {
      await _firestore.collection('facilities').doc(facilityId).delete();
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
