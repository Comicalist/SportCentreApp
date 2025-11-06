import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/booking.dart';
import '../models/voucher.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';

/// Central booking state management with voucher integration and real-time updates
/// 
/// Manages the complete booking lifecycle: activity selection → configuration → 
/// confirmation → tracking. Handles voucher discounts, points calculations, and
/// maintains real-time synchronization with user's booking history.
class BookingProvider extends ChangeNotifier {
  // Booking flow state (temporary during booking process)
  BookingDetails? _currentBookingDetails; // Current booking being configured
  Activity? _selectedActivity; // Activity being booked
  bool _isLoading = false;
  String? _errorMessage;

  // User's booking history (persistent data)
  List<Booking> _userBookings = [];
  bool _bookingsLoading = false;
  StreamSubscription<List<Booking>>? _bookingsSubscription; // Real-time updates

  // Booking completion tracking
  Booking? _lastCreatedBooking; // For success screen display

  // Voucher system integration
  Voucher? _selectedVoucher; // Currently selected voucher for discount

  // State accessors
  BookingDetails? get currentBookingDetails => _currentBookingDetails;
  Activity? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Booking> get userBookings => _userBookings;
  bool get bookingsLoading => _bookingsLoading;
  Booking? get lastCreatedBooking => _lastCreatedBooking;
  Voucher? get selectedVoucher => _selectedVoucher;

  // Real-time booking stream for UI consumption
  Stream<List<Booking>> get userBookingsStream =>
      _userBookingsStreamController.stream;
  final StreamController<List<Booking>> _userBookingsStreamController =
      StreamController<List<Booking>>.broadcast();

  /// Check if user is currently in booking process
  bool get hasActiveBookingFlow => _currentBookingDetails != null;

  /// Initialize new booking flow with activity selection
  void startBooking(Activity activity, AuthProvider authProvider) {
    // Clear previous booking result for clean state
    _lastCreatedBooking = null;
    _selectedActivity = activity;

    // Initialize booking configuration with default values
    _currentBookingDetails = BookingDetails(
      activityId: activity.id,
      bookingDate: activity.date,
      participantCount: 1,
      isMemberBooking: authProvider.isLoggedIn,
      totalPrice: _calculatePrice(activity, authProvider.isLoggedIn, 1),
      expectedPoints: _calculatePoints(activity, authProvider.isLoggedIn, 1),
    );

    _clearError();
    notifyListeners();
  }

  /// Update booking configuration during the flow (participant count, dates, etc.)
  void updateBookingDetails({
    String? timeSlotId,
    DateTime? bookingDate,
    int? participantCount,
    bool? isMemberBooking,
    Map<String, dynamic>? additionalInfo,
    String? voucherId,
  }) {
    if (_currentBookingDetails == null || _selectedActivity == null) return;

    final newParticipantCount =
        participantCount ?? _currentBookingDetails!.participantCount;
    final newIsMemberBooking =
        isMemberBooking ?? _currentBookingDetails!.isMemberBooking;

    // Store voucher ID for later processing
    if (voucherId != null) {
      // Voucher details fetched separately via setSelectedVoucher
    }

    _currentBookingDetails = _currentBookingDetails!.copyWith(
      timeSlotId: timeSlotId,
      bookingDate: bookingDate,
      participantCount: newParticipantCount,
      isMemberBooking: newIsMemberBooking,
      totalPrice: _calculatePrice(
        _selectedActivity!,
        newIsMemberBooking,
        newParticipantCount,
      ),
      expectedPoints: _calculatePoints(
        _selectedActivity!,
        newIsMemberBooking,
        newParticipantCount,
      ),
      additionalInfo: additionalInfo,
      voucherId: voucherId,
    );

    notifyListeners();
  }

  /// Apply voucher discount and recalculate pricing/points
  void setSelectedVoucher(Voucher? voucher) {
    _selectedVoucher = voucher;

    // Recalculate booking details with voucher discount applied
    if (_currentBookingDetails != null && _selectedActivity != null) {
      final originalPrice = _currentBookingDetails!.totalPrice;
      final voucherDiscount = voucher?.amount ?? 0.0;
      final finalPrice = (originalPrice - voucherDiscount).clamp(
        0.0,
        originalPrice,
      );

      // Points earned only on amount actually paid (after voucher)
      final adjustedPoints = _calculatePointsForAmount(
        _selectedActivity!,
        finalPrice,
        _currentBookingDetails!.isMemberBooking,
      );

      _currentBookingDetails = _currentBookingDetails!.copyWith(
        voucherId: voucher?.id,
        expectedPoints: adjustedPoints,
      );
    }

    notifyListeners();
  }

  /// Finalize booking creation with availability check and transaction processing
  Future<bool> confirmBooking() async {
    if (_currentBookingDetails == null || _selectedActivity == null) {
      _setError('No booking details available');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Prevent double-booking by checking current availability
      final isAvailable = await BookingService.checkAvailability(
        _currentBookingDetails!.activityId,
        _currentBookingDetails!.timeSlotId,
      );

      if (!isAvailable) {
        _setError('Sorry, this activity is no longer available');
        _setLoading(false);
        return false;
      }

      // Process booking with voucher integration
      final booking = await BookingService.createBooking(
        activityId: _currentBookingDetails!.activityId,
        timeSlotId: _currentBookingDetails!.timeSlotId,
        bookingDate: _currentBookingDetails!.bookingDate,
        participantCount: _currentBookingDetails!.participantCount,
        isMemberBooking: _currentBookingDetails!.isMemberBooking,
        totalPrice: _currentBookingDetails!.totalPrice,
        expectedPoints: _currentBookingDetails!.expectedPoints,
        metadata: _currentBookingDetails!.additionalInfo,
        voucherId: _currentBookingDetails!.voucherId, 
      );

      if (booking != null) {
        _lastCreatedBooking = booking;
        _clearBookingFlow();
        await _refreshUserBookings();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create booking. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Booking failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Cancel existing booking with optional reason
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await BookingService.cancelBooking(
        bookingId,
        reason: reason,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to cancel booking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Establish real-time connection to user's booking history
  Future<void> loadUserBookings(String userId) async {
    _setBookingsLoading(true);

    try {
      // Clean up previous subscription to prevent memory leaks
      await _bookingsSubscription?.cancel();

      // Subscribe to real-time booking updates from Firestore
      _bookingsSubscription = BookingService.getUserBookings(userId).listen(
        (bookings) {
          _userBookings = bookings;
          _userBookingsStreamController.add(_userBookings);
          _setBookingsLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load bookings: $error');
          _setBookingsLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load bookings: $e');
      _setBookingsLoading(false);
    }
  }

  /// Trigger manual refresh of booking data (handled by stream listener)
  Future<void> _refreshUserBookings() async {
    // Real-time updates handled automatically by stream subscription
  }

  /// Clear current booking flow state
  void clearBookingFlow() {
    _clearBookingFlow();
    notifyListeners();
  }

  /// Clear booking success result (for navigating away from success screen)
  void clearLastCreatedBooking() {
    _lastCreatedBooking = null;
    notifyListeners();
  }

  /// Internal flow state cleanup
  void _clearBookingFlow() {
    _currentBookingDetails = null;
    _selectedActivity = null;
    // Preserve _lastCreatedBooking for success screen display
  }

  /// Calculate total price based on member status and participant count
  double _calculatePrice(
    Activity activity,
    bool isMember,
    int participantCount,
  ) {
    return BookingService.calculatePrice(activity, isMember, participantCount);
  }

  /// Calculate expected points based on full price (before voucher discount)
  int _calculatePoints(Activity activity, bool isMember, int participantCount) {
    final totalPrice = _calculatePrice(activity, isMember, participantCount);
    return BookingService.calculatePointsEarned(activity, totalPrice, isMember);
  }

  /// Calculate points earned on specific amount (used for voucher-discounted bookings)
  /// Points only awarded on amount actually paid, not original price
  int _calculatePointsForAmount(
    Activity activity,
    double finalAmount,
    bool isMember,
  ) {
    var basePoints = finalAmount.floor();

    if (isMember) {
      basePoints = (basePoints * 1.5).floor();
    }

    // Activity category bonuses
    switch (activity.category.toLowerCase()) {
      case 'wellness':
        basePoints = (basePoints * 1.2).floor();
        break;
      case 'workshops':
        basePoints = (basePoints * 1.3).floor();
        break;
      default:
        break;
    }

    return basePoints;
  }

  /// Update main loading state and notify UI
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Update bookings loading state for UI indicators
  void _setBookingsLoading(bool loading) {
    _bookingsLoading = loading;
    notifyListeners();
  }

  /// Set error message and notify UI for display
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Public error clearing method
  void clearError() {
    _clearError();
  }

  /// Internal error state cleanup
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Filter user bookings for future activities
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _userBookings
        .where(
          (booking) => booking.bookingDate.isAfter(now) && booking.isActive,
        )
        .toList();
  }

  /// Filter user bookings for past or completed activities
  List<Booking> get pastBookings {
    final now = DateTime.now();
    return _userBookings
        .where(
          (booking) =>
              booking.bookingDate.isBefore(now) ||
              booking.status == BookingStatus.completed,
        )
        .toList();
  }

  /// Filter user bookings for cancelled activities
  List<Booking> get cancelledBookings {
    return _userBookings
        .where((booking) => booking.status == BookingStatus.cancelled)
        .toList();
  }

  /// Check for booking time conflicts (placeholder for future implementation)
  Future<bool> canBookActivity(DateTime startTime, DateTime endTime) async {
  return true;
  }

  /// Find specific booking by ID in user's history
  Booking? getBookingById(String bookingId) {
    try {
      return _userBookings.firstWhere((booking) => booking.id == bookingId);
    } catch (e) {
      return null;
    }
  }

  /// Check real-time activity availability before booking
  Future<bool> isActivityAvailable(
    String activityId,
    String? timeSlotId,
  ) async {
    return BookingService.checkAvailability(activityId, timeSlotId);
  }

  /// Clean up resources and subscriptions
  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _userBookingsStreamController.close();
    super.dispose();
  }
}
