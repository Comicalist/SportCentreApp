import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import 'blocking_service.dart';

/// Activity management service for sport centre booking system
/// Handles activity CRUD operations, filtering, authorization, and conflict detection
class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  // ========== READ OPERATIONS ==========

  /// Real-time stream of all activities ordered chronologically
  static Stream<List<Activity>> getActivities() {
    return _firestore
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Use Firestore document ID
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Activity catalog filtered by category with real-time updates
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
        final data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Advanced activity discovery with multi-criteria filtering
  /// Supports search, availability, club, facility, date, and time filters
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
        /// Exclude past activities from public booking interface
        if (activity.isPast) {
          return false;
        }

        /// Category-based activity filtering
        if (category != null && category != 'All' && activity.category != category) {
          return false;
        }

        /// Club-specific filtering for targeted discovery
        if (clubId != null && clubId.isNotEmpty && activity.clubId != clubId) {
          return false;
        }
        
        if (clubName != null && clubName.isNotEmpty && activity.clubName != clubName) {
          return false;
        }

        /// Facility-based filtering using display name
        if (facilityId != null && facilityId.isNotEmpty && activity.facilityName != facilityId) {
          return false;
        }

        /// Exact date matching for calendar-based browsing
        if (date != null) {
          final activityDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
          final filterDate = DateTime(date.year, date.month, date.day);
          if (!activityDate.isAtSameMomentAs(filterDate)) {
            return false;
          }
        }

        /// Time-of-day categorization filtering
        if (timeCategory != null && timeCategory.isNotEmpty && activity.timeCategory != timeCategory) {
          return false;
        }

        /// Full-text search across multiple activity attributes
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

        /// Booking availability filtering for immediate bookings
        if (onlyAvailable && !activity.hasAvailableSpots) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  /// Retrieve single activity with full details for booking
  static Future<Activity?> getActivity(String activityId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(activityId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  /// Stream a single activity for real-time updates (e.g., capacity changes)
  static Stream<Activity?> getActivityStream(String activityId) {
    return _firestore
        .collection(_collection)
        .doc(activityId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }
      return null;
    });
  }

  /// Activity lookup by ID - convenience method for consistent API
  static Future<Activity?> getActivityById(String activityId) async {
    return getActivity(activityId);
  }

  // ========== CLUB OWNER OPERATIONS ==========

  /// Club owner's activity management dashboard with chronological ordering
  static Stream<List<Activity>> getActivitiesByClub(String clubId) {
    return _firestore
        .collection(_collection)
        .where('clubId', isEqualTo: clubId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Facility-specific activity schedule for resource management
  static Stream<List<Activity>> getActivitiesByFacility(String facilityId) {
    return _firestore
        .collection(_collection)
        .where('facilityId', isEqualTo: facilityId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }).toList();
    });
  }

  /// Club activity metrics for dashboard statistics
  static Future<int> getClubActivityCount(String clubId) async {

      final snapshot = await _firestore
          .collection(_collection)
          .where('clubId', isEqualTo: clubId)
          .get();
      return snapshot.size;
  }

  // ========== CREATE / UPDATE / DELETE OPERATIONS ==========

  /// Secure activity creation with comprehensive validation and authorization
  /// Enforces club ownership, approval status, facility validation, and time slot availability
  static Future<String> createActivity({
    required Activity activity,
    required String currentUserId,
  }) async {
    try {
      /// Verify club ownership and authorization
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

      /// Prevent activity creation for unapproved clubs
      if (!isApproved) {
        throw Exception('Cannot create activities for unapproved clubs. Please wait for admin approval.');
      }

      /// Validate facility ownership and operational status
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

      /// Ensure facility is available for bookings
      if (!facilityIsActive) {
        throw Exception('Cannot create activities for inactive facilities');
      }

      /// Check for facility/club time blocking conflicts
      final blockStatus = await BlockingService.isTimeSlotBlocked(
        facilityId: activity.facilityId,
        activityDate: activity.date,
        activityTime: activity.time,
        durationMinutes: activity.duration,
      );

      if (blockStatus.isBlocked) {
        final sourceText = blockStatus.source == 'club' ? 'Club' : 'Facility';
        final reasonText = (blockStatus.reason != null && blockStatus.reason!.isNotEmpty)
            ? ' Reason: ${blockStatus.reason}'
            : '';
        throw Exception(
          'Cannot create activity: $sourceText is blocked during this time.$reasonText',
        );
      }

      /// Validate capacity constraints against facility limits
      if (activity.capacity > facilityMaxCapacity) {
        throw Exception('Capacity (${activity.capacity}) exceeds facility maximum ($facilityMaxCapacity)');
      }

      /// Create validated activity in Firestore
      final activityData = activity.toJson();
      
      activityData.remove('id');

      final docRef = await _firestore.collection(_collection).add(activityData);

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing activity with ownership verification and timestamp tracking
  static Future<void> updateActivity({
    required Activity activity,
    required String currentUserId,
  }) async {
    try {

      /// Verify club ownership for update authorization
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

      /// Apply updates with modification timestamp
      final activityData = activity.copyWith(
        updatedAt: DateTime.now(),
      ).toJson();

      activityData.remove('id');

      await _firestore
          .collection(_collection)
          .doc(activity.id)
          .update(activityData);

    } catch (e) {
      rethrow;
    }
  }

  /// Secure activity deletion with booking conflict prevention
  /// Prevents deletion of activities with active future bookings
  static Future<void> deleteActivity({
    required String activityId,
    required String clubId,
    required String currentUserId,
  }) async {
    try {

      /// Retrieve activity for date validation
      final activityDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();
      
      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data()!;
      
      final activityDate = activityData['date'] is String
          ? DateTime.parse(activityData['date'])
          : (activityData['date'] as Timestamp).toDate();

      /// Verify club ownership for deletion authorization
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

      /// Protect against deletion of activities with active bookings
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
    } catch (e) {
      rethrow;
    }
  }

  /// Administrative activity creation without business validation constraints
  static Future<void> addActivity(Activity activity) async {
    try {
      final activityData = activity.toJson();
      activityData.remove('id');
      
      await _firestore.collection(_collection).add(activityData);
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Extract unique club names for filtering dropdown population
  static Future<List<String>> getAvailableClubs() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      final clubs = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['clubName'] != null) {
          clubs.add(data['clubName']);
        }
      }
      
      final clubList = clubs.toList();
      clubList.sort();
      return clubList;
    } catch (e) {
      return [];
    }
  }

  /// Real-time club discovery for dynamic filter updates
  static Stream<List<String>> getAvailableClubsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final clubs = <String>{};
      
      for (final QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['clubName'] != null) {
          clubs.add(data['clubName']);
        }
      }
      
      final clubList = clubs.toList();
      clubList.sort();
      return clubList;
    });
  }

  /// Extract unique facility names for location-based filtering
  static Future<List<String>> getAvailableFacilities() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      final facilities = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      final facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    } catch (e) {
      return [];
    }
  }

  /// Real-time facility discovery for location-based browsing
  static Stream<List<String>> getAvailableFacilitiesStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final facilities = <String>{};
      
      for (final QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      final facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    });
  }

  /// Club-specific facility discovery for activity creation
  static Stream<List<String>> getAvailableFacilitiesStreamByClub(String clubId) {
    return _firestore
        .collection(_collection)
        .where('clubId', isEqualTo: clubId)
        .snapshots()
        .map((snapshot) {
      final facilities = <String>{};
      
      for (final QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['facilityName'] != null) {
          facilities.add(data['facilityName']);
        }
      }
      
      final facilityList = facilities.toList();
      facilityList.sort();
      return facilityList;
    });
  }

  /// Extract activity categories for classification and filtering
  static Future<List<String>> getAvailableCategories() async {
    final snapshot = await _firestore.collection(_collection).get();
    final categories = <String>{};
    
    for (final QueryDocumentSnapshot doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      if (data['category'] != null) {
        categories.add(data['category']);
      }
    }
    
    final categoryList = categories.toList();
    categoryList.sort();
    return categoryList;
  }

  /// Real-time category discovery for dynamic filter population
  static Stream<List<String>> getAvailableCategoriesStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final categories = <String>{};
      
      for (final QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }
      
      final categoryList = categories.toList();
      categoryList.sort();
      return categoryList;
    });
  }
}
