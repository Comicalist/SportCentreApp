import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/notification_preferences.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  NotificationMethod _selectedMethod = NotificationMethod.inApp;
  int _selectedHours = 2;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final prefs = await _notificationService.getPreferences(userId);
    setState(() {
      _selectedMethod = prefs.method;
      _selectedHours = prefs.reminderHoursBefore;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = NotificationPreferences(
        method: _selectedMethod,
        reminderHoursBefore: _selectedHours,
      );

      await _notificationService.savePreferences(userId, prefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Preferences saved successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to save preferences: $e',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePreferences,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(_isLoading ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Method selection
                Text(
                  'Preferred Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MethodCard(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        isSelected: _selectedMethod == NotificationMethod.email,
                        onTap: () {
                          setState(() {
                            _selectedMethod = NotificationMethod.email;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MethodCard(
                        icon: Icons.notifications_outlined,
                        label: 'In-app',
                        isSelected: _selectedMethod == NotificationMethod.inApp,
                        onTap: () {
                          setState(() {
                            _selectedMethod = NotificationMethod.inApp;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Timing
                Text(
                  'Booking Reminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Notify me'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedHours,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [1, 2, 4, 12, 24].map((hours) {
                          return DropdownMenuItem(
                            value: hours,
                            child: Text(
                              '$hours hour${hours > 1 ? 's' : ''} before',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedHours = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? Colors.teal : Colors.grey),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
