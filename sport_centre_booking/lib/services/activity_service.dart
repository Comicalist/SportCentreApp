import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  // ========== READ OPERATIONS ==========

  /// Get all activities from Firestore
  static Stream<List<Activity>> getActivities() {
    return _firestore
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Use Firestore document ID
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Get activities filtered by category
  static Stream<List<Activity>> getActivitiesByCategory(String category) {
    if (category == 'All') {
      return getActivities();
    }
    
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Get all activities with advanced filtering
  static Stream<List<Activity>> getFilteredActivities({
    String? category,
    String? clubId,
    String? clubName,
    DateTime? date,
    String? timeCategory,
    String? facilityId,
    String? searchQuery,
    bool onlyAvailable = false,
  }) {
    return getActivities().map((activities) {
      return activities.where((activity) {
        // Filter out past activities - only show future activities
        if (activity.isPast) {
          return false;
        }

        // Category filter
        if (category != null && category != 'All' && activity.category != category) {
          return false;
        }

        // Club filter (by ID or name)
        if (clubId != null && clubId.isNotEmpty && activity.clubId != clubId) {
          return false;
        }
        
        if (clubName != null && clubName.isNotEmpty && activity.clubName != clubName) {
          return false;
        }

        // Facility filter (by name since dropdown returns facilityName)
        if (facilityId != null && facilityId.isNotEmpty && activity.facilityName != facilityId) {
          return false;
        }

        // Date filter (exact date match)
        if (date != null) {
          final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
          final filterDate = DateTime(date.year, date.month, date.day);
          if (!activityDate.isAtSameMomentAs(filterDate)) {
            return false;
          }
        }

        // Time category filter
        if (timeCategory != null && timeCategory.isNotEmpty && activity.timeCategory != timeCategory) {
          return false;
        }

        // Search query filter (search in name, description, club, facility)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!activity.name.toLowerCase().contains(query) &&
              !activity.description.toLowerCase().contains(query) &&
              !activity.clubName.toLowerCase().contains(query) &&
              !activity.facilityName.toLowerCase().contains(query) &&
              !activity.category.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Availability filter
        if (onlyAvailable && !activity.hasAvailableSpots) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  /// Get a single activity by ID
  static Future<Activity?> getActivity(String activityId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(activityId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  /// Get single activity by ID (alias)
  static Future<Activity?> getActivityById(String activityId) async {
    return getActivity(activityId);
  }

  // ========== CLUB OWNER OPERATIONS ==========

  /// Get activities for a specific club (for club owners)
  static Stream<List<Activity>> getActivitiesByClub(String clubId) {
    return _firestore
        .collection(_collection)
        .where('clubId', isEqualTo: clubId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Get activities for a specific facility
  static Stream<List<Activity>> getActivitiesByFacility(String facilityId) {
    return _firestore
        .collection(_collection)
        .where('facilityId', isEqualTo: facilityId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Get count of activities for a club (for dashboard stats)
  static Future<int> getClubActivityCount(String clubId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clubId', isEqualTo: clubId)
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting club activity count: $e');
      return 0;
    }
  }

  // ========== CREATE / UPDATE / DELETE OPERATIONS ==========

  /// Create a new activity (with club owner authorization check)
  static Future<String> createActivity({
    required Activity activity,
    required String currentUserId,
  }) async {
    try {
      print('🔄 CREATING ACTIVITY:');
      print('   Name: ${activity.name}');
      print('   Club ID: ${activity.clubId}');
      print('   Facility ID: ${activity.facilityId}');
      print('   Created by: $currentUserId');

      // 🔒 VALIDATION 1: Verify user owns the club
      final clubDoc = await _firestore
          .collection('clubs')
          .doc(activity.clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data()!;
      final clubOwnerId = clubData['ownerId'] as String;
      final isApproved = clubData['isApproved'] as bool? ?? false;

      if (clubOwnerId != currentUserId) {
        throw Exception('Unauthorized: You do not own this club');
      }

      // 🔒 VALIDATION 2: Verify club is approved
      if (!isApproved) {
        throw Exception('Cannot create activities for unapproved clubs. Please wait for admin approval.');
      }

      // 🔒 VALIDATION 3: Verify facility belongs to club
      final facilityDoc = await _firestore
          .collection('facilities')
          .doc(activity.facilityId)
          .get();

      if (!facilityDoc.exists) {
        throw Exception('Facility not found');
      }

      final facilityData = facilityDoc.data()!;
      final facilityClubId = facilityData['clubId'] as String;
      final facilityMaxCapacity = facilityData['maxCapacity'] as int;
      final facilityIsActive = facilityData['isActive'] as bool? ?? true;

      if (facilityClubId != activity.clubId) {
        throw Exception('Invalid: Facility does not belong to this club');
      }

      // 🔒 VALIDATION 4: Verify facility is active
      if (!facilityIsActive) {
        throw Exception('Cannot create activities for inactive facilities');
      }

      // 🔒 VALIDATION 5: Verify capacity doesn't exceed facility maximum
      if (activity.capacity > facilityMaxCapacity) {
        throw Exception('Capacity (${activity.capacity}) exceeds facility maximum ($facilityMaxCapacity)');
      }

      // ✅ All validations passed - create activity
      final activityData = activity.toJson();
      
      // Remove the id field before adding (Firestore will generate one)
      activityData.remove('id');

      final docRef = await _firestore.collection(_collection).add(activityData);

      print('✅ ACTIVITY CREATED SUCCESSFULLY!');
      print('   Document ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('❌ ERROR CREATING ACTIVITY: $e');
      rethrow;
    }
  }

  /// Update an existing activity (with authorization check)
  static Future<void> updateActivity({
    required Activity activity,
    required String currentUserId,
  }) async {
    try {
      print('🔄 UPDATING ACTIVITY: ${activity.id}');

      // 🔒 VALIDATION: Verify user owns the club
      final clubDoc = await _firestore
          .collection('clubs')
          .doc(activity.clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubOwnerId = clubDoc.data()!['ownerId'] as String;

      if (clubOwnerId != currentUserId) {
        throw Exception('Unauthorized: You do not own this club');
      }

      // Update with new timestamp
      final activityData = activity.copyWith(
        updatedAt: DateTime.now(),
      ).toJson();

      // Remove id field (not stored in document)
      activityData.remove('id');

      await _firestore
          .collection(_collection)
          .doc(activity.id)
          .update(activityData);

      print('✅ ACTIVITY UPDATED SUCCESSFULLY');
    } catch (e) {
      print('❌ ERROR UPDATING ACTIVITY: $e');
      rethrow;
    }
  }

  /// Delete an activity (with authorization check)
  static Future<void> deleteActivity({
    required String activityId,
    required String clubId,
    required String currentUserId,
  }) async {
    try {
      print('🔄 DELETING ACTIVITY: $activityId');

      // Get activity to check date
      final activityDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();
      
      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data()!;
      
      // Get activity date
      final activityDate = activityData['date'] is String
          ? DateTime.parse(activityData['date'])
          : (activityData['date'] as Timestamp).toDate();

      // 🔒 VALIDATION: Verify user owns the club
      final clubDoc = await _firestore
          .collection('clubs')
          .doc(clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubOwnerId = clubDoc.data()!['ownerId'] as String;

      if (clubOwnerId != currentUserId) {
        throw Exception('Unauthorized: You do not own this club');
      }

      // Check only for FUTURE bookings (if activity is in the future)
      if (activityDate.isAfter(DateTime.now())) {
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('activityId', isEqualTo: activityId)
            .where('status', whereIn: ['confirmed', 'pending'])
            .get();

        if (bookingsSnapshot.docs.isNotEmpty) {
          throw Exception(
            'Cannot delete activity: ${bookingsSnapshot.docs.length} active booking(s) exist. '
            'Please cancel all bookings first.'
          );
        }
      }

      await _firestore.collection(_collection).doc(activityId).delete();
      print('✅ ACTIVITY DELETED SUCCESSFULLY');
    } catch (e) {
      print('❌ ERROR DELETING ACTIVITY: $e');
      rethrow;
    }
  }

  /// Add a new activity (simple version without validation - for admin use)
  static Future<void> addActivity(Activity activity) async {
    try {
      Map<String, dynamic> activityData = activity.toJson();
      activityData.remove('id'); // Don't include the ID in the document data
      
      await _firestore.collection(_collection).add(activityData);
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Get unique clubs for dropdown (using clubName from activities)
  static Future<List<String>> getAvailableClubs() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      Set<String> clubs = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['clubName'] != null) {
          clubs.add(data['clubName']);
        }
      }
      
      List<String> clubList = clubs.toList();
      clubList.sort();
      return clubList;
    } catch (e) {
      return [];
    }
  }

  /// Get unique clubs as a real-time stream
  static Stream<List<String>> getAvailableClubsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      Set<String> clubs = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['clubName'] != null) {
          clubs.add(data['clubName']);
        }
      }
      
      List<String> clubList = clubs.toList();
      clubList.sort();
      return clubList;
    });
  }

  /// Get unique facilities for dropdown (using facilityName from activities)
  static Future<List<String>> getAvailableFacilities() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      Set<String> facilities = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      List<String> facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    } catch (e) {
      return [];
    }
  }

  /// Get unique facilities as a real-time stream
  static Stream<List<String>> getAvailableFacilitiesStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      Set<String> facilities = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      List<String> facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    });
  }

  /// Get unique facilities for a specific club as a real-time stream
  static Stream<List<String>> getAvailableFacilitiesStreamByClub(String clubName) {
    return _firestore
        .collection(_collection)
        .where('clubName', isEqualTo: clubName)
        .snapshots()
        .map((snapshot) {
      Set<String> facilities = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      List<String> facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    });
  }

  /// Get unique categories from database
  static Future<List<String>> getAvailableCategories() async {
    final snapshot = await _firestore.collection(_collection).get();
    Set<String> categories = {};
    
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['category'] != null) {
        categories.add(data['category']);
      }
    }
    
    List<String> categoryList = categories.toList();
    categoryList.sort();
    return categoryList;
  }

  /// Get unique categories as a real-time stream
  static Stream<List<String>> getAvailableCategoriesStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      Set<String> categories = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }
      
      List<String> categoryList = categories.toList();
      categoryList.sort();
      return categoryList;
    });
  }
}
