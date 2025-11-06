import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_panel.dart';
import '../../screens/booking/bookings.dart';
import '../../screens/club_owner/club_owner_panel.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rewards.dart';
import '../auth/email_verification_banner.dart';

/// Dynamic navigation system adapting to user roles and permissions
/// Provides role-based access to management features for admins and club owners
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAdmin = authProvider.isAdmin;
        final isClubOwner = authProvider.isClubOwner;

        final screens = _getScreens(isAdmin, isClubOwner);
        final navItems = _getNavItems(isAdmin, isClubOwner);

        return Scaffold(
          body: Column(
            children: [
              const EmailVerificationBanner(),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: screens),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index < screens.length) {
                setState(() => _currentIndex = index);
              }
            },
            items: navItems,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
          ),
        );
      },
    );
  }

  /// Builds screen array with conditional management panels based on user privileges
  List<Widget> _getScreens(bool isAdmin, bool isClubOwner) {
    final screens = [
      const HomeScreen(),
      const BookingsScreen(),
      const RewardsScreen(),
      const ProfileScreen(),
    ];

    if (isClubOwner) {
      screens.add(const ClubOwnerPanel());
    }

    if (isAdmin) {
      screens.add(AdminPanel());
    }

    return screens;
  }

  /// Creates navigation items matching user access level for seamless UX
  List<BottomNavigationBarItem> _getNavItems(bool isAdmin, bool isClubOwner) {
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bookmark),
        label: 'Bookings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: 'Rewards',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (isClubOwner) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'My Clubs',
        ),
      );
    }

    if (isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return items;
  }
}
