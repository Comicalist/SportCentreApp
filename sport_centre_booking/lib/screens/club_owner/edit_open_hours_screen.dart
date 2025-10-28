import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sport_centre_booking/models/club.dart';


class EditOpenHoursScreen extends StatefulWidget {
  final Club club;

  const EditOpenHoursScreen({super.key, required this.club});

  @override
  State<EditOpenHoursScreen> createState() => _EditOpenHoursScreenState();
}

class _EditOpenHoursScreenState extends State<EditOpenHoursScreen> {
  late List<Map<String, dynamic>> blockedTimes;

  @override
  void initState() {
    super.initState();
    blockedTimes = List<Map<String, dynamic>>.from(widget.club.blockedTimes ?? []);
  }

  Future<void> _pickBlockedTime({Map<String, dynamic>? existing}) async {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');


    String? dayOfWeek = existing?['dayOfWeek'];
    String? date = existing?['date'];
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
              title: Text(existing == null ? 'Add Blocked Time' : 'Edit Blocked Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why is this time blocked?',
                    ),
                    onChanged: (val) => setDialogState(() => reason = val),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Recurring Weekly'),
                    value: recurring,
                    onChanged: (val) => setDialogState(() => recurring = val),
                  ),
                  if (recurring)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Day of Week'),
                      value: dayOfWeek,
                      items: const [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) => setDialogState(() => dayOfWeek = val),
                    )
                  else
                    InputDatePickerFormField(
                      firstDate: now.subtract(const Duration(days: 0)),
                      lastDate: now.add(const Duration(days: 365)),
                      fieldLabelText: 'Specific Date',
                      initialDate: DateTime.tryParse(date ?? '') ?? now,
                      onDateSubmitted: (selectedDate) =>
                          setDialogState(() => date = selectedDate.toIso8601String().split('T')[0]),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(startTime ?? '--:--'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => startTime =
                            timeFormat.format(DateTime(now.year, now.month, now.day, picked.hour, picked.minute)));
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
                        setDialogState(() => endTime =
                            timeFormat.format(DateTime(now.year, now.month, now.day, picked.hour, picked.minute)));
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
                ElevatedButton(
                  onPressed: () {
                    if ((recurring && dayOfWeek != null) ||
                        (!recurring && date != null && startTime != null && endTime != null)) {
                      final newEntry = {
                        'dayOfWeek': recurring ? dayOfWeek : null,
                        'date': recurring ? null : date,
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
    ).then((result) {
      if (result != null) {
        setState(() {
          if (existing != null) {
            final index = blockedTimes.indexOf(existing);
            blockedTimes[index] = result;
          } else {
            blockedTimes.add(result);
          }
        });
      }
    });
  }

  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.club.id)
        .set({'blockedTimes': blockedTimes}, SetOptions(merge: true));

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Blocked times updated')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Open Hours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToFirestore,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final block in blockedTimes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: Text(
                  block['recurring']
                      ? '${block['dayOfWeek']} ${block['startTime']} - ${block['endTime']}'
                      : '${block['date']} ${block['startTime']} - ${block['endTime']}',
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
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _pickBlockedTime(existing: block),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          setState(() => blockedTimes.remove(block)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Blocked Time'),
              onPressed: () => _pickBlockedTime(),
            ),
          ),
        ],
      ),
    );
  }
}
