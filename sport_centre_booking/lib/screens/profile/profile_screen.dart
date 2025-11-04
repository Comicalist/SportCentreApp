import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Hide firebase's AuthProvider to avoid name collision with your app's AuthProvider
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../providers/auth_provider.dart' as app_auth; // Alias your own AuthProvider
import '../../utils/colors.dart';
import '../../models/app_user.dart';
import '../../models/voucher.dart';
import '../../services/voucher_service.dart';
import '../../widgets/profile/testing_panel.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Same user data fetch as in RewardsScreen:
  /// reads users/{uid} once to get availablePoints and lifetimePointsEarned.
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        // 1) Not signed in -> simple gate screen
        if (!auth.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please sign in to view your profile'),
                ],
              ),
            ),
          );
        }

        // 2) Signed in but first AppUser not loaded yet -> loader
        if (auth.appUser == null) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // 3) Signed in + live profile stream for non-points parts (info, vouchers, etc.)
        final uid = auth.firebaseUser!.uid;
        final userDocStream =
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

        return StreamBuilder<DocumentSnapshot>(
          stream: userDocStream,
          builder: (context, snapshot) {
            // Use provider's user as fallback if stream hasn't emitted yet
            AppUser user = auth.appUser!;

            if (snapshot.hasError) {
              // Keep UI usable even on stream error
              debugPrint('Profile stream error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.exists) {
              try {
                user = AppUser.fromFirestore(snapshot.data!);
              } catch (_) {
                // Fallback to the previously loaded user
              }
            }

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          // TODO: implement edit profile
                          break;
                        case 'settings':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                          break;
                        case 'logout':
                          _handleLogout();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Profile'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.notifications_outlined),
                          title: Text('Notification Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoCard(user),
                    const SizedBox(height: 24),

                    if (user.isMember) ...[
                      _buildMembershipCard(user),
                      const SizedBox(height: 24),
                    ],

                    // ===== Points section: EXACTLY the same pattern as RewardsScreen =====
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserData(),
                      builder: (context, pointsSnap) {
                        if (pointsSnap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (!pointsSnap.hasData || pointsSnap.data == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load your rewards.',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please try again later.',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final data = pointsSnap.data!;
                        final availablePoints = (data['availablePoints'] ?? 0) as int;
                        final lifetimePoints = (data['lifetimePointsEarned'] ?? 0) as int;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Reward Points',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPointsCard('Available Points', availablePoints, Colors.green),
                            const SizedBox(height: 12),
                            _buildPointsCard('Lifetime Points Earned', lifetimePoints, Colors.orange),
                          ],
                        );
                      },
                    ),
                    // =======================================================================

                    const SizedBox(height: 24),
                    _buildVouchersSection(user.uid),
                    const SizedBox(height: 24),
                    _buildSettingsSection(context),

                    // Debug/testing panel only in debug builds
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      TestingPanel(userId: uid),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Settings section with quick access to notifications/preferences
  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                title: const Text('Notifications'),
                subtitle: const Text('Email or in-app preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: const Text('Booking History'),
                subtitle: const Text('View past activities'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking history coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Basic profile header with avatar, name, email, and membership badge.
  Widget _buildUserInfoCard(AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: {
            // Avatar with first letter fallback
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name / email / role badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isMember ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isMember ? 'Member' : 'Guest',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user.isMember ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          }.toList(),
        ),
      ),
    );
  }

  /// Points card identical to the one used in RewardsScreen.
  Widget _buildPointsCard(String label, int points, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.star, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            Text(
              '$points pts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membership card (unchanged from your previous version).
  Widget _buildMembershipCard(AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Membership',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.membershipType ?? 'Standard',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user.membershipExpiry != null)
              Text(
                'Expires: ${_formatDate(user.membershipExpiry!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('20% discount on all activities', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Bonus points on bookings', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Voucher list section for the user's vouchers.
  Widget _buildVouchersSection(String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.teal, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'My Vouchers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Jump to the Rewards tab (index 2 assumed)
                    DefaultTabController.of(context).animateTo(2);
                  },
                  child: const Text(
                    'Get More',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Voucher>>(
              stream: VoucherService.streamUserVouchers(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('Failed to load vouchers'),
                        ],
                      ),
                    ),
                  );
                }

                final vouchers = snapshot.data ?? [];
                final unusedVouchers = vouchers.where((v) => !v.isUsed && !v.isExpired).toList();
                final usedVouchers = vouchers.where((v) => v.isUsed || v.isExpired).toList();

                if (vouchers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No vouchers yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get vouchers from the Rewards tab',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active vouchers
                    if (unusedVouchers.isNotEmpty) ...[
                      const Text(
                        'Available',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      ...unusedVouchers.map((voucher) => _buildVoucherItem(voucher, true)),
                      const SizedBox(height: 16),
                    ],

                    // Used/expired vouchers (collapsible)
                    if (usedVouchers.isNotEmpty) ...[
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        title: Text(
                          'Used & Expired (${usedVouchers.length})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                        ),
                        children: usedVouchers.map((voucher) => _buildVoucherItem(voucher, false)).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A single voucher row (active or used/expired).
  Widget _buildVoucherItem(Voucher voucher, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.teal.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Small type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getVoucherTypeColor(voucher.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              voucher.type == VoucherType.fitness ? 'FITNESS' : 'STUFF',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: _getVoucherTypeColor(voucher.type),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title + club
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                Text(
                  voucher.clubName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${voucher.amount.toStringAsFixed(2)} CHF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.grey[600],
                ),
              ),
              Text(
                voucher.statusDisplayText,
                style: TextStyle(fontSize: 12, color: isActive ? Colors.teal : Colors.grey[500]),
              ),
            ],
          ),

          // Info button for active vouchers
          if (isActive && voucher.code != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showVoucherDetails(voucher),
              icon: const Icon(Icons.info_outline, size: 18),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getVoucherTypeColor(VoucherType type) {
    switch (type) {
      case VoucherType.fitness:
        return Colors.teal;
      case VoucherType.stuff:
        return Colors.purple;
    }
  }

  /// Voucher detail modal (code, value, club, expiry).
  void _showVoucherDetails(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(voucher.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(voucher.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher Code:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.code ?? 'N/A',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Value: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${voucher.amount.toStringAsFixed(2)} CHF'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Club: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(voucher.clubName),
              ],
            ),
            if (voucher.expiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Expires: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(_formatDate(voucher.expiresAt!)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Logout confirmation dialog and sign-out action.
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<app_auth.AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Short, human-readable date (e.g., "Jan 5, 2025").
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
