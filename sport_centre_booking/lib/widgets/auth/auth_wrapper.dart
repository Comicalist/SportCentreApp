import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/main_navigation.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/booking/bookings.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug prints to see what's happening
        print('AuthWrapper - isLoggedIn: ${authProvider.isLoggedIn}');
        print('AuthWrapper - appUser loaded: ${authProvider.appUser != null}');
        if (authProvider.appUser != null) {
          print('AuthWrapper - user role: ${authProvider.appUser!.role}');
          print('AuthWrapper - isAdmin: ${authProvider.isAdmin}');
        }

        // User not logged in - show login screen (starting with sign-in form)
        if (!authProvider.isLoggedIn) {
          return LoginScreen(isSignUp: false);
        }

        // User logged in but appUser still loading - show loading
        if (authProvider.isLoggedIn && authProvider.appUser == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        // User logged in AND appUser loaded - show main app
        return const MainNavigation();
      },
    );
  }
}