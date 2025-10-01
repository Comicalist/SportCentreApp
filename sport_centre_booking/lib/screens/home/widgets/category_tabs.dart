import 'package:flutter/material.dart';
import '../../../services/activity_service.dart';
import '../../../utils/activity_helpers.dart';

/// Widget for displaying category filter tabs
class CategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: StreamBuilder<List<String>>(
        stream: ActivityService.getAvailableCategoriesStream(),
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
                          : ActivityHelpers.getCategoryColor(category),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) => onCategorySelected(category),
                  backgroundColor: Colors.white,
                  selectedColor: ActivityHelpers.getCategoryColor(category),
                  side: BorderSide(
                    color: ActivityHelpers.getCategoryColor(category),
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
    );
  }
}