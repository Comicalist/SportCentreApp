import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../utils/activity_helpers.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/booking/booking_details_screen.dart';
import '../../services/booking_service.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;

  const ActivityCard({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActivityImage(),
          _buildActivityDetails(context),
        ],
      ),
    );
  }

  /// Build the activity image section with category badge and icon
  Widget _buildActivityImage() {
    return Container(
      height: AppConstants.activityImageHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
        color: Colors.grey[300],
      ),
      child: Stack(
        children: [
          // Activity Image - FIXED: Use displayImageUrl getter
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.cardBorderRadius),
            ),
            child: Image.network(
              activity.displayImageUrl, // ✅ Changed from activity.imageUrl
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ActivityHelpers.getCategoryColor(activity.category).withOpacity(0.7),
                        ActivityHelpers.getCategoryColor(activity.category).withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient background if image fails
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ActivityHelpers.getCategoryColor(activity.category).withOpacity(0.7),
                        ActivityHelpers.getCategoryColor(activity.category).withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      ActivityHelpers.getCategoryIcon(activity.category),
                      size: AppConstants.categoryIconSize,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          // Dark overlay for better text contrast on images
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.cardBorderRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Category Badge
          _buildCategoryBadge(),
        ],
      ),
    );
  }

  /// Build category badge in top-left corner
  Widget _buildCategoryBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: ActivityHelpers.getCategoryColor(activity.category),
          borderRadius: BorderRadius.circular(AppConstants.categoryBadgeRadius),
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
    );
  }

  /// Build the activity details section
  Widget _buildActivityDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActivityTitle(),
          const SizedBox(height: AppConstants.smallSpacing),
          _buildDateTimeInfo(),
          const SizedBox(height: 2),
          _buildClubInfo(),
          const SizedBox(height: 2),
          _buildLocationInfo(),
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildPriceAndAvailability(context),
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildBookButton(context),
        ],
      ),
    );
  }

  /// Build activity title
  Widget _buildActivityTitle() {
    return Text(
      activity.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build date and time information row
  Widget _buildDateTimeInfo() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM dd').format(activity.date),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(width: 16),
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          activity.time,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  /// Build club information row
  Widget _buildClubInfo() {
    return Row(
      children: [
        Icon(Icons.groups, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          activity.clubName,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build location information row
  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          activity.facilityName,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  /// Build price, points, and availability section
  Widget _buildPriceAndAvailability(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPriceAndPoints(context),
        _buildAvailabilityBadge(),
      ],
    );
  }

  /// Build price and points column (points computed with backend rules)
  Widget _buildPriceAndPoints(BuildContext context) {
    // Determine member/guest for preview
    final isMember = context.read<AuthProvider>().isLoggedIn;

    // Price per person according to member status
    final double currentPrice = isMember ? activity.memberPrice : activity.guestPrice;

    // Compute preview points using the same backend logic as the booking flow
    final int pointsPreview = BookingService.calculatePointsEarned(
      activity,
      currentPrice, // one participant preview
      isMember,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${currentPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 12,
              color: Colors.orange[600],
            ),
            const SizedBox(width: 2),
            Text(
              '$pointsPreview points',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build availability badge
  Widget _buildAvailabilityBadge() {
    final bool isFullyBooked = activity.spotsLeft <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ActivityHelpers.getSpotsColor(activity.spotsLeft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isFullyBooked ? 'Sold Out' : '${activity.spotsLeft} left',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build centered book now button
  Widget _buildBookButton(BuildContext context) {
    final bool isFullyBooked = activity.spotsLeft <= 0;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: isFullyBooked
            ? ElevatedButton(
                onPressed: null, // Disabled
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[600],
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Fully Booked',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: () => _handleBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }

  /// Handle booking button press
  void _handleBooking(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      // Show login dialog for non-authenticated users
      _showLoginPrompt(context);
      return;
    }

    // User is authenticated, navigate to booking details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(activity: activity),
      ),
    );
  }

  /// Show login prompt for non-authenticated users
  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign In Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'You need to sign in to book "${activity.name}".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Join us to access exclusive member rates and earn rewards!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(isSignUp: false),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }
}