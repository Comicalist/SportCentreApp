import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'booking_success_screen.dart';

/// Final booking confirmation screen displaying activity details, pricing breakdown,
/// and payment terms before confirming the reservation
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          final bookingDetails = bookingProvider.currentBookingDetails;

          if (bookingDetails == null) {
            return const Center(child: Text('No booking details found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationHeader(),
                const SizedBox(height: 24),
                _buildBookingSummary(bookingDetails),
                const SizedBox(height: 24),
                _buildPaymentInfo(),
                const SizedBox(height: 24),
                _buildImportantInfo(),
                const SizedBox(height: 32),
                _buildConfirmButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds welcoming header with confirmation progress indicator
  Widget _buildConfirmationHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Almost There!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your booking details below',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Displays comprehensive booking summary with activity details, 
  /// participant count, and pricing breakdown including member/guest rates
  Widget _buildBookingSummary(dynamic bookingDetails) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            /// Activity image and basic info display
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.activity.displayImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.teal,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal[400]!, Colors.teal[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activity.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.activity.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            /// Reservation details: date, time, location, participants
            _buildSummaryRow(
              'Date',
              DateFormat(
                'EEEE, MMM dd, yyyy',
              ).format(bookingDetails.bookingDate),
            ),
            _buildSummaryRow('Time', widget.activity.time),
            _buildSummaryRow('Location', widget.activity.facilityName),
            _buildSummaryRow(
              'Participants',
              '${bookingDetails.participantCount} ${bookingDetails.participantCount == 1 ? 'person' : 'people'}',
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            /// Dynamic pricing display based on member vs guest status
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  children: [
                    if (authProvider.isLoggedIn) ...[
                      _buildSummaryRow(
                        'Member Price (per person)',
                        '${widget.activity.memberPrice.toStringAsFixed(2)} CHF',
                        isHighlighted: true,
                      ),
                    ] else ...[
                      _buildSummaryRow(
                        'Guest Price (per person)',
                        '${widget.activity.guestPrice.toStringAsFixed(2)} CHF',
                      ),
                    ],
                    _buildSummaryRow(
                      'Total Amount',
                      '${bookingDetails.totalPrice.toStringAsFixed(2)} CHF',
                      isTotal: true,
                    ),
                    const SizedBox(height: 12),
                    /// Points reward preview for activity participation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Points to earn: ${bookingDetails.expectedPoints}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable summary row component with styling options for totals and highlights
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.teal : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted
                  ? Colors.teal
                  : (isTotal ? Colors.black : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Payment terms and collection method information
  Widget _buildPaymentInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment will be collected at the venue on the day of your activity.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Essential booking policies and participant guidelines
  Widget _buildImportantInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Important Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.access_time,
              'Arrive 15 minutes early for check-in',
            ),
            _buildInfoItem(
              Icons.cancel,
              'Free cancellation up to 24 hours before',
            ),
            _buildInfoItem(
              Icons.receipt,
              'You will receive a confirmation email',
            ),
            _buildInfoItem(
              Icons.phone,
              'Contact us if you need to make changes',
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable info item with icon and text for policy display
  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Final confirmation button with error handling and loading states
  Widget _buildConfirmButton() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        return Column(
          children: [
            /// Error message display for booking failures
            if (bookingProvider.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookingProvider.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: bookingProvider.isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                child: bookingProvider.isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: bookingProvider.isLoading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text(
                'Go Back to Edit',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Processes final booking confirmation and navigates to success screen
  Future<void> _confirmBooking() async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    final success = await bookingProvider.confirmBooking();

    if (success && mounted) {
      unawaited(
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              booking: bookingProvider.lastCreatedBooking!,
              activity: widget.activity,
            ),
          ),
        ),
      );
    }
  }
}
