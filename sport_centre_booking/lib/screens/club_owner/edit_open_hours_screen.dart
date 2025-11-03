import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/club.dart';
import '../../services/blocking_service.dart';

/// Club operating hours management with time blocking functionality
/// Handles recurring weekly blocks and one-time closures with conflict detection
class EditOpenHoursScreen extends StatefulWidget {
  const EditOpenHoursScreen({super.key, required this.club});
  final Club club;

  @override
  State<EditOpenHoursScreen> createState() => _EditOpenHoursScreenState();
}

class _EditOpenHoursScreenState extends State<EditOpenHoursScreen> {
  late List<Map<String, dynamic>> blockedTimes;

  @override
  void initState() {
    super.initState();
    // Initialize with existing club blocked times for editing
    blockedTimes = List<Map<String, dynamic>>.from(widget.club.blockedTimes);
  }

  /// Create or edit blocked time periods with validation and conflict checking
  /// Supports both recurring weekly patterns and one-time date ranges
  Future<void> _pickBlockedTime({Map<String, dynamic>? existing}) async {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');

    // Initialize form state from existing block or defaults
    String? startDayOfWeek = existing?['startDayOfWeek'];
    String? endDayOfWeek = existing?['endDayOfWeek'];
    String? startDate = existing?['startDate'];
    String? endDate = existing?['endDate'];
    String? startTime = existing?['startTime'];
    String? endTime = existing?['endTime'];
    bool recurring = existing?['recurring'] ?? false;
    String reason = existing?['reason'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Blocked Time' : 'Edit Blocked Time',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Business reason for blocking time
                  TextFormField(
                    initialValue: reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why is this time blocked?',
                    ),
                    onChanged: (val) => setDialogState(() => reason = val),
                  ),
                  const SizedBox(height: 12),
                  
                  // Toggle between recurring weekly and one-time blocks
                  SwitchListTile(
                    title: const Text('Recurring Weekly'),
                    value: recurring,
                    onChanged: (val) => setDialogState(() => recurring = val),
                  ),
                  
                  // Recurring weekly pattern configuration
                  if (recurring) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Start Day of Week',
                      ),
                      initialValue: startDayOfWeek,
                      items:
                          const [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday',
                              ]
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setDialogState(() => startDayOfWeek = val),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'End Day of Week',
                      ),
                      initialValue: endDayOfWeek,
                      items:
                          const [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday',
                              ]
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setDialogState(() => endDayOfWeek = val),
                    ),
                  ] else ...[
                    // One-time date range configuration
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(startDate ?? 'No date selected'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(
                            () => startDate = picked.toIso8601String().split(
                              'T',
                            )[0],
                          );
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(endDate ?? 'No date selected'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate != null
                              ? DateTime.parse(startDate!)
                              : now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(
                            () => endDate = picked.toIso8601String().split(
                              'T',
                            )[0],
                          );
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  
                  // Time range selection for blocked periods
                  ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(startTime ?? '--:--'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(
                          () => startTime = timeFormat.format(
                            DateTime(
                              now.year,
                              now.month,
                              now.day,
                              picked.hour,
                              picked.minute,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(endTime ?? '--:--'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(
                          () => endTime = timeFormat.format(
                            DateTime(
                              now.year,
                              now.month,
                              now.day,
                              picked.hour,
                              picked.minute,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                // Validate and save blocked time configuration
                ElevatedButton(
                  onPressed: () {
                    if ((recurring &&
                            startDayOfWeek != null &&
                            endDayOfWeek != null) ||
                        (!recurring &&
                            startDate != null &&
                            endDate != null &&
                            startTime != null &&
                            endTime != null)) {
                      if (!recurring) {
                        // Validate date range for one-time blocks
                        final start = DateTime.parse(startDate!);
                        final end = DateTime.parse(endDate!);
                        if (start.isAfter(end)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Start date cannot be after end date',
                              ),
                            ),
                          );
                          return;
                        }

                        // Validate time range for same-day blocks
                        if (start.isAtSameMomentAs(end)) {
                          final startParts = startTime!
                              .split(':')
                              .map(int.parse)
                              .toList();
                          final endParts = endTime!
                              .split(':')
                              .map(int.parse)
                              .toList();
                          final startDt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            startParts[0],
                            startParts[1],
                          );
                          final endDt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            endParts[0],
                            endParts[1],
                          );

                          if (endDt.isBefore(startDt)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'End time cannot be before start time',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                      }

                      // Create validated blocked time entry
                      final newEntry = {
                        'startDayOfWeek': recurring ? startDayOfWeek : null,
                        'endDayOfWeek': recurring ? endDayOfWeek : null,
                        'startDate': recurring ? null : startDate,
                        'endDate': recurring ? null : endDate,
                        'startTime': startTime,
                        'endTime': endTime,
                        'recurring': recurring,
                        'reason': reason,
                      };
                      Navigator.pop(context, newEntry);
                    }
                  },

                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null) {
        // Check for conflicting activities before applying block
        final conflicts = await BlockingService.getActivitiesInTimeRange(
          clubId: widget.club.id,
          blockData: result,
        );

        if (conflicts.isNotEmpty && mounted) {
          // Show warning dialog for existing activity conflicts
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cannot Block'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activities exist during this time. Remove them first:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...conflicts.map(
                      (activity) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event, color: Colors.red),
                          title: Text(activity.name),
                          subtitle: Text(
                            '${DateFormat('MMM dd, yyyy').format(activity.date)} at ${activity.time}\n${activity.facilityName}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // No conflicts - save the blocked time configuration
        setState(() {
          if (existing != null) {
            final index = blockedTimes.indexOf(existing);
            blockedTimes[index] = result;
          } else {
            blockedTimes.add(result);
          }
        });
        await _saveToFirestore();
      }
    });
  }

  /// Persist blocked times configuration to Firestore
  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.club.id)
          .set({'blockedTimes': blockedTimes}, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Blocked times updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Open Hours')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Display all configured blocked time periods
          for (final block in blockedTimes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: Text(
                  block['recurring']
                      ? '${block['startDayOfWeek']} ${block['startTime']} → ${block['endDayOfWeek']} ${block['endTime']}'
                      : '${block['startDate']} ${block['startTime']} → ${block['endDate']} ${block['endTime']}',
                ),
                subtitle: Text(
                  block['reason'] != null && block['reason'].isNotEmpty
                      ? '${block['recurring'] ? 'Repeats weekly' : 'One-time'} – ${block['reason']}'
                      : (block['recurring']
                            ? 'Repeats weekly'
                            : 'One-time block'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit existing blocked time
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _pickBlockedTime(existing: block),
                    ),
                    // Remove blocked time period
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        setState(() => blockedTimes.remove(block));
                        await _saveToFirestore();
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Add new blocked time period
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Blocked Time'),
              onPressed: _pickBlockedTime,
            ),
          ),
        ],
      ),
    );
  }
}
