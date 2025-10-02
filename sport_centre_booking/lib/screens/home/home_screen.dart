import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/category_tabs.dart';
import 'widgets/advanced_filters.dart';
import 'widgets/activities_grid.dart';

/// Main home screen showing activities with filtering capabilities
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Filter state
  String selectedCategory = 'All';
  bool isFilterExpanded = false;
  String? selectedClub;
  DateTime? selectedDate;
  String? selectedTimeCategory;
  String? selectedLocation;
  String searchQuery = '';
  bool onlyAvailable = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: ActivitiesGrid(
                selectedCategory: selectedCategory,
                selectedClub: selectedClub,
                selectedDate: selectedDate,
                selectedTimeCategory: selectedTimeCategory,
                selectedLocation: selectedLocation,
                searchQuery: searchQuery,
                onlyAvailable: onlyAvailable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header section with title, search, and filters
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 20),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          _buildSearchAndFilterToggle(),
          _buildAdvancedFilters(),
        ],
      ),
    );
  }

  /// Build title and welcome message
  Widget _buildTitle() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
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
            Text(
              authProvider.isLoggedIn 
                  ? 'Welcome back, ${authProvider.userFirstName}!'
                  : 'Discover amazing activities',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  /// Build category filter tabs
  Widget _buildCategoryTabs() {
    return CategoryTabs(
      selectedCategory: selectedCategory,
      onCategorySelected: (category) {
        setState(() {
          selectedCategory = category;
        });
      },
    );
  }

  /// Build search bar and filter toggle button
  Widget _buildSearchAndFilterToggle() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search),
              border: _buildInputBorder(),
              enabledBorder: _buildInputBorder(),
              focusedBorder: _buildInputBorder(focused: true),
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
        _buildFilterToggleButton(),
      ],
    );
  }

  /// Build filter toggle button
  Widget _buildFilterToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(
          isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
          color: isFilterExpanded ? Colors.teal : Colors.grey,
        ),
        onPressed: () {
          setState(() {
            isFilterExpanded = !isFilterExpanded;
          });
        },
      ),
    );
  }

  /// Build advanced filters section
  Widget _buildAdvancedFilters() {
    return AdvancedFilters(
      isExpanded: isFilterExpanded,
      selectedClub: selectedClub,
      selectedDate: selectedDate,
      selectedTimeCategory: selectedTimeCategory,
      selectedLocation: selectedLocation,
      onlyAvailable: onlyAvailable,
      onClubChanged: (value) => setState(() => selectedClub = value),
      onDateChanged: (value) => setState(() => selectedDate = value),
      onTimeCategoryChanged: (value) => setState(() => selectedTimeCategory = value),
      onLocationChanged: (value) => setState(() => selectedLocation = value),
      onAvailabilityChanged: (value) => setState(() => onlyAvailable = value),
      onClearFilters: _clearFilters,
    );
  }

  /// Build input border for text fields
  OutlineInputBorder _buildInputBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focused ? Colors.teal : Colors.grey.shade300,
      ),
    );
  }

  /// Clear all filters
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
}