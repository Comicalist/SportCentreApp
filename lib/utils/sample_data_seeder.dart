import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity.dart';
import '../models/booking.dart';
import '../models/app_user.dart';
import '../models/club.dart';
import '../models/facility.dart';
import '../models/voucher.dart';
import 'dart:math';

class ComprehensiveSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Random _random = Random();

  // Store credentials for display after seeding
  static final List<Map<String, String>> _createdCredentials = [];

  /// Main seeder method - creates a complete Swiss sport centre ecosystem
  static Future<Map<String, dynamic>> seedCompleteDatabase({bool clearExisting = false}) async {
    try {
      _createdCredentials.clear();
      
      // Phase 1: Foundation Data
      final users = await _setupExistingUsers();
      
      if (users.isEmpty) {
        throw Exception('No users found with the expected email addresses');
      }
      
      final clubs = await _seedSwissClubs(users);
      
      final facilities = await _seedSwissFacilities(clubs);
      
      // Phase 2: Operational Data  
      final activities = await _seedSwissActivities(clubs, facilities, users); // Pass users here
      
      final vouchers = await _seedVouchers(clubs, users);
      
      // Phase 3: Behavioral Data
      await _seedRealisticBookings(users, activities, vouchers);
      
      await _seedNotifications(users);
      
      return {
        'success': true,
        'credentials': List.from(_createdCredentials),
        'summary': {
          'users': users.length,
          'clubs': clubs.length,
          'facilities': facilities.length,
          'activities': activities.length,
          'vouchers': vouchers.length,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'credentials': List.from(_createdCredentials),
      };
    }
  }

  /// Setup existing users with Swiss sport profiles (admin-only operation)
  static Future<List<AppUser>> _setupExistingUsers() async {
    final List<AppUser> users = [];
    
    // Pre-defined user data that matches the created Firebase Auth accounts
    final List<Map<String, dynamic>> profilesData = [
      {
        'email': 'admin@sportcentre.ch',
        'displayName': 'Sport Centre Admin',
        'role': 'admin',
        'totalPoints': 0,
        'availablePoints': 0,
        'lifetimePointsEarned': 0,
        'isMember': true,
        'membershipType': 'premium',
        'isClubOwner': false,
      },
      {
        'email': 'sarah.weber@fitnessplus.ch',
        'displayName': 'Sarah Weber',
        'role': 'club_owner',
        'totalPoints': 450,
        'availablePoints': 320,
        'lifetimePointsEarned': 1250,
        'isMember': true,
        'membershipType': 'premium',
        'isClubOwner': true,
      },
      {
        'email': 'marco.rossi@aquatica.ch',
        'displayName': 'Marco Rossi',
        'role': 'club_owner',
        'totalPoints': 380,
        'availablePoints': 280,
        'lifetimePointsEarned': 980,
        'isMember': true,
        'membershipType': 'premium',
        'isClubOwner': true,
      },
      {
        'email': 'anna.schneider@zenflow.ch',
        'displayName': 'Anna Schneider',
        'role': 'club_owner',
        'totalPoints': 520,
        'availablePoints': 410,
        'lifetimePointsEarned': 1580,
        'isMember': true,
        'membershipType': 'premium',
        'isClubOwner': true,
      },
      {
        'email': 'lucas.zimmermann@bluemail.ch',
        'displayName': 'Lucas Zimmermann',
        'role': 'member',
        'totalPoints': 180,
        'availablePoints': 120,
        'lifetimePointsEarned': 540,
        'isMember': true,
        'membershipType': 'standard',
        'isClubOwner': false,
      },
      {
        'email': 'elena.fischer@sunrise.ch',
        'displayName': 'Elena Fischer',
        'role': 'member',
        'totalPoints': 290,
        'availablePoints': 210,
        'lifetimePointsEarned': 760,
        'isMember': true,
        'membershipType': 'premium',
        'isClubOwner': false,
      },
      {
        'email': 'thomas.meyer@gmx.ch',
        'displayName': 'Thomas Meyer',
        'role': 'member',
        'totalPoints': 85,
        'availablePoints': 65,
        'lifetimePointsEarned': 340,
        'isMember': true,
        'membershipType': 'basic',
        'isClubOwner': false,
      },
      {
        'email': 'julia.keller@hotmail.ch',
        'displayName': 'Julia Keller',
        'role': 'member',
        'totalPoints': 340,
        'availablePoints': 270,
        'lifetimePointsEarned': 890,
        'isMember': true,
        'membershipType': 'standard',
        'isClubOwner': false,
      },
      {
        'email': 'david.brunner@outlook.ch',
        'displayName': 'David Brunner',
        'role': 'member',
        'totalPoints': 150,
        'availablePoints': 100,
        'lifetimePointsEarned': 420,
        'isMember': true,
        'membershipType': 'basic',
        'isClubOwner': false,
      },
      {
        'email': 'nina.huber@protonmail.ch',
        'displayName': 'Nina Huber',
        'role': 'member',
        'totalPoints': 220,
        'availablePoints': 180,
        'lifetimePointsEarned': 650,
        'isMember': true,
        'membershipType': 'standard',
        'isClubOwner': false,
      },
      {
        'email': 'stefan.bauer@icloud.ch',
        'displayName': 'Stefan Bauer',
        'role': 'member',
        'totalPoints': 95,
        'availablePoints': 75,
        'lifetimePointsEarned': 280,
        'isMember': true,
        'membershipType': 'basic',
        'isClubOwner': false,
      },
    ];

    for (final profileData in profilesData) {
      try {
        
        // Try to find existing user in Firestore first
        String? uid;
        final firestoreQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: profileData['email'])
            .get();
            
        if (firestoreQuery.docs.isNotEmpty) {
          uid = firestoreQuery.docs.first.id;
          
          // Only update if this is the admin user (who has permissions)
          if (profileData['email'] == 'admin@sportcentre.ch') {
            final membershipExpiry = profileData['isMember'] == true 
                ? DateTime.now().add(const Duration(days: 365))
                : null;

            final user = AppUser(
              uid: uid,
              email: profileData['email'],
              displayName: profileData['displayName'],
              createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
              lastLoginAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
              role: profileData['role'],
              isActive: true,
              totalPoints: profileData['totalPoints'],
              availablePoints: profileData['availablePoints'],
              lifetimePointsEarned: profileData['lifetimePointsEarned'],
              isMember: profileData['isMember'],
              membershipType: profileData['membershipType'],
              membershipExpiry: membershipExpiry,
              isClubOwner: profileData['isClubOwner'],
            );

            await _firestore.collection('users').doc(uid).set(user.toJson(), SetOptions(merge: true));
            users.add(user);
          } else {
            // For non-admin users, create AppUser object with existing data but don't update Firestore
            final existingDoc = firestoreQuery.docs.first;
            final existingData = existingDoc.data();
            
            final user = AppUser(
              uid: uid,
              email: profileData['email'],
              displayName: profileData['displayName'],
              createdAt: existingData['createdAt']?.toDate() ?? DateTime.now(),
              lastLoginAt: existingData['lastLoginAt']?.toDate() ?? DateTime.now(),
              role: profileData['role'],
              isActive: existingData['isActive'] ?? true,
              totalPoints: profileData['totalPoints'],
              availablePoints: profileData['availablePoints'],
              lifetimePointsEarned: profileData['lifetimePointsEarned'],
              isMember: profileData['isMember'],
              membershipType: profileData['membershipType'],
              membershipExpiry: profileData['isMember'] == true 
                  ? DateTime.now().add(const Duration(days: 365))
                  : null,
              isClubOwner: profileData['isClubOwner'],
            );
            
            users.add(user);
          }
        } else {
          // Try to find in Firebase Auth (fallback)
          try {
            final authUsers = await _auth.fetchSignInMethodsForEmail(profileData['email']);
            if (authUsers.isNotEmpty) {
              // User exists in Auth but not in Firestore - skip for now since we can't update
              continue;
            } else {
              continue;
            }
          } catch (e) {
            continue;
          }
        }
        
        // Store info for display (without passwords since we don't know them)
        _createdCredentials.add({
          'email': profileData['email'],
          'password': 'Your chosen password',
          'name': profileData['displayName'],
          'role': profileData['role'],
          'type': profileData['role'] == 'admin' ? 'Super Admin' :
                  profileData['isClubOwner'] ? 'Club Owner' :
                  'Member (${profileData['membershipType']})',
        });
        
        
      } catch (e) {
        // Continue with other users even if one fails
      }
    }

    return users;
  }

  /// Create Swiss sport clubs with realistic locations and blocking schedules
  static Future<List<Club>> _seedSwissClubs(List<AppUser> users) async {
    try {
      final clubOwners = users.where((u) => u.isClubOwner).toList();
      
      if (clubOwners.isEmpty) {
        throw Exception('No club owners found in users list');
      }
      
      final List<Map<String, dynamic>> clubData = [
        {
          'name': 'FitnessPlus Zürich',
          'location': 'Bahnhofstrasse 45, 8001 Zürich',
          'description': 'Premium fitness club in the heart of Zurich with state-of-the-art equipment',
          'ownerId': clubOwners[0].uid,
          'facilities': ['Modern Gym', 'Group Fitness Studio', 'Sauna', 'Locker Rooms'],
          'contactEmail': 'info@fitnessplus.ch',
          'phone': '+41 44 123 45 67',
          'blockedTimes': [],
        },
        {
          'name': 'Aquatica Basel',
          'location': 'Rheinweg 12, 4052 Basel',
          'description': 'Modern aquatic center with pools, wellness, and water sports',
          'ownerId': clubOwners.length > 1 ? clubOwners[1].uid : clubOwners[0].uid,
          'facilities': ['Olympic Pool', 'Kids Pool', 'Spa Area', 'Changing Rooms'],
          'contactEmail': 'info@aquatica.ch',
          'phone': '+41 61 234 56 78',
          'blockedTimes': [],
        },
        {
          'name': 'ZenFlow Wellness Bern',
          'location': 'Kramgasse 88, 3011 Bern',
          'description': 'Holistic wellness center focusing on yoga, meditation, and mindfulness',
          'ownerId': clubOwners.length > 2 ? clubOwners[2].uid : clubOwners[0].uid,
          'facilities': ['Yoga Studio', 'Meditation Room', 'Therapy Rooms'],
          'contactEmail': 'info@zenflow.ch',
          'phone': '+41 31 345 67 89',
          'blockedTimes': [],
        },
      ];

      List<Club> clubs = [];
      for (int i = 0; i < clubData.length; i++) {
        final data = clubData[i];
        final club = Club(
          id: '',
          name: data['name'],
          ownerId: data['ownerId'],
          location: data['location'],
          isActive: true,
          isApproved: true,
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(180))),
          blockedTimes: List<Map<String, dynamic>>.from(data['blockedTimes']),
        );

        final docRef = await _firestore.collection('clubs').add(club.toMap());
        final savedClub = club.copyWith(id: docRef.id);
        clubs.add(savedClub);
      }

      return clubs;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Swiss facilities with maintenance blocking schedules
  static Future<List<Facility>> _seedSwissFacilities(List<Club> clubs) async {
    try {
      final List<Map<String, dynamic>> facilityTemplates = [
        // FitnessPlus Zürich facilities
        {
          'clubId': clubs[0].id,
          'title': 'Hauptfitness Studio',
          'description': 'Modern weight training area with premium equipment from Technogym',
          'maxCapacity': 35,
          'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        {
          'clubId': clubs[0].id,
          'title': 'Group Fitness Studio',
          'description': 'Spacious studio for group classes with sound system and mirrors',
          'maxCapacity': 25,
          'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        
        // Aquatica Basel facilities
        {
          'clubId': clubs.length > 1 ? clubs[1].id : clubs[0].id,
          'title': 'Olympisches Schwimmbecken',
          'description': '50-meter Olympic standard pool for serious swimmers and competitions',
          'maxCapacity': 40,
          'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        {
          'clubId': clubs.length > 1 ? clubs[1].id : clubs[0].id,
          'title': 'Kinderbecken',
          'description': 'Safe shallow pool area designed specifically for children and families',
          'maxCapacity': 15,
          'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        {
          'clubId': clubs.length > 1 ? clubs[1].id : clubs[0].id,
          'title': 'Wellness Bereich',
          'description': 'Relaxation area with hot tub, sauna, and steam room',
          'maxCapacity': 20,
          'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        
        // ZenFlow Bern facilities
        {
          'clubId': clubs.length > 2 ? clubs[2].id : clubs[0].id,
          'title': 'Hauptyoga Studio',
          'description': 'Serene yoga studio with natural lighting and peaceful atmosphere',
          'maxCapacity': 20,
          'imageUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
        {
          'clubId': clubs.length > 2 ? clubs[2].id : clubs[0].id,
          'title': 'Meditationsraum',
          'description': 'Quiet meditation space for mindfulness and spiritual practices',
          'maxCapacity': 12,
          'imageUrl': 'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?w=400&h=300&fit=crop',
          'blockedTimes': [],
        },
      ];

      List<Facility> facilities = [];
      for (var template in facilityTemplates) {
        final facility = Facility(
          id: '',
          clubId: template['clubId'],
          title: template['title'],
          description: template['description'],
          maxCapacity: template['maxCapacity'],
          imageUrl: template['imageUrl'],
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(120))),
          updatedAt: DateTime.now(),
          blockedTimes: List<Map<String, dynamic>>.from(template['blockedTimes']),
        );

        final docRef = await _firestore.collection('facilities').add(facility.toJson());
        final savedFacility = facility.copyWith(id: docRef.id);
        facilities.add(savedFacility);
      }

      return facilities;
    } catch (e) {
      rethrow;
    }
  }

  /// Create realistic Swiss activities with proper pricing and scheduling
  static Future<List<Activity>> _seedSwissActivities(List<Club> clubs, List<Facility> facilities, List<AppUser> users) async { // Added users parameter
    try {
      final List<Map<String, dynamic>> activityTemplates = [
        // FitnessPlus Zürich activities
        {
          'name': 'CrossFit Bootcamp',
          'description': 'High-intensity functional fitness training for all levels',
          'category': 'Fitness',
          'guestPrice': 45.0,
          'memberPrice': 35.0,
          'duration': 60,
          'pointsReward': 45,
          'requirements': ['Athletic shoes', 'Towel', 'Water bottle'],
          'clubIndex': 0,
          'facilityFilter': 'Studio',
        },
        {
          'name': 'Krafttraining für Einsteiger',
          'description': 'Learn proper weight training techniques with professional guidance',
          'category': 'Fitness',
          'guestPrice': 35.0,
          'memberPrice': 25.0,
          'duration': 75,
          'pointsReward': 35,
          'requirements': ['Gym gloves (optional)', 'Towel'],
          'clubIndex': 0,
          'facilityFilter': 'Studio',
        },
        {
          'name': 'HIIT Power Session',
          'description': 'Maximum calorie burn with high-intensity interval training',
          'category': 'Fitness',
          'guestPrice': 40.0,
          'memberPrice': 30.0,
          'duration': 45,
          'pointsReward': 40,
          'requirements': ['Athletic shoes', 'Towel'],
          'clubIndex': 0,
          'facilityFilter': 'Studio',
        },
        
        // Aquatica Basel activities
        {
          'name': 'Schwimmkurs für Erwachsene',
          'description': 'Learn swimming techniques or improve your stroke in small groups',
          'category': 'Fitness',
          'guestPrice': 65.0,
          'memberPrice': 50.0,
          'duration': 60,
          'pointsReward': 65,
          'requirements': ['Swimwear', 'Goggles', 'Towel'],
          'clubIndex': clubs.length > 1 ? 1 : 0,
          'facilityFilter': 'becken',
        },
        {
          'name': 'Aqua Aerobic',
          'description': 'Low-impact water aerobics for fitness and rehabilitation',
          'category': 'Wellness',
          'guestPrice': 30.0,
          'memberPrice': 22.0,
          'duration': 45,
          'pointsReward': 30,
          'requirements': ['Swimwear', 'Water shoes (optional)'],
          'clubIndex': clubs.length > 1 ? 1 : 0,
          'facilityFilter': 'becken',
        },
        
        // ZenFlow Bern activities
        {
          'name': 'Hatha Yoga für Anfänger',
          'description': 'Gentle introduction to yoga with focus on breathing and basic poses',
          'category': 'Wellness',
          'guestPrice': 28.0,
          'memberPrice': 20.0,
          'duration': 60,
          'pointsReward': 28,
          'requirements': ['Yoga mat', 'Comfortable clothes'],
          'clubIndex': clubs.length > 2 ? 2 : 0,
          'facilityFilter': 'Studio',
        },
        {
          'name': 'Meditation & Achtsamkeit',
          'description': 'Guided meditation session to reduce stress and increase mindfulness',
          'category': 'Wellness',
          'guestPrice': 20.0,
          'memberPrice': 15.0,
          'duration': 45,
          'pointsReward': 20,
          'requirements': ['Comfortable clothes'],
          'clubIndex': clubs.length > 2 ? 2 : 0,
          'facilityFilter': 'Meditation',
        },
      ];

      List<Activity> activities = [];
      
      // Create multiple sessions for each activity template over next 2 months
      for (var template in activityTemplates) {
        final clubIndex = template['clubIndex'] as int;
        if (clubIndex >= clubs.length) continue;
        
        final club = clubs[clubIndex];
        final clubFacilities = facilities.where((f) => f.clubId == club.id).toList();
        
        // Find appropriate facility
        final suitableFacilities = clubFacilities.where((f) => 
          f.title.toLowerCase().contains(template['facilityFilter'].toString().toLowerCase())
        ).toList();
        
        if (suitableFacilities.isEmpty) {
          if (clubFacilities.isNotEmpty) {
            suitableFacilities.add(clubFacilities.first);
          } else {
            continue;
          }
        }
        
        final facility = suitableFacilities.first;
        final sessionCount = 8 + _random.nextInt(12); // 8-20 sessions per activity
        
        for (int session = 0; session < sessionCount; session++) {
          final daysFromNow = _random.nextInt(60) + 1; // Next 60 days
          final activityDate = DateTime.now().add(Duration(days: daysFromNow));
          
          // Skip weekends for some activities
          if (template['category'] == 'Workshops' && (activityDate.weekday == 6 || activityDate.weekday == 7)) {
            continue;
          }
          
          final hour = _getRandomHourForCategory(template['category'] as String);
          final minute = [0, 15, 30, 45][_random.nextInt(4)];
          final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          
          // Vary capacity slightly
          final capacity = (facility.maxCapacity * 0.7).round() + _random.nextInt(5);
          final bookedCount = _random.nextInt((capacity * 0.8).round());
          
          // Add some past activities for demo
          final isHistorical = session < 2 && _random.nextBool();
          final finalDate = isHistorical 
              ? DateTime.now().subtract(Duration(days: _random.nextInt(30)))
              : activityDate;
          
          // Find a user to be the creator (club owner)
          final clubOwner = users.firstWhere((u) => u.uid == club.ownerId);
          
          final activity = Activity(
            id: '',
            clubId: club.id,
            clubName: club.name,
            facilityId: facility.id,
            facilityName: facility.title,
            name: template['name'] as String,
            description: template['description'] as String,
            category: template['category'] as String,
            date: finalDate,
            time: timeString,
            duration: template['duration'] as int,
            timeCategory: _getTimeCategory(timeString), // Required parameter
            capacity: capacity // Required parameter  
            , bookedCount: bookedCount // Use bookedCount instead of currentParticipants
            , guestPrice: template['guestPrice'] as double,
            memberPrice: template['memberPrice'] as double,
            pointsReward: template['pointsReward'] as int,
            requirements: List<String>.from(template['requirements']),
            imageUrl: _getImageForCategory(template['category'] as String),
            createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
            updatedAt: DateTime.now(),
            createdBy: clubOwner.uid, // Required parameter
          );

          final docRef = await _firestore.collection('activities').add(activity.toJson());
          final savedActivity = activity.copyWith(id: docRef.id);
          activities.add(savedActivity);
        }
      }

      return activities;
    } catch (e) {
      rethrow;
    }
  }

  /// Create vouchers for different clubs
  static Future<List<Voucher>> _seedVouchers(List<Club> clubs, List<AppUser> users) async {
    try {
      final List<Map<String, dynamic>> voucherTemplates = [
        {
          'title': '10 CHF Fitness Gutschein',
          'description': 'Gutschein für alle Fitness-Aktivitäten bei FitnessPlus',
          'type': VoucherType.fitness,
          'amount': 10.0,
          'pointsCost': 1000,
          'clubIndex': 0,
        },
        {
          'title': '15 CHF Wellness Voucher',
          'description': 'Rabatt für Wellness und Entspannungsangebote',
          'type': VoucherType.fitness,
          'amount': 15.0,
          'pointsCost': 1500,
          'clubIndex': clubs.length > 1 ? 1 : 0,
        },
        {
          'title': '20 CHF Yoga Gutschein',
          'description': 'Spezieller Rabatt für alle Yoga-Klassen',
          'type': VoucherType.fitness,
          'amount': 20.0,
          'pointsCost': 2000,
          'clubIndex': clubs.length > 2 ? 2 : 0,
        },
        {
          'title': '5 CHF Getränke Voucher',
          'description': 'Gutschein für Getränke und Snacks',
          'type': VoucherType.stuff,
          'amount': 5.0,
          'pointsCost': 500,
          'clubIndex': 0,
        },
      ];

      List<Voucher> vouchers = [];
      
      for (var template in voucherTemplates) {
        final clubIndex = template['clubIndex'] as int;
        if (clubIndex >= clubs.length) continue;
        
        final club = clubs[clubIndex];
        final clubOwner = users.firstWhere((u) => u.uid == club.ownerId);
        
        // Create some available vouchers
        for (int i = 0; i < 3; i++) {
          final voucher = Voucher(
            id: '',
            title: template['title'] as String,
            description: template['description'] as String,
            type: template['type'] as VoucherType,
            amount: template['amount'] as double,
            pointsCost: template['pointsCost'] as int,
            isActive: true,
            clubId: club.id,
            clubName: club.name, // Required parameter
            createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
            updatedAt: DateTime.now(), // Required parameter
            createdBy: clubOwner.uid,
          );

          final docRef = await _firestore.collection('vouchers').add(voucher.toJson());
          vouchers.add(voucher.copyWith(id: docRef.id));
        }
        
        // Create some purchased vouchers
        final eligibleUsers = users.where((u) => !u.isClubOwner && u.role != 'admin').toList();
        for (int i = 0; i < 2; i++) {
          if (eligibleUsers.isEmpty) break;
          
          final purchaser = eligibleUsers[_random.nextInt(eligibleUsers.length)];
          final purchaseDate = DateTime.now().subtract(Duration(days: _random.nextInt(60)));
          
          final voucher = Voucher(
            id: '',
            title: template['title'] as String,
            description: template['description'] as String,
            type: template['type'] as VoucherType,
            amount: template['amount'] as double,
            pointsCost: template['pointsCost'] as int,
            isActive: true,
            clubId: club.id,
            clubName: club.name, // Required parameter
            createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
            updatedAt: DateTime.now(), // Required parameter
            createdBy: clubOwner.uid,
            purchasedBy: purchaser.uid,
            purchasedAt: purchaseDate,
            usedAt: _random.nextBool() ? purchaseDate.add(Duration(days: _random.nextInt(30))) : null,
            usedForBooking: _random.nextBool() ? 'booking_${_random.nextInt(1000)}' : null,
          );

          final docRef = await _firestore.collection('vouchers').add(voucher.toJson());
          vouchers.add(voucher.copyWith(id: docRef.id));
        }
      }

      return vouchers;
    } catch (e) {
      return [];
    }
  }

  /// Create realistic booking patterns
  static Future<void> _seedRealisticBookings(List<AppUser> users, List<Activity> activities, List<Voucher> vouchers) async {
    try {
      final regularUsers = users.where((u) => !u.isClubOwner && u.role != 'admin').toList();
      final pastActivities = activities.where((a) => a.date.isBefore(DateTime.now())).toList();
      final futureActivities = activities.where((a) => a.date.isAfter(DateTime.now())).toList();
      
      // Create past bookings (completed)
      for (var activity in pastActivities.take(25)) {
        if (regularUsers.isNotEmpty) {
          final user = regularUsers[_random.nextInt(regularUsers.length)];
          await _createBooking(user, activity, BookingStatus.completed, vouchers);
        }
      }
      
      // Create upcoming bookings (confirmed)
      for (var activity in futureActivities.take(35)) {
        if (activity.spotsLeft > 0 && regularUsers.isNotEmpty) {
          final user = regularUsers[_random.nextInt(regularUsers.length)];
          await _createBooking(user, activity, BookingStatus.confirmed, vouchers);
        }
      }
      
      // Create some cancelled bookings
      for (var activity in futureActivities.take(8)) {
        if (regularUsers.isNotEmpty) {
          final user = regularUsers[_random.nextInt(regularUsers.length)];
          await _createBooking(user, activity, BookingStatus.cancelled, vouchers);
        }
      }
    } catch (e) {
    }
  }

  static Future<void> _createBooking(AppUser user, Activity activity, BookingStatus status, List<Voucher> vouchers) async {
    try {
      final price = user.isMember ? activity.memberPrice : activity.guestPrice;
      final pointsEarned = status == BookingStatus.completed ? activity.pointsReward : 0;
      
      // Randomly use vouchers
      Voucher? usedVoucher;
      double voucherDiscount = 0.0;
      
      if (_random.nextBool() && vouchers.isNotEmpty) {
        final userVouchers = vouchers.where((v) => 
          v.purchasedBy == user.uid && v.type == VoucherType.fitness && v.usedAt == null
        ).toList();
        
        if (userVouchers.isNotEmpty) {
          usedVoucher = userVouchers.first;
          voucherDiscount = usedVoucher.amount;
        }
      }
      
      final finalPrice = (price - voucherDiscount).clamp(0.0, price);
      
      final booking = Booking(
        id: '',
        userId: user.uid,
        activityId: activity.id,
        bookingDate: status == BookingStatus.completed 
            ? activity.date.subtract(Duration(days: _random.nextInt(30)))
            : DateTime.now().subtract(Duration(days: _random.nextInt(15))),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        status: status,
        amountPaid: finalPrice,
        pointsEarned: pointsEarned,
        participantCount: 1,
        isMemberBooking: user.isMember,
        confirmationNumber: 'SC${_random.nextInt(9999).toString().padLeft(4, '0')}',
        voucherId: usedVoucher?.id,
        voucherDiscount: voucherDiscount > 0 ? voucherDiscount : null,
        activityTitle: activity.name,
        activityDate: activity.date,
        activityTime: activity.time,
        totalPrice: price,
        clubId: activity.clubId,
        clubName: activity.clubName,
        facilityId: activity.facilityId,
        facilityName: activity.facilityName,
        // Note: userName and userEmail are not in the Booking constructor
        // They should be handled by the booking service when needed
      );

      await _firestore.collection('bookings').add(booking.toJson());
      
      // Mark voucher as used if applicable
      if (usedVoucher != null) {
        await _firestore.collection('vouchers').doc(usedVoucher.id).update({
          'usedAt': Timestamp.fromDate(DateTime.now()),
          'usedForBooking': booking.id,
        });
      }
    } catch (e) {
    }
  }

  /// Create sample notifications
  static Future<void> _seedNotifications(List<AppUser> users) async {
    try {
      final regularUsers = users.where((u) => !u.isClubOwner && u.role != 'admin').toList();
      
      for (var user in regularUsers.take(5)) {
        // Booking reminder
        final notification = {
          'userId': user.uid,
          'type': 'bookingReminder',
          'title': 'Erinnerung: Yoga Klasse morgen',
          'body': 'Vergessen Sie nicht Ihre Yoga-Stunde morgen um 10:00 Uhr!',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: _random.nextInt(48)))),
          'isRead': _random.nextBool(),
          'bookingId': 'booking_${_random.nextInt(1000)}',
          'activityName': 'Hatha Yoga für Anfänger',
        };
        
        await _firestore.collection('notifications').add(notification);
      }
    } catch (e) {
    }
  }

  // Helper methods
  static int _getRandomHourForCategory(String category) {
    switch (category) {
      case 'Wellness':
        return [7, 8, 9, 17, 18, 19, 20][_random.nextInt(7)];
      case 'Fitness':
        return [6, 7, 8, 17, 18, 19, 20][_random.nextInt(7)];
      case 'Kids':
        return [14, 15, 16, 17][_random.nextInt(4)];
      case 'Workshops':
        return [9, 10, 14, 15, 19][_random.nextInt(5)];
      default:
        return _random.nextInt(14) + 7; // 7-20
    }
  }

  static String _getTimeCategory(String time) {
    final hour = int.parse(time.split(':')[0]);
    if (hour >= 6 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  static String _getImageForCategory(String category) {
    switch (category) {
      case 'Wellness':
        return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop';
      case 'Fitness':
        return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop';
      case 'Kids':
        return 'https://images.unsplash.com/photo-1566104827745-7237210ee915?w=400&h=300&fit=crop';
      case 'Workshops':
        return 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=400&h=300&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop';
    }
  }

}