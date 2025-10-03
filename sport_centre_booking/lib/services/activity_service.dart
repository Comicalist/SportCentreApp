import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

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
    String? club,
    DateTime? date,
    String? timeCategory,
    String? location,
    String? searchQuery,
    bool onlyAvailable = false,
  }) {
    return getActivities().map((activities) {
      final now = DateTime.now();
      
      return activities.where((activity) {
        // Filter out past activities - only show future activities
        try {
          // Parse time string (format: "HH:mm")
          final timeParts = activity.time.split(':');
          if (timeParts.length != 2) return true; // If time format is invalid, show the activity
          
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          final activityDateTime = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
            hour,
            minute,
          );
          
          if (activityDateTime.isBefore(now)) {
            return false;
          }
        } catch (e) {
          // If there's any error parsing the time, show the activity
          print('Error parsing time for activity ${activity.name}: $e');
        }

        // Category filter
        if (category != null && category != 'All' && activity.category != category) {
          return false;
        }

        // Club filter
        if (club != null && club.isNotEmpty && activity.club != club) {
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

        // Location filter
        if (location != null && location.isNotEmpty && activity.location != location) {
          return false;
        }

        // Search query filter (name and description)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final nameMatch = activity.name.toLowerCase().contains(query);
          final descriptionMatch = activity.description.toLowerCase().contains(query);
          if (!nameMatch && !descriptionMatch) {
            return false;
          }
        }

        // Available spots filter
        if (onlyAvailable && activity.spotsLeft <= 0) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  /// Add a new activity to Firestore
  static Future<String> addActivity(Activity activity) async {
    try {
      // Don't include the ID in the data since Firestore will generate it
      Map<String, dynamic> activityData = activity.toJson();
      activityData.remove('id');
      
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(activityData);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  /// Update an existing activity
  static Future<void> updateActivity(Activity activity) async {
    try {
      Map<String, dynamic> activityData = activity.toJson();
      activityData.remove('id'); // Don't update the ID field
      
      await _firestore
          .collection(_collection)
          .doc(activity.id)
          .update(activityData);
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  /// Delete an activity
  static Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(activityId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Get a single activity by ID
  static Future<Activity?> getActivity(String activityId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(activityId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Activity.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  /// Add sample activities for testing
  static Future<void> addSampleActivities() async {
    final sampleActivities = [
      // Yoga Club Activities
      Activity(
        id: '',
        name: 'Morning Yoga Flow',
        description: 'Start your day with energizing yoga poses and mindful breathing exercises',
        category: 'Wellness',
        club: 'Yoga Club',
        date: DateTime.now().add(const Duration(days: 1)),
        time: '07:00',
        timeCategory: Activity.getTimeCategory('07:00'),
        location: 'Downtown Sports Club',
        price: 15.0,
        pointsReward: 50,
        capacity: 15,
        bookedCount: 10, // 10 people already booked
        spotsLeft: 5,
        imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
        requirements: ['Yoga mat', 'Water bottle'],
      ),
      Activity(
        id: '',
        name: 'Evening Restorative Yoga',
        description: 'Gentle stretches and meditation to unwind after a busy day',
        category: 'Wellness',
        club: 'Yoga Club',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '19:00',
        timeCategory: Activity.getTimeCategory('19:00'),
        location: 'Zen Wellness Center',
        price: 18.0,
        pointsReward: 55,
        capacity: 12,
        bookedCount: 12, // Full class
        spotsLeft: 0, // Full class
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop',
        requirements: ['Yoga mat', 'Blanket'],
      ),
      Activity(
        id: '',
        name: 'Power Vinyasa',
        description: 'Dynamic flowing sequences for strength and flexibility',
        category: 'Wellness',
        club: 'Yoga Club',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '12:30',
        timeCategory: Activity.getTimeCategory('12:30'),
        location: 'Downtown Sports Club',
        price: 20.0,
        pointsReward: 65,
        capacity: 10,
        bookedCount: 7, // 7 people already booked
        spotsLeft: 3,
        imageUrl: 'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=300&h=200&fit=crop',
        requirements: ['Yoga mat', 'Towel'],
      ),

      // Fitness Club Activities
      Activity(
        id: '',
        name: 'HIIT Training',
        description: 'High-intensity interval training for maximum calorie burn and fitness',
        category: 'Fitness',
        club: 'Fitness Club',
        date: DateTime.now().add(const Duration(days: 1)),
        time: '18:00',
        timeCategory: Activity.getTimeCategory('18:00'),
        location: 'Westside Fitness Center',
        price: 20.0,
        pointsReward: 75,
        capacity: 12,
        bookedCount: 9, // 9 people already booked
        spotsLeft: 3,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Towel', 'Water bottle'],
      ),
      Activity(
        id: '',
        name: 'CrossFit Fundamentals',
        description: 'Learn basic CrossFit movements with proper form and technique',
        category: 'Fitness',
        club: 'Fitness Club',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '06:30',
        timeCategory: Activity.getTimeCategory('06:30'),
        location: 'Iron Gym',
        price: 25.0,
        pointsReward: 85,
        capacity: 8,
        bookedCount: 6, // 6 people already booked
        spotsLeft: 2,
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop',
        requirements: ['Athletic shoes', 'Water bottle'],
      ),
      Activity(
        id: '',
        name: 'Strength & Conditioning',
        description: 'Build muscle and improve overall strength with guided workouts',
        category: 'Fitness',
        club: 'Fitness Club',
        date: DateTime.now().add(const Duration(days: 4)),
        time: '17:30',
        timeCategory: Activity.getTimeCategory('17:30'),
        location: 'Westside Fitness Center',
        price: 22.0,
        pointsReward: 80,
        capacity: 15,
        bookedCount: 7, // 7 people already booked
        spotsLeft: 8,
        imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=300&h=200&fit=crop',
        requirements: ['Gym gloves', 'Towel'],
      ),

      // Swimming Club Activities
      Activity(
        id: '',
        name: 'Kids Swimming Lessons',
        description: 'Fun swimming lessons for children aged 6-12 with certified instructors',
        category: 'Kids',
        club: 'Swimming Club',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '16:00',
        timeCategory: Activity.getTimeCategory('16:00'),
        location: 'Aquatic Center',
        price: 25.0,
        pointsReward: 60,
        capacity: 8,
        spotsLeft: 2,
        imageUrl: 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=300&h=200&fit=crop',
        requirements: ['Swimwear', 'Towel', 'Swimming cap'],
      ),
      Activity(
        id: '',
        name: 'Adult Swim Training',
        description: 'Improve your swimming technique and endurance with professional coaching',
        category: 'Fitness',
        club: 'Swimming Club',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '07:30',
        timeCategory: Activity.getTimeCategory('07:30'),
        location: 'Aquatic Center',
        price: 30.0,
        pointsReward: 90,
        capacity: 6,
        spotsLeft: 1,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Swimwear', 'Goggles', 'Towel'],
      ),
      Activity(
        id: '',
        name: 'Water Aerobics',
        description: 'Low-impact fitness class in the pool suitable for all fitness levels',
        category: 'Wellness',
        club: 'Swimming Club',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '14:00',
        timeCategory: Activity.getTimeCategory('14:00'),
        location: 'Aquatic Center',
        price: 18.0,
        pointsReward: 55,
        capacity: 12,
        spotsLeft: 7,
        imageUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=300&h=200&fit=crop',
        requirements: ['Swimwear', 'Water shoes'],
      ),

      // Boxing Club Activities
      Activity(
        id: '',
        name: 'Boxing Fundamentals',
        description: 'Learn basic boxing techniques and improve your fitness and coordination',
        category: 'Fitness',
        club: 'Boxing Club',
        date: DateTime.now().add(const Duration(days: 4)),
        time: '19:30',
        timeCategory: Activity.getTimeCategory('19:30'),
        location: 'Fight Club Gym',
        price: 22.0,
        pointsReward: 80,
        capacity: 6,
        spotsLeft: 1,
        imageUrl: 'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=300&h=200&fit=crop',
        requirements: ['Hand wraps', 'Water bottle'],
      ),
      Activity(
        id: '',
        name: 'Kickboxing Cardio',
        description: 'High-energy cardio workout combining martial arts and fitness',
        category: 'Fitness',
        club: 'Boxing Club',
        date: DateTime.now().add(const Duration(days: 6)),
        time: '18:30',
        timeCategory: Activity.getTimeCategory('18:30'),
        location: 'Fight Club Gym',
        price: 20.0,
        pointsReward: 75,
        capacity: 10,
        spotsLeft: 4,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Athletic shoes', 'Water bottle'],
      ),

      // Pilates Club Activities
      Activity(
        id: '',
        name: 'Pilates Core Strength',
        description: 'Build core strength and flexibility with controlled movements and breathing',
        category: 'Wellness',
        club: 'Pilates Club',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '12:00',
        timeCategory: Activity.getTimeCategory('12:00'),
        location: 'Downtown Sports Club',
        price: 18.0,
        pointsReward: 55,
        capacity: 10,
        spotsLeft: 0, // Full activity for testing
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=300&h=200&fit=crop',
        requirements: ['Yoga mat'],
      ),
      Activity(
        id: '',
        name: 'Pilates Reformer',
        description: 'Advanced Pilates using reformer machines for full-body conditioning',
        category: 'Wellness',
        club: 'Pilates Club',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '09:00',
        timeCategory: Activity.getTimeCategory('09:00'),
        location: 'Zen Wellness Center',
        price: 35.0,
        pointsReward: 100,
        capacity: 4,
        spotsLeft: 2,
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=300&h=200&fit=crop',
        requirements: ['Grip socks'],
      ),

      // Arts & Crafts Club Activities
      Activity(
        id: '',
        name: 'Pottery Workshop',
        description: 'Create beautiful ceramic pieces while learning pottery basics and glazing techniques',
        category: 'Workshops',
        club: 'Arts & Crafts Club',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '14:00',
        timeCategory: Activity.getTimeCategory('14:00'),
        location: 'Creative Arts Studio',
        price: 35.0,
        pointsReward: 90,
        capacity: 12,
        spotsLeft: 7,
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=200&fit=crop',
        requirements: ['Apron'],
      ),
      Activity(
        id: '',
        name: 'Painting Masterclass',
        description: 'Explore watercolor and acrylic techniques with a professional artist',
        category: 'Workshops',
        club: 'Arts & Crafts Club',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '10:00',
        timeCategory: Activity.getTimeCategory('10:00'),
        location: 'Creative Arts Studio',
        price: 40.0,
        pointsReward: 95,
        capacity: 8,
        spotsLeft: 3,
        imageUrl: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=300&h=200&fit=crop',
        requirements: ['Apron', 'Old clothes'],
      ),

      // Kids Club Activities
      Activity(
        id: '',
        name: 'Kids Martial Arts',
        description: 'Fun martial arts training for kids focusing on discipline and confidence',
        category: 'Kids',
        club: 'Kids Club',
        date: DateTime.now().add(const Duration(days: 4)),
        time: '15:30',
        timeCategory: Activity.getTimeCategory('15:30'),
        location: 'Community Center',
        price: 20.0,
        pointsReward: 65,
        capacity: 15,
        spotsLeft: 9,
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop',
        requirements: ['Comfortable clothes'],
      ),
      Activity(
        id: '',
        name: 'Junior Basketball',
        description: 'Basketball skills and teamwork for children aged 8-14',
        category: 'Kids',
        club: 'Kids Club',
        date: DateTime.now().add(const Duration(days: 6)),
        time: '16:30',
        timeCategory: Activity.getTimeCategory('16:30'),
        location: 'Sports Complex',
        price: 15.0,
        pointsReward: 50,
        capacity: 20,
        spotsLeft: 12,
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=300&h=200&fit=crop',
        requirements: ['Athletic shoes', 'Water bottle'],
      ),

      // Dance Club Activities
      Activity(
        id: '',
        name: 'Salsa Dance Lessons',
        description: 'Learn the passionate rhythms of salsa with professional instructors',
        category: 'Workshops',
        club: 'Dance Club',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '20:00',
        timeCategory: Activity.getTimeCategory('20:00'),
        location: 'Dance Studio',
        price: 25.0,
        pointsReward: 70,
        capacity: 16,
        spotsLeft: 6,
        imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=300&h=200&fit=crop',
        requirements: ['Dance shoes', 'Comfortable clothes'],
      ),
      Activity(
        id: '',
        name: 'Hip Hop Dance',
        description: 'Urban dance styles and choreography for all skill levels',
        category: 'Fitness',
        club: 'Dance Club',
        date: DateTime.now().add(const Duration(days: 4)),
        time: '17:00',
        timeCategory: Activity.getTimeCategory('17:00'),
        location: 'Dance Studio',
        price: 20.0,
        pointsReward: 65,
        capacity: 12,
        spotsLeft: 5,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Sneakers', 'Loose clothing'],
      ),

      // Running Club Activities
      Activity(
        id: '',
        name: 'Morning Trail Run',
        description: 'Guided trail running through scenic park routes for all fitness levels',
        category: 'Fitness',
        club: 'Running Club',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '06:00',
        timeCategory: Activity.getTimeCategory('06:00'),
        location: 'Central Park',
        price: 12.0,
        pointsReward: 45,
        capacity: 25,
        spotsLeft: 15,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Running shoes', 'Water bottle'],
      ),
      Activity(
        id: '',
        name: 'Speed Training',
        description: 'Interval training and speed work to improve your running performance',
        category: 'Fitness',
        club: 'Running Club',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '18:45',
        timeCategory: Activity.getTimeCategory('18:45'),
        location: 'Sports Complex',
        price: 15.0,
        pointsReward: 55,
        capacity: 10,
        spotsLeft: 4,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
        requirements: ['Running spikes', 'Stopwatch'],
      ),
    ];

    for (Activity activity in sampleActivities) {
      // Calculate bookedCount if it's not explicitly set
      final activityWithBookedCount = Activity(
        id: activity.id,
        name: activity.name,
        description: activity.description,
        category: activity.category,
        club: activity.club,
        date: activity.date,
        time: activity.time,
        timeCategory: activity.timeCategory,
        location: activity.location,
        price: activity.price,
        guestPrice: activity.guestPrice,
        memberPrice: activity.memberPrice,
        pointsReward: activity.pointsReward,
        capacity: activity.capacity,
        bookedCount: activity.capacity - activity.spotsLeft, // Calculate from capacity and spotsLeft
        spotsLeft: activity.spotsLeft,
        imageUrl: activity.imageUrl,
        requirements: activity.requirements,
      );
      await addActivity(activityWithBookedCount);
    }
  }

  /// Get unique clubs for dropdown
  static Future<List<String>> getAvailableClubs() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      Set<String> clubs = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['club'] != null) {
          clubs.add(data['club']);
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
        if (data['club'] != null) {
          clubs.add(data['club']);
        }
      }
      
      List<String> clubList = clubs.toList();
      clubList.sort();
      return clubList;
    });
  }

  /// Get unique locations for dropdown
  static Future<List<String>> getAvailableLocations() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      Set<String> locations = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null) {
          locations.add(data['location']);
        }
      }
      
      List<String> locationList = locations.toList();
      locationList.sort();
      return locationList;
    } catch (e) {
      return [];
    }
  }

  /// Get unique locations as a real-time stream
  static Stream<List<String>> getAvailableLocationsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      Set<String> locations = {};
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null) {
          locations.add(data['location']);
        }
      }
      
      List<String> locationList = locations.toList();
      locationList.sort();
      return locationList;
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