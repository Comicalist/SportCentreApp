import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../notifications/notifications_drawer.dart';

/// Unified app bar providing real-time notification access across all screens
/// Displays unread count badges to encourage user engagement with updates
class AppBarWithNotifications extends StatelessWidget
    implements PreferredSizeWidget {
  const AppBarWithNotifications({super.key, required this.title, this.actions});
  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      title: Text(title),
      actions: [
        if (userId != null) ...[
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
                  // Visual urgency indicator for pending notifications
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
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
