import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (userId == null) return;

    final prefs = NotificationPreferences(
      method: _selectedMethod,
      reminderHoursBefore: _selectedHours,
    );

    await _notificationService.savePreferences(userId, prefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Method selection
                Text('Preferred Method',
                    style: Theme.of(context).textTheme.titleLarge),
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

                // Email warning
                if (_selectedMethod == NotificationMethod.email) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Email notifications require Firebase Blaze plan',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Timing
                Text('Booking Reminder',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Notify me'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedHours,
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
                                '$hours hour${hours > 1 ? 's' : ''} before'),
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
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
          color:
              isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
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
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
