import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/activity.dart';

/// Seed Script for Creating Sample Activities
///
/// This script creates sample activities based on existing clubs and facilities
/// Run this from a debug button or admin panel
class ActivitySeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample activities for all approved clubs with facilities
  static Future<void> seedActivities() async {
    try {
      // Get current user for createdBy field
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to seed data');
      }

      final clubsSnapshot = await _firestore
          .collection('clubs')
          .where('isApproved', isEqualTo: true)
          .get();

      if (clubsSnapshot.docs.isEmpty) {
        return;
      }

      var totalActivitiesCreated = 0;

      for (final clubDoc in clubsSnapshot.docs) {
        final clubData = clubDoc.data();
        final clubId = clubDoc.id;
        final clubName = clubData['name'] as String;
        final clubOwnerId = clubData['ownerId'] as String;

        // Get facilities for this club
        final facilitiesSnapshot = await _firestore
            .collection('facilities')
            .where('clubId', isEqualTo: clubId)
            .where('isActive', isEqualTo: true)
            .get();

        if (facilitiesSnapshot.docs.isEmpty) {
          continue;
        }

        // Create 2-3 activities per facility
        for (final facilityDoc in facilitiesSnapshot.docs) {
          final facilityData = facilityDoc.data();
          final facilityId = facilityDoc.id;
          final facilityName = facilityData['title'] as String;
          final facilityMaxCapacity = facilityData['maxCapacity'] as int;

          // Determine activities based on facility type
          final activities = _getActivitiesForFacility(
            facilityName,
            clubId,
            clubName,
            facilityId,
            facilityMaxCapacity,
            clubOwnerId,
          );

          for (final activity in activities) {
            try {
              final activityData = activity.toJson();
              activityData.remove('id'); // Firestore will generate ID

              await _firestore.collection('activities').add(activityData);
              totalActivitiesCreated++;
            } catch (e) {
              // Log error but continue with other activities
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate sample activities based on facility name
  static List<Activity> _getActivitiesForFacility(
    String facilityName,
    String clubId,
    String clubName,
    String facilityId,
    int maxCapacity,
    String ownerId,
  ) {
    final now = DateTime.now();
    final activities = <Activity>[];
    final facilityLower = facilityName.toLowerCase();

    // Capacity should be 60-80% of max
    final capacity = (maxCapacity * 0.7).round();

    if (facilityLower.contains('pool') || facilityLower.contains('swim')) {
      // Swimming activities
      activities.addAll([
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Aqua Aerobics',
          description:
              'Low-impact water exercise for all fitness levels. Great for joint health and cardiovascular fitness.',
          category: 'Wellness',
          date: now.add(const Duration(days: 2)),
          time: '10:00',
          duration: 45,
          timeCategory: 'Morning',
          capacity: capacity,
          guestPrice: 18.0,
          memberPrice: 15.0,
          pointsReward: 50,
          requirements: ['Swimsuit', 'Swim cap', 'Goggles'],
          imageUrl:
              'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Adult Swimming Lessons',
          description:
              'Beginner-friendly swimming lessons to build confidence and technique in the water.',
          category: 'Wellness',
          date: now.add(const Duration(days: 5)),
          time: '18:00',
          duration: 60,
          timeCategory: 'Evening',
          capacity: (capacity * 0.5).round(),
          guestPrice: 25.0,
          memberPrice: 20.0,
          pointsReward: 70,
          requirements: ['Swimsuit', 'Goggles', 'Towel'],
          imageUrl:
              'https://images.unsplash.com/photo-1519315901367-f34ff9154487?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
      ]);
    } else if (facilityLower.contains('gym') ||
        facilityLower.contains('weight')) {
      // Gym activities
      activities.addAll([
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'CrossFit Fundamentals',
          description:
              'Master basic CrossFit movements with focus on proper form and technique.',
          category: 'Fitness',
          date: now.add(const Duration(days: 1)),
          time: '06:30',
          duration: 60,
          timeCategory: 'Morning',
          capacity: capacity,
          guestPrice: 30.0,
          memberPrice: 25.0,
          pointsReward: 90,
          requirements: ['Athletic shoes', 'Water bottle', 'Towel'],
          imageUrl:
              'https://images.unsplash.com/photo-1517438322307-e67111335449?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Weight Training Basics',
          description:
              'Learn proper form and technique for common weight training exercises. Perfect for beginners.',
          category: 'Fitness',
          date: now.add(const Duration(days: 4)),
          time: '09:00',
          duration: 60,
          timeCategory: 'Morning',
          capacity: (capacity * 0.6).round(),
          guestPrice: 25.0,
          memberPrice: 20.0,
          pointsReward: 80,
          requirements: ['Workout gloves (optional)', 'Water bottle', 'Towel'],
          imageUrl:
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'HIIT Workout',
          description:
              'High intensity interval training for maximum calorie burn and cardiovascular fitness.',
          category: 'Fitness',
          date: now.add(const Duration(days: 3)),
          time: '18:00',
          duration: 45,
          timeCategory: 'Evening',
          capacity: capacity,
          guestPrice: 20.0,
          memberPrice: 16.0,
          pointsReward: 70,
          requirements: ['Athletic shoes', 'Water bottle', 'Towel'],
          imageUrl:
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
      ]);
    } else if (facilityLower.contains('studio') ||
        facilityLower.contains('yoga') ||
        facilityLower.contains('dance')) {
      // Studio activities
      activities.addAll([
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Morning Yoga Flow',
          description:
              'Start your day with energizing yoga poses and mindful breathing exercises.',
          category: 'Wellness',
          date: now.add(const Duration(days: 1)),
          time: '07:00',
          duration: 60,
          timeCategory: 'Morning',
          capacity: capacity,
          guestPrice: 18.0,
          memberPrice: 15.0,
          pointsReward: 50,
          requirements: ['Yoga mat', 'Water bottle'],
          imageUrl:
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Pilates Core Strength',
          description:
              'Core-strengthening exercises focusing on alignment, breathing, and body control.',
          category: 'Wellness',
          date: now.add(const Duration(days: 2)),
          time: '12:00',
          duration: 50,
          timeCategory: 'Afternoon',
          capacity: (capacity * 0.7).round(),
          guestPrice: 22.0,
          memberPrice: 18.0,
          pointsReward: 65,
          requirements: ['Mat', 'Grip socks', 'Water bottle'],
          imageUrl:
              'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Evening Restorative Yoga',
          description:
              'Gentle stretches and meditation to unwind and relax after a busy day.',
          category: 'Wellness',
          date: now.add(const Duration(days: 6)),
          time: '19:00',
          duration: 60,
          timeCategory: 'Evening',
          capacity: capacity,
          guestPrice: 18.0,
          memberPrice: 15.0,
          pointsReward: 55,
          requirements: ['Yoga mat', 'Blanket'],
          imageUrl:
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
      ]);
    } else if (facilityLower.contains('court')) {
      // Court activities
      activities.addAll([
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Tennis Beginner Class',
          description:
              'Learn the fundamentals of tennis including proper grip, stance, and basic strokes.',
          category: 'Fitness',
          date: now.add(const Duration(days: 3)),
          time: '10:00',
          duration: 90,
          timeCategory: 'Morning',
          capacity: (capacity * 0.5).round(),
          guestPrice: 28.0,
          memberPrice: 23.0,
          pointsReward: 75,
          requirements: ['Tennis racket', 'Tennis shoes', 'Water bottle'],
          imageUrl:
              'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
      ]);
    } else {
      // Generic fitness activity for unknown facility types
      activities.add(
        Activity(
          id: '',
          clubId: clubId,
          facilityId: facilityId,
          clubName: clubName,
          facilityName: facilityName,
          name: 'Fitness Class',
          description:
              'General fitness class suitable for all levels. Join us for a great workout!',
          category: 'Fitness',
          date: now.add(const Duration(days: 2)),
          time: '14:00',
          duration: 60,
          timeCategory: 'Afternoon',
          capacity: capacity,
          guestPrice: 15.0,
          memberPrice: 12.0,
          pointsReward: 40,
          requirements: ['Athletic shoes', 'Water bottle'],
          imageUrl:
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=300&h=200&fit=crop',
          createdAt: now,
          updatedAt: now,
          createdBy: ownerId,
        ),
      );
    }

    return activities;
  }

  /// Delete all existing activities (for clean re-seeding)
  static Future<void> clearAllActivities() async {
    try {
      final snapshot = await _firestore.collection('activities').get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Full reseed: clear and create new activities
  static Future<void> reseedActivities() async {
    await clearAllActivities();
    await seedActivities();
  }
}

/// Widget to trigger seeding from admin panel
class SeedActivitiesButton extends StatefulWidget {
  const SeedActivitiesButton({super.key});

  @override
  State<SeedActivitiesButton> createState() => _SeedActivitiesButtonState();
}

class _SeedActivitiesButtonState extends State<SeedActivitiesButton> {
  bool _isSeeding = false;

  Future<void> _handleSeed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Activities'),
        content: const Text(
          'This will create sample activities for all approved clubs with facilities. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      await ActivitySeeder.seedActivities();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activities seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding activities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSeeding ? null : _handleSeed,
      icon: _isSeeding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle),
      label: Text(_isSeeding ? 'Seeding...' : 'Seed Activities'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
