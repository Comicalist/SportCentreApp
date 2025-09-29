import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Wellness',
    'Fitness',
    'Kids',
    'Workshops',
  ];

  // Sample data - will be replaced with Firebase data later
  /*
  final List<Activity> sampleActivities = [
    Activity(
      id: '1',
      name: 'Morning Yoga Flow',
      description: 'Start your day with energizing yoga poses',
      category: 'Wellness',
      date: DateTime(2025, 1, 12),
      time: '07:00',
      location: 'Studio A',
      price: 15.0,
      pointsReward: 50,
      capacity: 15,
      spotsLeft: 5,
      imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
    ),
    Activity(
      id: '2',
      name: 'HIIT Training',
      description: 'High-intensity interval training session',
      category: 'Fitness',
      date: DateTime(2025, 1, 12),
      time: '18:00',
      location: 'Gym Floor',
      price: 20.0,
      pointsReward: 75,
      capacity: 12,
      spotsLeft: 3,
      imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
    ),
    Activity(
      id: '3',
      name: 'Kids Swimming Lessons',
      description: 'Swimming lessons for children aged 5-12',
      category: 'Kids',
      date: DateTime(2025, 1, 13),
      time: '16:00',
      location: 'Pool Area',
      price: 25.0,
      pointsReward: 60,
      capacity: 8,
      spotsLeft: 2,
      imageUrl: 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=300&h=200&fit=crop',
    ),
    Activity(
      id: '4',
      name: 'Nutrition Workshop',
      description: 'Learn about healthy eating and meal planning',
      category: 'Workshops',
      date: DateTime(2025, 1, 14),
      time: '14:00',
      location: 'Conference Room',
      price: 30.0,
      pointsReward: 100,
      capacity: 20,
      spotsLeft: 8,
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=300&h=200&fit=crop',
    ),
  ]; */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Club Activities',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back, Sarah Johnson!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter Tabs
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category;

                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : getCategoryColor(category),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: getCategoryColor(category),
                            side: BorderSide(
                              color: getCategoryColor(category),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Activities List with Firebase Stream
            Expanded(
              child: StreamBuilder<List<Activity>>(
                stream: ActivityService.getActivitiesByCategory(
                  selectedCategory,
                ),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading activities...'),
                        ],
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading activities'),
                          SizedBox(height: 8),
                          Text('${snapshot.error}'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            selectedCategory == 'All'
                                ? 'No activities available'
                                : 'No $selectedCategory activities',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await ActivityService.addSampleActivities();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sample activities added!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Add Sample Activities'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show activities
                  final activities = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ActivityCard(activity: activity);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Wellness':
        return Colors.teal;
      case 'Fitness':
        return Colors.orange;
      case 'Kids':
        return Colors.purple;
      case 'Workshops':
        return Colors.blue;
      default:
        return Colors.grey[600]!;
    }
  }
}

class ActivityCard extends StatelessWidget {
  final Activity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              color: Colors.grey[300],
            ),
            child: Stack(
              children: [
                // Placeholder for image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        getCategoryColor(activity.category).withOpacity(0.7),
                        getCategoryColor(activity.category).withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Icon(
                    getCategoryIcon(activity.category),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getCategoryColor(activity.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Activity Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Date and Time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(activity.date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      activity.time,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      activity.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price and Spots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${activity.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${activity.pointsReward} points',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getSpotsColor(activity.spotsLeft),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activity.spotsLeft} left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement booking functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking ${activity.name}...'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Book Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Wellness':
        return Colors.teal;
      case 'Fitness':
        return Colors.orange;
      case 'Kids':
        return Colors.purple;
      case 'Workshops':
        return Colors.blue;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Wellness':
        return Icons.self_improvement;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Kids':
        return Icons.child_care;
      case 'Workshops':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  Color getSpotsColor(int spotsLeft) {
    if (spotsLeft <= 1) return Colors.red;
    if (spotsLeft <= 3) return Colors.orange;
    return Colors.green;
  }
}
