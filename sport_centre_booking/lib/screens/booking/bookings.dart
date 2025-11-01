import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // date/time formatting
import 'package:table_calendar/table_calendar.dart'; // calendar widget
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notifications/notifications_drawer.dart';
import '../../utils/colors.dart';
import '../../screens/auth/login_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  // ---- Filters (original feature) ----
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Confirmed', 'Completed', 'Cancelled'];

  // ---- Calendar state (required by TableCalendar) ----
  DateTime _focusedDay = DateTime.now(); // must be non-null
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Load user bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.appUser != null) {
        Provider.of<BookingProvider>(context, listen: false)
            .loadUserBookings(authProvider.firebaseUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If not logged in, show a sign-in prompt
        if (!authProvider.isLoggedIn) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('My Bookings'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to view your bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to view and manage your activities.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(isSignUp: false),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        // Logged-in view: calendar + filters + list
        final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'My Bookings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (userId != null)
                // Bell icon with badge
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
          body: Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- 📅 Calendar (identical behavior) ----
                    _buildCalendarSection(bookingProvider),
                    const SizedBox(height: 24),

                    // ---- Filter chips (original feature) ----
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: selectedFilter == filter,
                              onSelected: (_) => setState(() => selectedFilter = filter),
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---- Bookings list (with safe date handling) ----
                    StreamBuilder<List<Booking>>(
                      stream: bookingProvider.userBookingsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading bookings: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final allBookings = snapshot.data ?? [];
                        final filteredBookings = _filterBookings(allBookings);

                        if (filteredBookings.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    selectedFilter == 'All'
                                        ? 'No bookings yet'
                                        : 'No ${selectedFilter.toLowerCase()} bookings',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start booking activities to see them here',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================================
  // Calendar helpers (identical logic + safe date conversion)
  // ============================================================================

  // Normalize a DateTime to midnight
  DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  // Safely converts dynamic (DateTime or Firestore Timestamp) to DateTime
  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      final toDate = (v as dynamic).toDate;
      if (toDate is Function) return toDate() as DateTime;
    } catch (_) {}
    return null;
  }

  // Extractors that try multiple possible fields from your Booking model
  DateTime? _getStartDate(Booking b) {
    try {
      final v1 = (b as dynamic).activityDate;
      final dt1 = _asDateTime(v1);
      if (dt1 != null) return dt1;
    } catch (_) {}
    try {
      final v2 = (b as dynamic).startDate;
      final dt2 = _asDateTime(v2);
      if (dt2 != null) return dt2;
    } catch (_) {}
    return null;
  }

  DateTime? _getEndDate(Booking b) {
    try {
      final v1 = (b as dynamic).activityEndDate;
      final dt1 = _asDateTime(v1);
      if (dt1 != null) return dt1;
    } catch (_) {}
    try {
      final v2 = (b as dynamic).endDate;
      final dt2 = _asDateTime(v2);
      if (dt2 != null) return dt2;
    } catch (_) {}
    return null;
  }

  int? _getDurationMinutes(Booking b) {
    try {
      return (b as dynamic).durationMinutes as int?;
    } catch (_) {
      return null;
    }
  }

  /// Formats as "HH:mm – HH:mm" if end exists,
  /// else "HH:mm • X min" if only duration exists,
  /// else "HH:mm", else "Time TBA".
  String _formatTimeRange(Booking b) {
    final start = _getStartDate(b);
    if (start == null) return 'Time TBA';

    final end = _getEndDate(b);
    final dur = _getDurationMinutes(b);

    final s = DateFormat('HH:mm').format(start);
    if (end != null) {
      final e = DateFormat('HH:mm').format(end);
      return '$s – $e';
    }
    if (dur != null) return '$s • ${dur} min';
    return s;
  }

  /// Calendar card: same behavior as the working page
  Widget _buildCalendarSection(BookingProvider bookingProvider) {
    // Fallback to an immediate empty stream if provider hasn't set one yet
    final Stream<List<Booking>> safeStream =
        bookingProvider.userBookingsStream ?? Stream.value(const <Booking>[]);

    return StreamBuilder<List<Booking>>(
      stream: safeStream,
      initialData: const <Booking>[],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyCalendar(message: 'Failed to load bookings.');
        }

        final bookings = snapshot.data ?? const <Booking>[];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        // Map day -> list of bookings (skip rows without valid date)
        final Map<DateTime, List<Booking>> byDay = {};
        for (final b in bookings) {
          final start = _getStartDate(b);
          if (start == null) continue;
          final key = _atMidnight(start);
          byDay.putIfAbsent(key, () => []).add(b);
        }

        // Default selection: today if available, else first day with bookings, else today
        _selectedDay ??= () {
          final todayKey = _atMidnight(DateTime.now());
          if (byDay.containsKey(todayKey)) return todayKey;
          if (byDay.isNotEmpty) {
            final keys = byDay.keys.toList()..sort();
            return keys.first;
          }
          return todayKey;
        }();

        final selectedBookings = byDay[_selectedDay!] ?? const <Booking>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Bookings Calendar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // --- Calendar ---
              TableCalendar<Booking>(
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = _atMidnight(selected);
                    _focusedDay = focused;
                  });
                },
                // Return the list of bookings for that day
                eventLoader: (day) => byDay[_atMidnight(day)] ?? const <Booking>[],
              ),

              const SizedBox(height: 12),

              // --- States / messages ---
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                )
              else if (bookings.isEmpty) ...[
                const Text('No bookings yet.', style: TextStyle(color: Colors.grey)),
              ] else ...[
                // Selected day title
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Selected day bookings list
                if (selectedBookings.isEmpty)
                  const Text('No bookings this day.', style: TextStyle(color: Colors.grey))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedBookings.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final b = selectedBookings[i];

                      // Optional fields depending on your Booking model
                      String title = 'Booking';
                      String? place;
                      try {
                        title = (b as dynamic).activityName as String? ?? title;
                      } catch (_) {}
                      try {
                        place = (b as dynamic).facilityName as String?;
                      } catch (_) {}

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.event)),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeRange(b),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (place != null) ...[
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.teal),
                                    const SizedBox(width: 6),
                                    Text(place!),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Minimal empty calendar used for errors or no data
  Widget _buildEmptyCalendar({String? message}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings Calendar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            eventLoader: (_) => const [],
          ),
          const SizedBox(height: 8),
          Text(message ?? 'No bookings yet.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ============================================================================
  // Existing list UI & actions (with safe date usage)
  // ============================================================================

  Widget _buildBookingCard(Booking booking) {
    // Safely derive date + time for the card
    final startForList = _getStartDate(booking);
    final dateLabel = startForList != null ? _formatDate(startForList) : 'Date TBA';
    // If activityTime is missing, reuse computed time range as a fallback
    String? activityTime;
    try {
      activityTime = (booking as dynamic).activityTime as String?;
    } catch (_) {}
    final timeLabel =
        (activityTime == null || activityTime.isEmpty) ? _formatTimeRange(booking) : activityTime;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Title + date/time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.activityTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateLabel • $timeLabel',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${booking.participantCount} participant${booking.participantCount > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            // Points for completed bookings
            if (booking.pointsEarned > 0 && booking.status == BookingStatus.completed) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.star, size: 16, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    '+ points earned',
                    style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            // Actions for confirmed bookings
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showBookingDetails(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Temporary testing button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeBooking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Complete Booking (+${booking.pointsEarned} pts)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        text = 'Pending';
        break;
      case BookingStatus.confirmed:
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        text = 'Confirmed';
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        text = 'Cancelled';
        break;
      case BookingStatus.waitlist:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        text = 'Waitlist';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (selectedFilter == 'All') return bookings;
    final status = BookingStatus.values.firstWhere(
      (s) => s.toString().split('.').last.toLowerCase() == selectedFilter.toLowerCase(),
    );
    return bookings.where((booking) => booking.status == status).toList();
  }

  void _showBookingDetails(Booking booking) {
    final start = _getStartDate(booking);
    final startLabel = start != null ? _formatDate(start) : 'TBA';

    String? activityTime;
    try {
      activityTime = (booking as dynamic).activityTime as String?;
    } catch (_) {}
    final timeLabel =
        (activityTime == null || activityTime.isEmpty) ? _formatTimeRange(booking) : activityTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.activityTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $startLabel'),
            Text('Time: $timeLabel'),
            Text('Participants: ${booking.participantCount}'),
            Text('Total Price: \$${booking.totalPrice.toStringAsFixed(2)}'),
            if (booking.pointsEarned > 0) Text('Points Earned: ${booking.pointsEarned}'),
            const SizedBox(height: 8),
            Text('Booking ID: ${booking.id}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _completeBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Booking'),
        content: Text(
            'Mark "${booking.activityTitle}" as completed and credit ${booking.pointsEarned} points?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final success = await BookingService.completeBooking(booking.id);
                if (!mounted) return;
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Booking completed! ${booking.pointsEarned} points credited'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to complete booking. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (!mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Complete & Credit Points'),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
            'Are you sure you want to cancel your booking for "${booking.activityTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keep Booking')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final success = await Provider.of<BookingProvider>(context, listen: false)
                    .cancelBooking(booking.id);
                if (!mounted) return;
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to cancel booking. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (!mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  // Format a DateTime for list cards
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
