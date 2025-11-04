import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// 🧪 Testing Tools Panel
/// 
/// Debug-only widget for testing notification system.
/// Provides buttons to:
/// - Create test in-app notifications
/// - Queue test emails
/// - Manually trigger cron job
class TestingPanel extends StatelessWidget {
  final String userId;

  const TestingPanel({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '🧪 Testing Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildTestButton(
                context,
                icon: Icons.bug_report,
                iconColor: Colors.orange,
                title: 'Create Test Notification',
                subtitle: 'Test in-app notification system',
                buttonLabel: 'Test',
                buttonColor: Colors.orange,
                onPressed: () => _createTestNotification(context, 'inApp'),
              ),
              const Divider(height: 1),
              _buildTestButton(
                context,
                icon: Icons.email,
                iconColor: Colors.blue,
                title: 'Send Test Email',
                subtitle: 'Test email notification system',
                buttonLabel: 'Send',
                buttonColor: Colors.blue,
                onPressed: () => _createTestNotification(context, 'email'),
              ),
              const Divider(height: 1),
              _buildTestButton(
                context,
                icon: Icons.schedule,
                iconColor: Colors.purple,
                title: 'Trigger Cron Job Now',
                subtitle: 'Manually process pending notifications',
                buttonLabel: 'Run',
                buttonColor: Colors.purple,
                onPressed: () => _triggerCronJobManually(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ElevatedButton.icon(
        icon: Icon(_getButtonIcon(buttonLabel), size: 18),
        label: Text(buttonLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }

  IconData _getButtonIcon(String label) {
    switch (label) {
      case 'Test':
        return Icons.add_alert;
      case 'Send':
        return Icons.send;
      case 'Run':
        return Icons.refresh;
      default:
        return Icons.play_arrow;
    }
  }

  Future<void> _createTestNotification(
    BuildContext context,
    String method,
  ) async {
    try {
      if (method == 'inApp') {
        // Create in-app test notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'type': 'bookingReminder',
          'title': '🧪 Test Notification',
          'body':
              'This is a test notification created at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'bookingId': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'activityName': 'Test Activity',
          'scheduledFor': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 2)),
          ),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child:
                        Text('Test notification created! Check the bell icon 🔔'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Create test email by adding to pendingNotifications with past scheduledFor
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        await FirebaseFirestore.instance.collection('pendingNotifications').add({
          'userId': userId,
          'bookingId': 'test-email-${DateTime.now().millisecondsSinceEpoch}',
          'type': 'bookingReminder',
          'scheduledFor': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          'method': 'email',
          'userEmail': userDoc.data()?['email'],
          'activityName': 'Test Yoga Class',
          'bookingTime': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 2)),
          ),
          'created': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Test email queued!'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click "Run" button to trigger cron job and send email now.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _triggerCronJobManually(BuildContext context) async {
    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Triggering cron job...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://us-central1-sportcentreapp.cloudfunctions.net/triggerCheckPendingNotifications'),
          )
          .timeout(const Duration(seconds: 30));

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Cron job executed successfully!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    response.body,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ Manual cron trigger error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Error triggering cron job'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
