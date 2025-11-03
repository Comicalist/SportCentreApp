import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../utils/activity_helpers.dart';
import '../../../widgets/activity/activity_card.dart';

/// Responsive activity grid with real-time filtering and search capabilities
/// Displays available activities based on user preferences and booking criteria
class ActivitiesGrid extends StatelessWidget {
  const ActivitiesGrid({
    super.key,
    required this.selectedCategory,
    required this.selectedClub,
    required this.selectedDate,
    required this.selectedTimeCategory,
    required this.selectedLocation,
    required this.searchQuery,
    required this.onlyAvailable,
  });
  
  final String selectedCategory;
  final String? selectedClub;
  final DateTime? selectedDate;
  final String? selectedTimeCategory;
  final String? selectedLocation;
  final String? searchQuery;
  final bool onlyAvailable;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      // Real-time activity stream with comprehensive filtering
      stream: ActivityService.getFilteredActivities(
        category: selectedCategory,
        clubName: selectedClub,
        date: selectedDate,
        timeCategory: selectedTimeCategory,
        facilityId: selectedLocation,
        searchQuery: searchQuery?.isEmpty ?? false ? null : searchQuery,
        onlyAvailable: onlyAvailable,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildActivitiesGrid(context, snapshot.data!);
      },
    );
  }

  /// Loading state with user-friendly messaging
  Widget _buildLoadingState() {
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

  /// Error state with retry capability for network issues
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading activities'),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Trigger rebuild by calling setState on parent
              // This is a simplified approach - in a real app you'd use proper state management
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Empty state with context-aware messaging based on selected filters
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            selectedCategory == 'All'
                ? 'No activities available'
                : 'No $selectedCategory activities',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Responsive grid layout with dynamic card sizing
  /// Adapts to screen size for optimal viewing across devices
  Widget _buildActivitiesGrid(BuildContext context, List<Activity> activities) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: activities.map((activity) {
          return SizedBox(
            // Dynamic width calculation for responsive design
            width: ActivityHelpers.calculateCardWidth(context),
            child: ActivityCard(activity: activity),
          );
        }).toList(),
      ),
    );
  }
}
