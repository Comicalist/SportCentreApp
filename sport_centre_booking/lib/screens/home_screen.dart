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

  // Advanced filter variables
  bool isFilterExpanded = false;
  String? selectedClub;
  DateTime? selectedDate;
  String? selectedTimeCategory;
  String? selectedLocation;
  String searchQuery = '';
  bool onlyAvailable = false;

  final TextEditingController searchController = TextEditingController();
  List<String> availableClubs = [];
  List<String> availableLocations = [];
  final List<String> timeCategories = ['Morning', 'Afternoon', 'Evening'];

  // Stream subscriptions for real-time dropdown updates
  late Stream<List<String>> clubsStream;
  late Stream<List<String>> locationsStream;
  late Stream<List<String>> categoriesStream;

  @override
  void initState() {
    super.initState();
    // Initialize real-time streams for dropdown options
    clubsStream = ActivityService.getAvailableClubsStream();
    locationsStream = ActivityService.getAvailableLocationsStream();
    categoriesStream = ActivityService.getAvailableCategoriesStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      selectedClub = null;
      selectedDate = null;
      selectedTimeCategory = null;
      selectedLocation = null;
      searchQuery = '';
      onlyAvailable = false;
      searchController.clear();
    });
  }

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
                    child: StreamBuilder<List<String>>(
                      stream: categoriesStream,
                      builder: (context, snapshot) {
                        List<String> categories = ['All'];
                        if (snapshot.hasData) {
                          categories.addAll(snapshot.data!);
                        }
                        
                        return ListView.builder(
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
                        );
                      },
                    ),
                  ),

                  // Advanced Filters Toggle
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search activities...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.teal),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFilterExpanded
                                ? Icons.filter_list_off
                                : Icons.filter_list,
                            color: isFilterExpanded ? Colors.teal : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              isFilterExpanded = !isFilterExpanded;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Expandable Advanced Filters
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isFilterExpanded ? null : 0,
                    child: isFilterExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: 16),

                              // Row 1: Club and Date
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStreamDropdown(
                                      label: 'Club',
                                      value: selectedClub,
                                      stream: clubsStream,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedClub = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDatePicker()),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Row 2: Time and Location
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      label: 'Time',
                                      value: selectedTimeCategory,
                                      items: timeCategories,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTimeCategory = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStreamDropdown(
                                      label: 'Location',
                                      value: selectedLocation,
                                      stream: locationsStream,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedLocation = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Row 3: Available checkbox and Clear button
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: onlyAvailable,
                                          onChanged: (value) {
                                            setState(() {
                                              onlyAvailable = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.teal,
                                        ),
                                        const Text('Only show available'),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Clear filters'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Activities List with Firebase Stream
            Expanded(
              child: StreamBuilder<List<Activity>>(
                stream: ActivityService.getFilteredActivities(
                  category: selectedCategory,
                  club: selectedClub,
                  date: selectedDate,
                  timeCategory: selectedTimeCategory,
                  location: selectedLocation,
                  searchQuery: searchQuery.isEmpty ? null : searchQuery,
                  onlyAvailable: onlyAvailable,
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
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio:
                              0.68, 
                        ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: TextStyle(color: Colors.grey[600])),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All ${label}s',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ...items.map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStreamDropdown({
    required String label,
    required String? value,
    required Stream<List<String>> stream,
    required Function(String?) onChanged,
  }) {
    return StreamBuilder<List<String>>(
      stream: stream,
      builder: (context, snapshot) {
        List<String> items = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              hint: Text(label, style: TextStyle(color: Colors.grey[600])),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'All ${label}s',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ...items.map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: Colors.teal),
                ),
                child: child!,
              );
            },
          );
          if (picked != null && picked != selectedDate) {
            setState(() {
              selectedDate = picked;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: selectedDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              if (selectedDate != null)
                InkWell(
                  onTap: () {
                    setState(() {
                      selectedDate = null;
                    });
                  },
                  child: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                ),
            ],
          ),
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
          Expanded(
            flex: 1,
            child: Container(
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
                  ),
                  // Category Icon
                  Center(
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
          ),

          // Activity Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

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
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Club and Location
                  Row(
                    children: [
                      Icon(Icons.groups, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        activity.club,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${activity.pointsReward} points',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Centered Book Now Button
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
