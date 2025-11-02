import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../utils/activity_helpers.dart';
import '../../../widgets/activity/activity_card.dart';

/// Widget for displaying activities in a responsive grid layout
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

  Widget _buildActivitiesGrid(BuildContext context, List<Activity> activities) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: activities.map((activity) {
          return SizedBox(
            width: ActivityHelpers.calculateCardWidth(context),
            child: ActivityCard(activity: activity),
          );
        }).toList(),
      ),
    );
  }
}
