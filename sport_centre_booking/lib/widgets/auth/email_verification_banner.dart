import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../utils/colors.dart';

class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Only show if user is logged in and email is not verified
        if (!authProvider.isLoggedIn || authProvider.isEmailVerified) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange.shade100,
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please verify your email address to secure your account.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmailVerificationScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // This could hide the banner temporarily, but we'll keep it simple for now
                },
                child: Icon(
                  Icons.close,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
