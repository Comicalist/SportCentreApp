import 'package:flutter/material.dart';
import '../../../services/activity_service.dart';
import '../../../utils/activity_helpers.dart';

/// Dynamic category filter tabs with real-time activity classification
/// Provides horizontal scrolling interface for activity type selection and discovery
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });
  
  final String selectedCategory;
  final Function(String) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: StreamBuilder<List<String>>(
        // Real-time category data from available activities
        stream: ActivityService.getAvailableCategoriesStream(),
        builder: (context, snapshot) {
          // Always include "All" option for comprehensive view
          final categories = <String>['All'];
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
                      // Dynamic text color based on selection state
                      color: isSelected
                          ? Colors.white
                          : ActivityHelpers.getCategoryColor(category),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) => onCategorySelected(category),
                  backgroundColor: Colors.white,
                  // Category-specific color theming for brand recognition
                  selectedColor: ActivityHelpers.getCategoryColor(category),
                  side: BorderSide(
                    color: ActivityHelpers.getCategoryColor(category),
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
    );
  }
}
