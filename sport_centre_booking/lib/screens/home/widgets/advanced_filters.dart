import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/activity_service.dart';
import '../../../utils/constants.dart';

/// Widget for advanced filtering options
class AdvancedFilters extends StatelessWidget {
  final bool isExpanded;
  final String? selectedClub;
  final DateTime? selectedDate;
  final String? selectedTimeCategory;
  final String? selectedLocation;
  final bool onlyAvailable;
  final Function(String?) onClubChanged;
  final Function(DateTime?) onDateChanged;
  final Function(String?) onTimeCategoryChanged;
  final Function(String?) onLocationChanged;
  final Function(bool) onAvailabilityChanged;
  final VoidCallback onClearFilters;

  const AdvancedFilters({
    super.key,
    required this.isExpanded,
    required this.selectedClub,
    required this.selectedDate,
    required this.selectedTimeCategory,
    required this.selectedLocation,
    required this.onlyAvailable,
    required this.onClubChanged,
    required this.onDateChanged,
    required this.onTimeCategoryChanged,
    required this.onLocationChanged,
    required this.onAvailabilityChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded ? null : 0,
      child: isExpanded ? _buildFilterContent(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Row 1: Club and Date
        Row(
          children: [
            Expanded(
              child: _buildStreamDropdown(
                label: 'Club',
                value: selectedClub,
                stream: ActivityService.getAvailableClubsStream(),
                onChanged: onClubChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(context),
            ),
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
                items: AppConstants.timeCategories,
                onChanged: onTimeCategoryChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStreamDropdown(
                label: 'Location',
                value: selectedLocation,
                stream: ActivityService.getAvailableLocationsStream(),
                onChanged: onLocationChanged,
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
                    onChanged: (value) => onAvailabilityChanged(value ?? false),
                    activeColor: Colors.teal,
                  ),
                  const Text('Only show available'),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
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
              child: Text('All ${label}s', style: TextStyle(color: Colors.grey[600])),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            )),
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
            borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
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
                  child: Text('All ${label}s', style: TextStyle(color: Colors.grey[600])),
                ),
                ...items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
        onTap: () => _showDatePicker(context),
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
                    color: selectedDate != null ? Colors.black87 : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              if (selectedDate != null)
                InkWell(
                  onTap: () => onDateChanged(null),
                  child: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}