import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/booking/bookings.dart';
import '../../screens/rewards.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_panel.dart';
import '../../screens/club_owner/club_owner_panel.dart';
import '../auth/email_verification_banner.dart';

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
        // Check both admin and club owner status
        final bool isAdmin = authProvider.isAdmin;
        final bool isClubOwner = authProvider.isClubOwner;
        
     
        
        final screens = _getScreens(isAdmin, isClubOwner);
        final navItems = _getNavItems(isAdmin, isClubOwner);

        return Scaffold(
          body: Column(
            children: [
              const EmailVerificationBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
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

  List<Widget> _getScreens(bool isAdmin, bool isClubOwner) {
    final screens = [
      HomeScreen(),
      BookingsScreen(),
      RewardsScreen(),
      ProfileScreen(),
    ];
    
    // Add Club Owner Panel if user is club owner
    if (isClubOwner) {
      screens.add(ClubOwnerPanel());
    }
    
    // Add Admin Panel if user is admin
    if (isAdmin) {
      screens.add(AdminPanel());
    }
    
    return screens;
  }

  List<BottomNavigationBarItem> _getNavItems(bool isAdmin, bool isClubOwner) {
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookings'),
      const BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
    
    // Add Club Owner tab if user is club owner
    if (isClubOwner) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'My Clubs',
      ));
    }
    
    // Add Admin tab if user is admin
    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }

   
    
    return items;
  }
}