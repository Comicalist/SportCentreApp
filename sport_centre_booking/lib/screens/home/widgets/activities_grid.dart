import 'package:flutter/material.dart';
import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../widgets/activity/activity_card.dart';
import '../../../utils/activity_helpers.dart';

/// Widget for displaying activities in a responsive grid layout
class ActivitiesGrid extends StatelessWidget {
  final String selectedCategory;
  final String? selectedClub;
  final DateTime? selectedDate;
  final String? selectedTimeCategory;
  final String? selectedLocation;
  final String? searchQuery;
  final bool onlyAvailable;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: ActivityService.getFilteredActivities(
        category: selectedCategory,
        club: selectedClub,
        date: selectedDate,
        timeCategory: selectedTimeCategory,
        location: selectedLocation,
        searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
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
          ElevatedButton(
            onPressed: () => _addSampleActivities(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Sample Activities'),
          ),
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

  Future<void> _addSampleActivities(BuildContext context) async {
    try {
      await ActivityService.addSampleActivities();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample activities added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}