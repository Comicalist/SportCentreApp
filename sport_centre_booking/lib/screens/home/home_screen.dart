import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/notifications/notifications_drawer.dart';
import 'widgets/activities_grid.dart';
import 'widgets/advanced_filters.dart';
import 'widgets/category_tabs.dart';

/// Primary activity discovery interface with comprehensive filtering and search
/// Central hub for users to explore, filter, and access available sport activities
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Activity discovery and filtering state management
  String selectedCategory = 'All';
  bool isFilterExpanded = false;
  String? selectedClub;
  DateTime? selectedDate;
  String? selectedTimeCategory;
  String? selectedFacility;
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
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text('Activities'),
        actions: [
          if (userId != null)
            // Real-time notification system with unread count badge
            StreamBuilder<int>(
              stream: NotificationService().getUnreadCount(userId),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        showNotificationsDrawer(context);
                      },
                      tooltip: 'Notifications',
                    ),
                    // Dynamic badge for unread notifications
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
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
                selectedLocation: selectedFacility,
                searchQuery: searchQuery,
                onlyAvailable: onlyAvailable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header section with user engagement and discovery tools
  /// Combines branding, search, filtering, and category navigation
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

  /// Personalized welcome message and app branding
  /// Adapts greeting based on user authentication status
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

  /// Category-based activity filtering for quick discovery
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

  /// Primary search interface with expandable advanced filtering
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

  /// Toggle button for advanced filtering options
  /// Visual feedback for filter expansion state
  Widget _buildFilterToggleButton() {
    return DecoratedBox(
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

  /// Advanced filtering system with hierarchical dependencies
  /// Manages complex filter relationships and state synchronization
  Widget _buildAdvancedFilters() {
    return AdvancedFilters(
      isExpanded: isFilterExpanded,
      selectedClub: selectedClub,
      selectedDate: selectedDate,
      selectedTimeCategory: selectedTimeCategory,
      selectedFacility: selectedFacility,
      onlyAvailable: onlyAvailable,
      onClubChanged: (value) {
        setState(() {
          selectedClub = value;
          // Clear facility when club changes to maintain data integrity
          selectedFacility = null;
        });
      },
      onDateChanged: (value) => setState(() => selectedDate = value),
      onTimeCategoryChanged: (value) =>
          setState(() => selectedTimeCategory = value),
      onFacilityChanged: (value) => setState(() => selectedFacility = value),
      onAvailabilityChanged: (value) => setState(() => onlyAvailable = value),
      onClearFilters: _clearFilters,
    );
  }

  /// Consistent input styling for search and filter components
  OutlineInputBorder _buildInputBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: focused ? Colors.teal : Colors.grey.shade300,
      ),
    );
  }

  /// Reset all filters to default state for fresh discovery
  /// Maintains search interface consistency and user experience
  void _clearFilters() {
    setState(() {
      selectedClub = null;
      selectedDate = null;
      selectedTimeCategory = null;
      selectedFacility = null;
      searchQuery = '';
      onlyAvailable = false;
      searchController.clear();
    });
  }
}
