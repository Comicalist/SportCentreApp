import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/activity_helpers.dart';
import '../../utils/constants.dart';
import 'booking_confirmation_screen.dart';

/// Screen for booking activity details and participant selection
class BookingDetailsScreen extends StatefulWidget {
  final Activity activity;

  const BookingDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  int _participantCount = 1;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize booking flow when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.startBooking(widget.activity, authProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, authProvider, bookingProvider, child) {
        final isMember = authProvider.isLoggedIn;
        final currentPrice = isMember ? widget.activity.memberPrice : widget.activity.guestPrice;
        final totalPrice = currentPrice * _participantCount;
        final totalPoints = widget.activity.pointsReward * _participantCount;

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
                      _buildActivityCard(),
                      const SizedBox(height: AppConstants.largeSpacing),
                      _buildBookingDetails(isMember, currentPrice, totalPrice, totalPoints),
                      const SizedBox(height: AppConstants.largeSpacing),
                      _buildParticipantSelector(),
                      const SizedBox(height: AppConstants.largeSpacing),
                      _buildPricingBreakdown(isMember, currentPrice, totalPrice, totalPoints),
                      const SizedBox(height: AppConstants.largeSpacing),
                      _buildTermsAndConditions(),
                      const SizedBox(height: AppConstants.largeSpacing * 2),
                      _buildBookingButton(bookingProvider, totalPrice, totalPoints),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Build activity information card
  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppConstants.shadowOpacity),
            blurRadius: AppConstants.shadowBlurRadius,
            offset: AppConstants.shadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity header with gradient background
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
                  ActivityHelpers.getCategoryColor(widget.activity.category).withOpacity(0.8),
                  ActivityHelpers.getCategoryColor(widget.activity.category).withOpacity(0.6),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ActivityHelpers.getCategoryColor(widget.activity.category),
                      borderRadius: BorderRadius.circular(AppConstants.categoryBadgeRadius),
                    ),
                    child: Text(
                      widget.activity.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Activity icon
                Center(
                  child: Icon(
                    ActivityHelpers.getCategoryIcon(widget.activity.category),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Activity details
          Padding(
            padding: const EdgeInsets.all(AppConstants.largeSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.activity.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppConstants.mediumSpacing),
                Text(
                  widget.activity.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppConstants.largeSpacing),
                _buildActivityInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build activity information rows
  Widget _buildActivityInfo() {
    return Column(
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          'Date',
          DateFormat('EEEE, MMMM dd, yyyy').format(widget.activity.date),
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.access_time,
          'Time',
          widget.activity.time,
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.location_on,
          'Location',
          widget.activity.location,
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.groups,
          'Organized by',
          widget.activity.club,
        ),
        const SizedBox(height: AppConstants.mediumSpacing),
        _buildInfoRow(
          Icons.people,
          'Available spots',
          '${widget.activity.spotsLeft} of ${widget.activity.capacity}',
        ),
      ],
    );
  }

  /// Build information row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.teal,
        ),
        const SizedBox(width: AppConstants.mediumSpacing),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
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

  /// Build booking details section
  Widget _buildBookingDetails(bool isMember, double currentPrice, double totalPrice, int totalPoints) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppConstants.shadowOpacity),
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
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.teal,
                    size: 20,
                  ),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.mediumSpacing),
                  Expanded(
                    child: Text(
                      'Guest rate applied. Sign up to get member discounts!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
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

  /// Build participant count selector
  Widget _buildParticipantSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppConstants.shadowOpacity),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.largeSpacing),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _participantCount > 1 ? _decrementParticipants : null,
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
                      onPressed: _participantCount < widget.activity.spotsLeft 
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
          if (_participantCount >= widget.activity.spotsLeft) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Text(
              'Maximum ${widget.activity.spotsLeft} spots available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build pricing breakdown
  Widget _buildPricingBreakdown(bool isMember, double currentPrice, double totalPrice, int totalPoints) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppConstants.shadowOpacity),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$${currentPrice.toStringAsFixed(2)}',
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
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
          if (!isMember && widget.activity.memberPrice != widget.activity.guestPrice) ...[
            const SizedBox(height: AppConstants.mediumSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Member savings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[600],
                  ),
                ),
                Text(
                  '-\$${((widget.activity.guestPrice - widget.activity.memberPrice) * _participantCount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: AppConstants.mediumSpacing),
                Text(
                  'You\'ll earn $totalPoints points',
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

  /// Build terms and conditions checkbox
  Widget _buildTermsAndConditions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppConstants.shadowOpacity),
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
                          const TextSpan(
                            text: 'I agree to the ',
                          ),
                          TextSpan(
                            text: 'cancellation policy',
                            style: TextStyle(
                              color: Colors.teal[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ' and ',
                          ),
                          TextSpan(
                            text: 'terms of service',
                            style: TextStyle(
                              color: Colors.teal[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: '. Cancellations must be made 24 hours in advance for a full refund.',
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

  /// Build confirm booking button
  Widget _buildBookingButton(BookingProvider bookingProvider, double totalPrice, int totalPoints) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _agreeToTerms && !bookingProvider.isLoading 
            ? () => _confirmBooking(bookingProvider, totalPrice, totalPoints)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
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
                'Confirm Booking - \$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Increment participant count
  void _incrementParticipants() {
    if (_participantCount < widget.activity.spotsLeft) {
      setState(() {
        _participantCount++;
      });
      _updateBookingDetails();
    }
  }

  /// Decrement participant count
  void _decrementParticipants() {
    if (_participantCount > 1) {
      setState(() {
        _participantCount--;
      });
      _updateBookingDetails();
    }
  }

  /// Update booking details in provider
  void _updateBookingDetails() {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bookingProvider.updateBookingDetails(
      participantCount: _participantCount,
      isMemberBooking: authProvider.isLoggedIn,
    );
  }

  /// Confirm the booking
  Future<void> _confirmBooking(BookingProvider bookingProvider, double totalPrice, int totalPoints) async {
    setState(() {
      _isLoading = true;
    });

    // Update final booking details
    bookingProvider.updateBookingDetails(
      participantCount: _participantCount,
    );

    try {
      final success = await bookingProvider.confirmBooking();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Navigate to confirmation screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookingConfirmationScreen(
                activity: widget.activity,
              ),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookingProvider.errorMessage ?? 'Booking failed. Please try again.',
              ),
              backgroundColor: Colors.red,
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