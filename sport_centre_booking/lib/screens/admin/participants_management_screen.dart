import 'package:flutter/material.dart';
import '../../models/participant.dart';
import '../../models/booking.dart';
import '../../services/participant_service.dart';

/// Admin screen for managing event participants
/// Features: View, search, filter, edit, and remove participants with real-time sync
class AdminParticipantsScreen extends StatefulWidget {
  const AdminParticipantsScreen({Key? key}) : super(key: key);

  @override
  State<AdminParticipantsScreen> createState() => _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  BookingStatus? _selectedStatus;
  bool _showStats = true;
  
  Stream<List<Participant>>? _participantsStream;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _loadStats();
  }

  void _loadParticipants() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _participantsStream = ParticipantService.searchParticipants(_searchController.text);
      } else if (_selectedStatus != null) {
        _participantsStream = ParticipantService.getParticipantsByStatus(_selectedStatus!);
      } else {
        _participantsStream = ParticipantService.getAllParticipants();
      }
    });
  }

  Future<void> _loadStats() async {
    final stats = await ParticipantService.getParticipantStats();
    setState(() {
      _stats = stats;
    });
  }

  void _onSearch(String query) {
    _loadParticipants();
  }

  void _onStatusFilter(BookingStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadParticipants();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
    });
    _loadParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Participants Management'),
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.visibility),
            tooltip: _showStats ? 'Hide Statistics' : 'Show Statistics',
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadParticipants();
              _loadStats();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Panel
          if (_showStats && _stats != null) _buildStatsPanel(),

          // Search and Filter Bar
          _buildSearchAndFilterBar(),

          // Participants List
          Expanded(
            child: _buildParticipantsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participant Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatItem('Total', _stats!['total'].toString(), Colors.blue),
              _buildStatItem('Confirmed', _stats!['confirmed'].toString(), Colors.green),
              _buildStatItem('Pending', _stats!['pending'].toString(), Colors.orange),
              _buildStatItem('Cancelled', _stats!['cancelled'].toString(), Colors.red),
              _buildStatItem('Completed', _stats!['completed'].toString(), Colors.purple),
              _buildStatItem(
                'Revenue',
                '\$${_stats!['totalRevenue'].toStringAsFixed(2)}',
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or confirmation number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadParticipants();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearch,
          ),
          const SizedBox(height: 12),

          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text('Filter by Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
              _buildFilterChip('All', null),
              _buildFilterChip('Confirmed', BookingStatus.confirmed),
              _buildFilterChip('Pending', BookingStatus.pending),
              _buildFilterChip('Cancelled', BookingStatus.cancelled),
              _buildFilterChip('Completed', BookingStatus.completed),
              _buildFilterChip('Waitlist', BookingStatus.waitlist),
              if (_selectedStatus != null || _searchController.text.isNotEmpty)
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: _clearFilters,
                  avatar: const Icon(Icons.clear_all, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BookingStatus? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onStatusFilter(selected ? status : null);
      },
      selectedColor: Colors.blue.shade200,
    );
  }

  Widget _buildParticipantsList() {
    if (_participantsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Participant>>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading participants: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadParticipants(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final participants = snapshot.data ?? [];

        if (participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'No participants found matching your search'
                      : 'No participants registered yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            return _buildParticipantCard(participants[index]);
          },
        );
      },
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(participant.status),
          child: Text(
            participant.userName.isNotEmpty 
                ? participant.userName[0].toUpperCase() 
                : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          participant.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(participant.userEmail),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusBadge(participant.status),
                const SizedBox(width: 8),
                _buildMemberBadge(participant.isMemberBooking),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Activity', participant.activityTitle),
                _buildDetailRow('Activity Date', participant.formattedActivityDate),
                _buildDetailRow('Activity Time', participant.activityTime),
                _buildDetailRow('Booking Date', participant.formattedBookingDate),
                _buildDetailRow('Participants', participant.participantCount.toString()),
                _buildDetailRow('Amount Paid', '\$${participant.amountPaid.toStringAsFixed(2)}'),
                _buildDetailRow('Points Earned', participant.pointsEarned.toString()),
                _buildDetailRow('Confirmation #', participant.confirmationNumber),
                if (participant.phoneNumber != null)
                  _buildDetailRow('Phone', participant.phoneNumber!),
                if (participant.notes != null)
                  _buildDetailRow('Notes', participant.notes!),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editParticipant(participant),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _changeStatus(participant),
                      icon: const Icon(Icons.change_circle),
                      label: const Text('Change Status'),
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _removeParticipant(participant),
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMemberBadge(bool isMember) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMember ? Colors.amber.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMember ? Colors.amber.shade700 : Colors.grey.shade400),
      ),
      child: Text(
        isMember ? 'MEMBER' : 'GUEST',
        style: TextStyle(
          color: isMember ? Colors.amber.shade900 : Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.purple;
      case BookingStatus.waitlist:
        return Colors.blue;
    }
  }

  Future<void> _editParticipant(Participant participant) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditParticipantDialog(participant: participant),
    );

    if (result != null && mounted) {
      final success = await ParticipantService.updateParticipant(participant.id, result);
      
      if (success) {
        _showSnackBar('Participant updated successfully', Colors.green);
        _loadStats(); // Refresh stats
      } else {
        _showSnackBar('Failed to update participant', Colors.red);
      }
    }
  }

  Future<void> _changeStatus(Participant participant) async {
    final newStatus = await showDialog<BookingStatus>(
      context: context,
      builder: (context) => ChangeStatusDialog(currentStatus: participant.status),
    );

    if (newStatus != null && mounted) {
      final success = await ParticipantService.updateParticipantStatus(
        participant.id,
        newStatus,
      );

      if (success) {
        _showSnackBar('Status updated successfully', Colors.green);
        _loadStats(); // Refresh stats
      } else {
        _showSnackBar('Failed to update status', Colors.red);
      }
    }
  }

  Future<void> _removeParticipant(Participant participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text(
          'Are you sure you want to remove ${participant.userName} from ${participant.activityTitle}?\n\n'
          'This action cannot be undone and will:\n'
          '• Delete the booking record\n'
          '• Free up ${participant.participantCount} spot(s)\n'
          '• Remove from user\'s booking history',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ParticipantService.removeParticipant(participant.id);

      if (success) {
        _showSnackBar('Participant removed successfully', Colors.green);
        _loadStats(); // Refresh stats
      } else {
        _showSnackBar('Failed to remove participant', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Dialog for editing participant details
class EditParticipantDialog extends StatefulWidget {
  final Participant participant;

  const EditParticipantDialog({Key? key, required this.participant}) : super(key: key);

  @override
  State<EditParticipantDialog> createState() => _EditParticipantDialogState();
}

class _EditParticipantDialogState extends State<EditParticipantDialog> {
  late TextEditingController _participantCountController;
  late TextEditingController _amountController;
  late TextEditingController _pointsController;
  late TextEditingController _notesController;
  late bool _isMemberBooking;

  @override
  void initState() {
    super.initState();
    _participantCountController = TextEditingController(
      text: widget.participant.participantCount.toString(),
    );
    _amountController = TextEditingController(
      text: widget.participant.amountPaid.toStringAsFixed(2),
    );
    _pointsController = TextEditingController(
      text: widget.participant.pointsEarned.toString(),
    );
    _notesController = TextEditingController(
      text: widget.participant.notes ?? '',
    );
    _isMemberBooking = widget.participant.isMemberBooking;
  }

  @override
  void dispose() {
    _participantCountController.dispose();
    _amountController.dispose();
    _pointsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Participant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.participant.userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(widget.participant.activityTitle),
            const Divider(height: 24),
            TextField(
              controller: _participantCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Participants',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pointsController,
              decoration: const InputDecoration(
                labelText: 'Points Earned',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Member Booking'),
              value: _isMemberBooking,
              onChanged: (value) {
                setState(() {
                  _isMemberBooking = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final participantCount = int.tryParse(_participantCountController.text);
    final amount = double.tryParse(_amountController.text);
    final points = int.tryParse(_pointsController.text);

    if (participantCount == null || participantCount <= 0) {
      _showError('Please enter a valid number of participants');
      return;
    }

    if (amount == null || amount < 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (points == null || points < 0) {
      _showError('Please enter valid points');
      return;
    }

    final updates = {
      'participantCount': participantCount,
      'amountPaid': amount,
      'pointsEarned': points,
      'isMemberBooking': _isMemberBooking,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    Navigator.pop(context, updates);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

/// Dialog for changing participant status
class ChangeStatusDialog extends StatelessWidget {
  final BookingStatus currentStatus;

  const ChangeStatusDialog({Key? key, required this.currentStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current status: ${currentStatus.value.toUpperCase()}'),
          const SizedBox(height: 16),
          const Text('Select new status:'),
          const SizedBox(height: 12),
          ...BookingStatus.values.map((status) {
            return ListTile(
              title: Text(status.value.toUpperCase()),
              leading: Radio<BookingStatus>(
                value: status,
                groupValue: null,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context, value);
                  }
                },
              ),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
