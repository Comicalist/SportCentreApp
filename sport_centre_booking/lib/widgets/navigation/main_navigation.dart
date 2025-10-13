import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/booking/bookings.dart';
import '../../screens/rewards.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_panel.dart';

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
        // This will now work because appUser is loaded in AuthProvider
        final bool isAdmin = authProvider.isAdmin;
        
        print('MainNavigation - isAdmin: $isAdmin');
        
        final screens = _getScreens(isAdmin);
        final navItems = _getNavItems(isAdmin);

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
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

  List<Widget> _getScreens(bool isAdmin) {
    final screens = [
      HomeScreen(),
      BookingsScreen(),
      RewardsScreen(),
      ProfileScreen(),
    ];
    
    // Only add AdminPanel if user is admin
    if (isAdmin) {
      screens.add(AdminPanel());
    }
    
    return screens;
  }

  List<BottomNavigationBarItem> _getNavItems(bool isAdmin) {
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookings'),
      const BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
    
    // Only add Admin tab if user is admin
    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }

    print('Screens count: ${items.length}');
    print('Admin panel included: $isAdmin');
    
    return items;
  }
}