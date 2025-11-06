import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/activity.dart';
import '../../models/booking.dart';
import '../../models/voucher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/activity_service.dart';
import '../../services/booking_service.dart';
import '../../services/voucher_service.dart';
import '../../utils/activity_helpers.dart';
import '../../utils/constants.dart';
import 'booking_success_screen.dart';

/// Comprehensive booking screen with participant selection, voucher application,
/// calendar view of existing bookings, and pricing breakdown
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  int _participantCount = 1;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();

  /// Voucher system state for discount application
  Voucher? _selectedVoucher;
  List<Voucher> _availableVouchers = [];
  
  /// Current activity data from stream for real-time updates
  Activity? _currentActivity;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity; // Initialize with passed activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      )..startBooking(widget.activity, authProvider);

      final uid = authProvider.firebaseUser?.uid;
      if (uid != null) {
        bookingProvider.loadUserBookings(uid);
        _loadAvailableVouchers(uid);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh vouchers when screen becomes active again
    final uid = Provider.of<AuthProvider>(context, listen: false)
        .firebaseUser
        ?.uid;
    if (uid != null && widget.activity.allowVouchers) {
      _loadAvailableVouchers(uid);
    }
  }

  /// Loads user's available vouchers for this club and activity type
  /// Filters out used vouchers by querying fresh data from Firestore
  Future<void> _loadAvailableVouchers(String userId) async {
    if (!widget.activity.allowVouchers) return;

    try {
      final vouchers = await VoucherService.getUsableVouchers(
        userId,
        widget.activity.clubId,
      );
      if (mounted) {
        setState(() {
          _availableVouchers = vouchers;
          // Reset selected voucher if it's no longer available (was used)
          if (_selectedVoucher != null &&
              !vouchers.any((v) => v.id == _selectedVoucher!.id)) {
            _selectedVoucher = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vouchers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Activity?>(
      stream: ActivityService.getActivityStream(widget.activity.id),
      initialData: widget.activity,
      builder: (context, activitySnapshot) {
        // Use the real-time activity data or fall back to initial activity
        final currentActivity = activitySnapshot.data ?? widget.activity;
        
        // Update state with current activity for use in other methods
        if (activitySnapshot.hasData && activitySnapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentActivity?.spotsLeft != currentActivity.spotsLeft) {
              setState(() {
                _currentActivity = currentActivity;
                // Adjust participant count if it exceeds new available spots
                if (_participantCount > currentActivity.spotsLeft) {
                  _participantCount = currentActivity.spotsLeft.clamp(1, _participantCount);
                }
              });
            }
          });
        }
        
        return Consumer2<AuthProvider, BookingProvider>(
          builder: (context, authProvider, bookingProvider, child) {
            final isMember = authProvider.isLoggedIn;
            final currentPrice = isMember
                ? currentActivity.memberPrice
                : currentActivity.guestPrice;
            final totalPrice = currentPrice * _participantCount;

            /// Voucher discount calculation with price floor protection
            final voucherDiscount = _selectedVoucher?.amount ?? 0.0;
            final finalPrice = (totalPrice - voucherDiscount).clamp(
              0.0,
              totalPrice,
            );

            /// Points calculation using the corrected BookingService method
            final expectedPoints = BookingService.calculatePointsEarned(
              currentActivity,
              finalPrice,
              isMember,
            );

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                title: const Text('Booking Details'),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActivityCard(currentActivity),
                          const SizedBox(height: AppConstants.largeSpacing),
                          _buildBookingDetails(isMember, currentPrice, totalPrice),
                          const SizedBox(height: AppConstants.largeSpacing),
                          _buildParticipantSelector(currentActivity),
                          const SizedBox(height: AppConstants.largeSpacing),
                          if (_availableVouchers.isNotEmpty &&
                              currentActivity.allowVouchers) ...[
                            _buildVoucherSection(),
                            const SizedBox(height: AppConstants.largeSpacing),
                          ],
                          _buildPricingBreakdown(
                            isMember,
                            currentPrice,
                            totalPrice,
                            finalPrice,
                            voucherDiscount,
                            expectedPoints,
                          ),
                          const SizedBox(height: AppConstants.largeSpacing),
                          _buildCalendarSection(bookingProvider),
                          const SizedBox(height: AppConstants.largeSpacing),
                          _buildTermsAndConditions(),
                          const SizedBox(height: AppConstants.largeSpacing * 2),
                          _buildBookingButton(bookingProvider, finalPrice, currentActivity),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  /// Normalizes dates to midnight for consistent calendar comparison
  DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _selectedDay;

  /// Formats booking time display with end time or duration when available
  String _formatTimeRange(Booking b) {
    final start = b.activityDate;
    DateTime? end;
    int? dur;

    try {
      end = (b as dynamic).activityEndDate as DateTime?;
    } catch (_) {}
    try {
      end ??= (b as dynamic).endDate as DateTime?;
    } catch (_) {}
    try {
      dur = (b as dynamic).durationMinutes as int?;
    } catch (_) {}

    final s = DateFormat('HH:mm').format(start);
    if (end != null) {
      final e = DateFormat('HH:mm').format(end);
      return '$s – $e';
    }
    if (dur != null) return '$s • $dur min';
    return s;
  }

  /// Interactive calendar showing user's existing bookings to avoid scheduling conflicts
  Widget _buildCalendarSection(BookingProvider bookingProvider) {
    return StreamBuilder<List<Booking>>(
      stream: bookingProvider.userBookingsStream,
      initialData: const <Booking>[],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyCalendar(message: 'Failed to load bookings.');
        }

        final bookings = snapshot.data ?? const <Booking>[];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        /// Group bookings by day for calendar display
        final byDay = <DateTime, List<Booking>>{};
        for (final b in bookings) {
          final key = _atMidnight(b.activityDate);
          byDay.putIfAbsent(key, () => []).add(b);
        }

        /// Default to today if has bookings, otherwise first booking day
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
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppConstants.largeSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Bookings Calendar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              /// Interactive calendar with booking indicators
              TableCalendar<Booking>(
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.3),
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
                eventLoader: (day) =>
                    byDay[_atMidnight(day)] ?? const <Booking>[],
              ),

              const SizedBox(height: 12),

              /// Loading state or booking list display
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                )
              else if (bookings.isEmpty) ...[
                const Text(
                  'No bookings yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                /// Daily booking list for selected day
                if (selectedBookings.isEmpty)
                  const Text(
                    'No bookings this day.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedBookings.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final b = selectedBookings[i];

                      var title = 'Booking';
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
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeRange(b),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (place != null) ...[
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(place),
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

  /// Fallback calendar display when bookings fail to load
  Widget _buildEmptyCalendar({String? message}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (_) => const [],
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'No bookings yet.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Displays activity details with gradient header and comprehensive information
  Widget _buildActivityCard(Activity activity) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Category-themed gradient header with activity icon
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.cardBorderRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ActivityHelpers.getCategoryColor(
                    activity.category,
                  ).withValues(alpha: 0.8),
                  ActivityHelpers.getCategoryColor(
                    activity.category,
                  ).withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ActivityHelpers.getCategoryColor(
                        activity.category,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppConstants.categoryBadgeRadius,
                      ),
                    ),
                    child: Text(
                      activity.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    ActivityHelpers.getCategoryIcon(activity.category),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.largeSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppConstants.mediumSpacing),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppConstants.largeSpacing),
                _buildActivityInfo(activity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays essential activity information in structured rows
  Widget _buildActivityInfo(Activity activity) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          'Date',
          DateFormat('EEEE, MMMM dd, yyyy').format(activity.date),
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.access_time,
          'Time',
          '${activity.time} - ${activity.endTimeFormatted} (${activity.duration} min)',
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.location_on,
          'Location',
          activity.facilityName,
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(Icons.groups, 'Organized by', activity.clubName),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.people,
          'Available spots',
          '${activity.spotsLeft} of ${activity.capacity}',
        ),
        if (activity.requirements.isNotEmpty) ...[
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildRequirementsSection(),
        ],
      ],
    );
  }

  /// Reusable information row component for activity details
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: AppConstants.mediumSpacing),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Displays activity requirements as bulleted list when present
  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Colors.teal),
            const SizedBox(width: AppConstants.mediumSpacing),
            Text(
              'Requirements',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.activity.requirements.map((requirement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        requirement,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Shows member benefits or prompts guest signup with pricing context
  Widget _buildBookingDetails(
    bool isMember,
    double currentPrice,
    double totalPrice,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppConstants.largeSpacing),
          if (isMember) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.filterBorderRadius,
                ),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.teal, size: 20),
                  const SizedBox(width: AppConstants.mediumSpacing),
                  Expanded(
                    child: Text(
                      'Member Benefits Applied',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.filterBorderRadius,
                ),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: AppConstants.mediumSpacing),
                  Expanded(
                    child: Text(
                      'Guest rate applied. Sign up to get member discounts!',
                      style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Interactive participant count selector with capacity limits
  Widget _buildParticipantSelector(Activity activity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Number of Participants',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppConstants.largeSpacing),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select how many people will participate',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: AppConstants.largeSpacing),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonBorderRadius,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _participantCount > 1
                          ? _decrementParticipants
                          : null,
                      icon: const Icon(Icons.remove),
                      color: Colors.teal,
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '$_participantCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _participantCount < activity.spotsLeft
                          ? _incrementParticipants
                          : null,
                      icon: const Icon(Icons.add),
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_participantCount >= activity.spotsLeft) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Text(
              'Maximum ${activity.spotsLeft} spots available',
              style: TextStyle(fontSize: 14, color: Colors.orange[700]),
            ),
          ],
        ],
      ),
    );
  }

  /// Voucher selection interface with discount preview and points impact warning
  Widget _buildVoucherSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply Voucher',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Text(
            'You have ${_availableVouchers.length} voucher(s) available for this activity',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: AppConstants.largeSpacing),

          /// Individual voucher selection cards
          ...List.generate(_availableVouchers.length, (index) {
            final voucher = _availableVouchers[index];
            final isSelected = _selectedVoucher?.id == voucher.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedVoucher = isSelected ? null : voucher;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.teal.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.teal
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.teal : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.teal : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getVoucherTypeColor(
                            voucher.type,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          voucher.type == VoucherType.fitness
                              ? 'FITNESS'
                              : 'STUFF',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _getVoucherTypeColor(voucher.type),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              voucher.clubName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${voucher.amount.toStringAsFixed(2)} CHF',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          /// Points impact warning for voucher usage
          if (_selectedVoucher != null) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voucher savings will reduce points earned. You\'ll earn points only on the amount you pay.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_selectedVoucher != null) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVoucher = null;
                });
              },
              child: const Text('Remove voucher'),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns theme color for voucher type badges
  Color _getVoucherTypeColor(VoucherType type) {
    switch (type) {
      case VoucherType.fitness:
        return Colors.teal;
      case VoucherType.stuff:
        return Colors.purple;
    }
  }

  /// Comprehensive pricing breakdown showing all fees, discounts, and point earnings
  Widget _buildPricingBreakdown(
    bool isMember,
    double currentPrice,
    double totalPrice,
    double finalPrice,
    double voucherDiscount,
    int expectedPoints,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppConstants.largeSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMember ? 'Member price per person' : 'Guest price per person',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                '${currentPrice.toStringAsFixed(2)} CHF',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                '$_participantCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          /// Member savings display for guest users
          if (!isMember &&
              widget.activity.memberPrice != widget.activity.guestPrice) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Member savings',
                  style: TextStyle(fontSize: 14, color: Colors.orange[600]),
                ),
                Text(
                  '-${((widget.activity.guestPrice - widget.activity.memberPrice) * _participantCount).toStringAsFixed(2)} CHF',
                  style: TextStyle(fontSize: 14, color: Colors.orange[600]),
                ),
              ],
            ),
          ],

          /// Voucher discount line item
          if (voucherDiscount > 0) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Voucher discount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${voucherDiscount.toStringAsFixed(2)} CHF',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 32),

          /// Subtotal with strikethrough when voucher applied
          if (voucherDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(2)} CHF',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          /// Final total amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                voucherDiscount > 0 ? 'Final Total' : 'Total',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${finalPrice.toStringAsFixed(2)} CHF',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          
          /// Points earning preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.filterBorderRadius,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.orange[700], size: 20),
                const SizedBox(width: AppConstants.mediumSpacing),
                Text(
                  'You\'ll earn $expectedPoints points',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Terms and conditions acceptance with cancellation policy
  Widget _buildTermsAndConditions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppConstants.largeSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: Colors.teal,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreeToTerms = !_agreeToTerms;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'cancellation policy',
                            style: TextStyle(
                              color: Colors.teal[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'terms of service',
                            style: TextStyle(
                              color: Colors.teal[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '. Cancellations must be made 24 hours in advance for a full refund.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Final booking confirmation button with price display
  Widget _buildBookingButton(
    BookingProvider bookingProvider,
    double totalPrice,
    Activity activity,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _agreeToTerms && !bookingProvider.isLoading
            ? () => _confirmBooking(bookingProvider, totalPrice)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.buttonBorderRadius,
            ),
          ),
          elevation: 2,
        ),
        child: bookingProvider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Confirm Booking - ${totalPrice.toStringAsFixed(2)} CHF',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Increases participant count within capacity limits
  void _incrementParticipants() {
    final spotsLeft = _currentActivity?.spotsLeft ?? widget.activity.spotsLeft;
    if (_participantCount < spotsLeft) {
      setState(() {
        _participantCount++;
      });
      _updateBookingDetails();
    }
  }

  /// Decreases participant count with minimum of 1
  void _decrementParticipants() {
    if (_participantCount > 1) {
      setState(() {
        _participantCount--;
      });
      _updateBookingDetails();
    }
  }

  /// Updates booking provider with current participant selection
  void _updateBookingDetails() {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bookingProvider.updateBookingDetails(
      participantCount: _participantCount,
      isMemberBooking: authProvider.isLoggedIn,
    );
  }

  /// Processes final booking with voucher application and error handling
  Future<void> _confirmBooking(
    BookingProvider bookingProvider,
    double totalPrice,
  ) async {
    setState(() {
      _isLoading = true;
    });

    /// Apply voucher selection to booking details
    bookingProvider
      ..updateBookingDetails(
        participantCount: _participantCount,
        voucherId: _selectedVoucher?.id,
      )
      ..setSelectedVoucher(_selectedVoucher);

    try {
      final success = await bookingProvider.confirmBooking();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success && bookingProvider.lastCreatedBooking != null) {
          unawaited(
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookingSuccessScreen(
                  activity: widget.activity,
                  booking: bookingProvider.lastCreatedBooking!,
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Booking was created but details are unavailable. Please check My Bookings.'
                    : (bookingProvider.errorMessage ??
                          'Booking failed. Please try again.'),
              ),
              backgroundColor: success ? Colors.orange : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
