import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking.dart';
import '../../models/activity.dart';

/// Screen for club owners to view and manage participants for a specific activity/event
class ActivityParticipantsScreen extends StatefulWidget {
  final Activity activity;

  const ActivityParticipantsScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityParticipantsScreen> createState() => _ActivityParticipantsScreenState();
}

class _ActivityParticipantsScreenState extends State<ActivityParticipantsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  BookingStatus? _filterStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Participants'),
            Text(
              widget.activity.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('activityId', isEqualTo: widget.activity.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data!.docs;
          
          // Calculate stats
          final total = allBookings.length;
          final confirmed = allBookings.where((b) => b['status'] == 'confirmed').length;
          final pending = allBookings.where((b) => b['status'] == 'pending').length;
          final cancelled = allBookings.where((b) => b['status'] == 'cancelled').length;
          final completed = allBookings.where((b) => b['status'] == 'completed').length;
          final waitlist = allBookings.where((b) => b['status'] == 'waitlist').length;

          // Calculate total participants (not just bookings) for confirmed bookings
          final totalConfirmedParticipants = allBookings
              .where((b) => b['status'] == 'confirmed')
              .fold<int>(0, (sum, booking) => sum + (booking['participantCount'] as int? ?? 1));

          // Apply filters
          var filteredBookings = allBookings;
          if (_filterStatus != null) {
            filteredBookings = allBookings.where((doc) => doc['status'] == _filterStatus!.value).toList();
          }

          return Column(
            children: [
              _buildStatsAndFiltersCard(total, confirmed, pending, cancelled, completed, waitlist, totalConfirmedParticipants),
              Expanded(child: _buildParticipantsListContent(filteredBookings)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsAndFiltersCard(int total, int confirmed, int pending, int cancelled, int completed, int waitlist, int totalConfirmedParticipants) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participant Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Capacity: ${widget.activity.capacity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Available: ${widget.activity.capacity - totalConfirmedParticipants}',
              style: TextStyle(
                color: widget.activity.capacity - totalConfirmedParticipants > 0 ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Clickable stat chips for filtering
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatFilterChip(
                  label: 'Total',
                  value: total,
                  color: Colors.blue,
                  isSelected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                _StatFilterChip(
                  label: 'Confirmed',
                  value: confirmed,
                  color: Colors.green,
                  isSelected: _filterStatus == BookingStatus.confirmed,
                  onTap: () => setState(() => _filterStatus = BookingStatus.confirmed),
                ),
                _StatFilterChip(
                  label: 'Pending',
                  value: pending,
                  color: Colors.orange,
                  isSelected: _filterStatus == BookingStatus.pending,
                  onTap: () => setState(() => _filterStatus = BookingStatus.pending),
                ),
                _StatFilterChip(
                  label: 'Cancelled',
                  value: cancelled,
                  color: Colors.red,
                  isSelected: _filterStatus == BookingStatus.cancelled,
                  onTap: () => setState(() => _filterStatus = BookingStatus.cancelled),
                ),
                _StatFilterChip(
                  label: 'Completed',
                  value: completed,
                  color: Colors.purple,
                  isSelected: _filterStatus == BookingStatus.completed,
                  onTap: () => setState(() => _filterStatus = BookingStatus.completed),
                ),
                _StatFilterChip(
                  label: 'Waitlist',
                  value: waitlist,
                  color: Colors.grey,
                  isSelected: _filterStatus == BookingStatus.waitlist,
                  onTap: () => setState(() => _filterStatus = BookingStatus.waitlist),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsListContent(List<QueryDocumentSnapshot> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No participants found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final bookingDoc = bookings[index];
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final userId = bookingData['userId'] as String?;

        if (userId == null) return const SizedBox.shrink();

        final status = BookingStatus.values.firstWhere(
          (s) => s.value == bookingData['status'],
          orElse: () => BookingStatus.pending,
        );
        final bookingDate = (bookingData['bookingDate'] as Timestamp?)?.toDate();
        final totalPrice = (bookingData['totalPrice'] ?? 0.0).toDouble();
        final participantCount = bookingData['participantCount'] as int? ?? 1;

        // Fetch user data from users collection in real-time
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            String userName = 'Loading...';
            String userEmail = '';

            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null) {
                // Prioritize displayName over name field
                userName = userData['displayName'] as String? ?? userData['name'] as String? ?? 'Unknown User';
                userEmail = userData['email'] as String? ?? '';
              }
            } else if (userSnapshot.connectionState == ConnectionState.done) {
              // User not found in database
              userName = 'Unknown User';
            }

            // Apply search filter
            if (_searchQuery.isNotEmpty && userSnapshot.connectionState == ConnectionState.done) {
              final searchLower = _searchQuery.toLowerCase();
              if (!userName.toLowerCase().contains(searchLower) &&
                  !userEmail.toLowerCase().contains(searchLower) &&
                  !bookingDoc.id.toLowerCase().contains(searchLower)) {
                return const SizedBox.shrink();
              }
            }

            return _ParticipantCard(
              bookingId: bookingDoc.id,
              userName: userName,
              userEmail: userEmail,
              status: status,
              bookingDate: bookingDate,
              totalPrice: totalPrice,
              participantCount: participantCount,
              confirmationNumber: bookingData['confirmationNumber'] ?? bookingDoc.id,
              onStatusChanged: (newStatus) => _updateBookingStatus(bookingDoc.id, newStatus),
              onDelete: () => _deleteBooking(bookingDoc.id),
            );
          },
        );
      },
    );
  }

  Future<void> _updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get booking data first to update activity capacity
        final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
        
        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data() as Map<String, dynamic>;
          final activityId = bookingData['activityId'] as String?;
          final participantCount = bookingData['participantCount'] as int? ?? 1;
          final status = bookingData['status'] as String?;
          
          // Delete the booking
          await _firestore.collection('bookings').doc(bookingId).delete();
          
          // If booking was confirmed, restore capacity
          if (status == 'confirmed' && activityId != null) {
            final activityRef = _firestore.collection('activities').doc(activityId);
            final activityDoc = await activityRef.get();
            
            if (activityDoc.exists) {
              final activityData = activityDoc.data() as Map<String, dynamic>;
              final currentBookedCount = activityData['bookedCount'] as int? ?? 0;
              final capacity = activityData['capacity'] as int? ?? 0;
              
              final newBookedCount = (currentBookedCount - participantCount).clamp(0, capacity);
              final newSpotsLeft = capacity - newBookedCount;
              
              await activityRef.update({
                'bookedCount': newBookedCount,
                'spotsLeft': newSpotsLeft,
              });
            }
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _StatFilterChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatFilterChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: isSelected ? color : color.withValues(alpha: 0.5),
          child: Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
        side: isSelected ? BorderSide(color: color, width: 2) : null,
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final String bookingId;
  final String userName;
  final String userEmail;
  final BookingStatus status;
  final DateTime? bookingDate;
  final double totalPrice;
  final int participantCount;
  final String confirmationNumber;
  final Function(BookingStatus) onStatusChanged;
  final VoidCallback onDelete;

  const _ParticipantCard({
    required this.bookingId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.bookingDate,
    required this.totalPrice,
    required this.participantCount,
    required this.confirmationNumber,
    required this.onStatusChanged,
    required this.onDelete,
  });

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
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.displayName.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.confirmation_number, label: 'Confirmation', value: confirmationNumber),
                _InfoRow(icon: Icons.people, label: 'Participants', value: participantCount.toString()),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Booked',
                  value: bookingDate != null
                      ? '${bookingDate!.day}/${bookingDate!.month}/${bookingDate!.year}'
                      : 'N/A',
                ),
                _InfoRow(icon: Icons.attach_money, label: 'Price', value: '\$${totalPrice.toStringAsFixed(2)}'),
                const Divider(height: 24),
                const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BookingStatus.values.map((s) {
                    final isCurrentStatus = s == status;
                    final statusColor = _getStatusColor(s);
                    
                    return GestureDetector(
                      onTap: isCurrentStatus ? null : () => onStatusChanged(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrentStatus ? statusColor : Colors.white,
                          border: Border.all(
                            color: statusColor,
                            width: isCurrentStatus ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCurrentStatus) ...[
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              s.displayName,
                              style: TextStyle(
                                color: isCurrentStatus ? Colors.white : statusColor,
                                fontSize: 12,
                                fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
