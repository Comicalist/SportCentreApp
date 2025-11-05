import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/voucher.dart';
import '../services/notification_service.dart';
import '../services/voucher_service.dart';
import '../widgets/notifications/notifications_drawer.dart';

/// Voucher marketplace for redeeming points into club discounts and merchandise
/// Features real-time points tracking and instant voucher purchases with notifications
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  /// Stream current user points data for real-time balance updates
  Stream<Map<String, dynamic>?> _getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rewards',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (userId != null)
            /// Notification bell with unread count badge
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
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _getUserDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load your rewards.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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

          final data = snapshot.data!;
          final availablePoints = (data['availablePoints'] ?? 0) as int;
          final lifetimePoints = (data['lifetimePointsEarned'] ?? 0) as int;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// User points dashboard for purchase decisions
                const Text(
                  'Your Reward Points',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                /// Points balance cards with visual hierarchy
                _buildPointsCard(
                  'Available Points',
                  availablePoints,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildPointsCard(
                  'Lifetime Points Earned',
                  lifetimePoints,
                  Colors.orange,
                ),

                const SizedBox(height: 32),

                /// Voucher marketplace section
                const Text(
                  'Available Vouchers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                /// Real-time voucher catalog with purchase capabilities
                Expanded(
                  child: StreamBuilder<List<Voucher>>(
                    stream: VoucherService.streamAvailableVouchers(),
                    builder: (context, voucherSnapshot) {
                      if (voucherSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (voucherSnapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              const Text('Failed to load vouchers'),
                            ],
                          ),
                        );
                      }

                      final vouchers = voucherSnapshot.data ?? [];

                      if (vouchers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No vouchers available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later for new vouchers!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = vouchers[index];
                          return _buildVoucherCard(
                            context,
                            voucher,
                            availablePoints,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Points balance display card with color-coded categories
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

  /// Individual voucher card with purchase validation and category indicators
  Widget _buildVoucherCard(
    BuildContext context,
    Voucher voucher,
    int userPoints,
  ) {
    final canAfford = userPoints >= voucher.pointsCost;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Voucher category badge for easy identification
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getVoucherTypeColor(
                      voucher.type,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher.type == VoucherType.fitness ? 'FITNESS' : 'STUFF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getVoucherTypeColor(voucher.type),
                    ),
                  ),
                ),
                const Spacer(),

                /// Club branding and source identification
                Text(
                  voucher.clubName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Voucher marketing content
            Text(
              voucher.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              voucher.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            /// Purchase information and redemption interface
            Row(
              children: [
                /// Voucher monetary value display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${voucher.amount.toStringAsFixed(2)} CHF',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                /// Points cost indicator
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${voucher.pointsCost} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                /// Purchase validation and transaction initiation
                if (userId != null)
                  ElevatedButton(
                    onPressed: canAfford
                        ? () => _purchaseVoucher(context, voucher, userId)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? Colors.teal
                          : Colors.grey[300],
                      foregroundColor: canAfford
                          ? Colors.white
                          : Colors.grey[600],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      canAfford
                          ? 'Redeem'
                          : 'Need ${voucher.pointsCost - userPoints} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Category-based color coding for voucher types
  Color _getVoucherTypeColor(VoucherType type) {
    switch (type) {
      case VoucherType.fitness:
        return Colors.teal;
      case VoucherType.stuff:
        return Colors.purple;
    }
  }

  /// Execute voucher purchase transaction with error handling and user feedback
  Future<void> _purchaseVoucher(
    BuildContext context,
    Voucher voucher,
    String userId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await VoucherService.purchaseVoucher(voucher.id, userId);

      if (!context.mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showSuccessDialog(context, voucher);
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Success confirmation with voucher code and usage instructions
  void _showSuccessDialog(BuildContext context, Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Voucher Purchased!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have successfully purchased "${voucher.title}"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            /// Voucher redemption code for club use
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voucher Code:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.code ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Expires: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  voucher.expiresAt != null
                      ? _formatDate(voucher.expiresAt!)
                      : '1 year from purchase',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can view and use your vouchers in your profile.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Purchase failure notification with error details
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Purchase Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Date formatting for voucher expiration display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
