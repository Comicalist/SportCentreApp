import 'package:flutter/material.dart';
import 'dart:async';
import '../models/booking.dart';
import '../models/activity.dart';
import '../services/booking_service.dart';
import '../providers/auth_provider.dart';

/// Provider for managing booking state and operations
class BookingProvider extends ChangeNotifier {
  // Current booking flow state
  BookingDetails? _currentBookingDetails;
  Activity? _selectedActivity;
  bool _isLoading = false;
  String? _errorMessage;
  
  // User bookings
  List<Booking> _userBookings = [];
  bool _bookingsLoading = false;
  StreamSubscription<List<Booking>>? _bookingsSubscription;
  
  // Booking confirmation
  Booking? _lastCreatedBooking;

  // Getters
  BookingDetails? get currentBookingDetails => _currentBookingDetails;
  Activity? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Booking> get userBookings => _userBookings;
  bool get bookingsLoading => _bookingsLoading;
  Booking? get lastCreatedBooking => _lastCreatedBooking;
  
  // Stream for user bookings
  Stream<List<Booking>> get userBookingsStream => 
      _userBookingsStreamController.stream;
  final StreamController<List<Booking>> _userBookingsStreamController = 
      StreamController<List<Booking>>.broadcast();
  
  // Check if user has an active booking flow
  bool get hasActiveBookingFlow => _currentBookingDetails != null;

  /// Start a new booking flow
  void startBooking(Activity activity, AuthProvider authProvider) {
    print('Starting booking for activity: ${activity.name}, user logged in: ${authProvider.isLoggedIn}');
    
    _selectedActivity = activity;
    
    // Initialize booking details with default values
    _currentBookingDetails = BookingDetails(
      activityId: activity.id,
      bookingDate: activity.date,
      participantCount: 1,
      isMemberBooking: authProvider.isLoggedIn,
      totalPrice: _calculatePrice(activity, authProvider.isLoggedIn, 1),
      expectedPoints: _calculatePoints(activity, authProvider.isLoggedIn, 1),
    );
    
    print('Booking details initialized: totalPrice=${_currentBookingDetails!.totalPrice}, expectedPoints=${_currentBookingDetails!.expectedPoints}');
    
    _clearError();
    notifyListeners();
  }

  /// Update booking details during the flow
  void updateBookingDetails({
    String? timeSlotId,
    DateTime? bookingDate,
    int? participantCount,
    bool? isMemberBooking,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (_currentBookingDetails == null || _selectedActivity == null) return;

    final newParticipantCount = participantCount ?? _currentBookingDetails!.participantCount;
    final newIsMemberBooking = isMemberBooking ?? _currentBookingDetails!.isMemberBooking;
    
    _currentBookingDetails = _currentBookingDetails!.copyWith(
      timeSlotId: timeSlotId,
      bookingDate: bookingDate,
      participantCount: newParticipantCount,
      isMemberBooking: newIsMemberBooking,
      totalPrice: _calculatePrice(_selectedActivity!, newIsMemberBooking, newParticipantCount),
      expectedPoints: _calculatePoints(_selectedActivity!, newIsMemberBooking, newParticipantCount),
      additionalInfo: additionalInfo,
    );
    
    notifyListeners();
  }

  /// Confirm and create the booking
  Future<bool> confirmBooking() async {
    if (_currentBookingDetails == null || _selectedActivity == null) {
      _setError('No booking details available');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Check availability first
      final isAvailable = await BookingService.checkAvailability(
        _currentBookingDetails!.activityId,
        _currentBookingDetails!.timeSlotId,
      );

      if (!isAvailable) {
        _setError('Sorry, this activity is no longer available');
        _setLoading(false);
        return false;
      }

      // Create the booking
      final booking = await BookingService.createBooking(
        activityId: _currentBookingDetails!.activityId,
        timeSlotId: _currentBookingDetails!.timeSlotId,
        bookingDate: _currentBookingDetails!.bookingDate,
        participantCount: _currentBookingDetails!.participantCount,
        isMemberBooking: _currentBookingDetails!.isMemberBooking,
        totalPrice: _currentBookingDetails!.totalPrice,
        expectedPoints: _currentBookingDetails!.expectedPoints,
        metadata: _currentBookingDetails!.additionalInfo,
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

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await BookingService.cancelBooking(bookingId, reason: reason);
      _setLoading(false);
      return success;
    } catch (e) {
      print('BookingProvider: Error cancelling booking: $e');
      _setError('Failed to cancel booking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Load user bookings
  Future<void> loadUserBookings(String userId) async {
    _setBookingsLoading(true);
    
    try {
      // Cancel existing subscription
      _bookingsSubscription?.cancel();
      
      // Listen to real-time updates
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

  /// Refresh user bookings
  Future<void> _refreshUserBookings() async {
    // This will be handled by the stream listener in loadUserBookings
    // But we can trigger a manual refresh if needed
  }

  /// Clear the current booking flow
  void clearBookingFlow() {
    _clearBookingFlow();
    notifyListeners();
  }

  void _clearBookingFlow() {
    _currentBookingDetails = null;
    _selectedActivity = null;
    _lastCreatedBooking = null;
  }

  /// Calculate price based on activity and user status
  double _calculatePrice(Activity activity, bool isMember, int participantCount) {
    return BookingService.calculatePrice(activity, isMember, participantCount);
  }

  /// Calculate points based on activity and user status
  int _calculatePoints(Activity activity, bool isMember, int participantCount) {
    final totalPrice = _calculatePrice(activity, isMember, participantCount);
    return BookingService.calculatePointsEarned(activity, totalPrice, isMember);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set bookings loading state
  void _setBookingsLoading(bool loading) {
    _bookingsLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get upcoming bookings
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _userBookings
        .where((booking) => 
            booking.bookingDate.isAfter(now) && 
            booking.isActive)
        .toList();
  }

  /// Get past bookings
  List<Booking> get pastBookings {
    final now = DateTime.now();
    return _userBookings
        .where((booking) => 
            booking.bookingDate.isBefore(now) || 
            booking.status == BookingStatus.completed)
        .toList();
  }

  /// Get cancelled bookings
  List<Booking> get cancelledBookings {
    return _userBookings
        .where((booking) => booking.status == BookingStatus.cancelled)
        .toList();
  }

  /// Check if user can book an activity (no conflicts)
  Future<bool> canBookActivity(DateTime startTime, DateTime endTime) async {
    // This would check for conflicting bookings
    // For now, return true - implement conflict checking later
    return true;
  }

  /// Get booking by ID
  Booking? getBookingById(String bookingId) {
    try {
      return _userBookings.firstWhere((booking) => booking.id == bookingId);
    } catch (e) {
      return null;
    }
  }

  /// Check if activity is fully booked
  Future<bool> isActivityAvailable(String activityId, String? timeSlotId) async {
    return await BookingService.checkAvailability(activityId, timeSlotId);
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _userBookingsStreamController.close();
    super.dispose();
  }
}