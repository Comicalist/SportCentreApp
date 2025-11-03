import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

/// Time blocking service for facility and club availability management
/// Prevents activity creation during blocked periods and detects scheduling conflicts
class BlockingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a time slot is blocked by club or facility restrictions
  /// Validates activity scheduling against hierarchical blocking rules (club overrides facility)
  static Future<BlockStatus> isTimeSlotBlocked({
    required String facilityId,
    required DateTime activityDate,
    required String activityTime,
    required int durationMinutes,
  }) async {
    try {
      final facilityDoc = await _firestore
          .collection('facilities')
          .doc(facilityId)
          .get();

      if (!facilityDoc.exists) {
        return BlockStatus(isBlocked: false);
      }

      final facilityData = facilityDoc.data()!;
      final clubId = facilityData['clubId'] as String;
      final facilityBlockedTimes = List<Map<String, dynamic>>.from(
        facilityData['blockedTimes'] ?? [],
      );

      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();

      if (!clubDoc.exists) {
        return BlockStatus(isBlocked: false);
      }

      final clubData = clubDoc.data()!;
      final clubBlockedTimes = List<Map<String, dynamic>>.from(
        clubData['blockedTimes'] ?? [],
      );

      /// Club-level blocking takes precedence over facility-level restrictions
      for (final block in clubBlockedTimes) {
        final overlaps = _doesActivityOverlapWithBlock(
          activityDate: activityDate,
          activityTime: activityTime,
          durationMinutes: durationMinutes,
          block: block,
        );

        if (overlaps) {
          return BlockStatus(
            isBlocked: true,
            reason: block['reason'] ?? 'Club blocked',
            source: 'club',
          );
        }
      }

      /// Facility-level blocking for operational restrictions
      for (final block in facilityBlockedTimes) {
        final overlaps = _doesActivityOverlapWithBlock(
          activityDate: activityDate,
          activityTime: activityTime,
          durationMinutes: durationMinutes,
          block: block,
        );

        if (overlaps) {
          return BlockStatus(
            isBlocked: true,
            reason: block['reason'] ?? 'Facility blocked',
            source: 'facility',
          );
        }
      }

      return BlockStatus(isBlocked: false);
    } catch (e) {
      return BlockStatus(isBlocked: false);
    }
  }

  /// Identify existing activities that conflict with proposed blocking period
  /// Used for club-wide blocking validation and conflict prevention
  static Future<List<Activity>> getActivitiesInTimeRange({
    required String clubId,
    required Map<String, dynamic> blockData,
  }) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('clubId', isEqualTo: clubId)
          .get();

      final conflictingActivities = <Activity>[];

      for (final doc in activitiesSnapshot.docs) {
        final activityData = doc.data();
        activityData['id'] = doc.id;
        final activity = Activity.fromJson(activityData);

        /// Check temporal overlap between activity and proposed block
        if (_doesActivityOverlapWithBlock(
          activityDate: activity.date,
          activityTime: activity.time,
          durationMinutes: activity.duration,
          block: blockData,
        )) {
          conflictingActivities.add(activity);
        }
      }

      return conflictingActivities;
    } catch (e) {
      return [];
    }
  }

  /// Identify facility-specific activities that conflict with blocking configuration
  /// Used for facility management and operational planning
  static Future<List<Activity>> getActivitiesInFacilityTimeRange({
    required String facilityId,
    required Map<String, dynamic> blockData,
  }) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('facilityId', isEqualTo: facilityId)
          .get();

      final conflictingActivities = <Activity>[];

      for (final doc in activitiesSnapshot.docs) {
        final activityData = doc.data();
        activityData['id'] = doc.id;
        final activity = Activity.fromJson(activityData);

        /// Validate activity-block temporal conflicts for facility scheduling
        if (_doesActivityOverlapWithBlock(
          activityDate: activity.date,
          activityTime: activity.time,
          durationMinutes: activity.duration,
          block: blockData,
        )) {
          conflictingActivities.add(activity);
        }
      }

      return conflictingActivities;
    } catch (e) {
      return [];
    }
  }

  /// Core temporal overlap detection between activities and blocking periods
  /// Handles both recurring weekly patterns and one-time date ranges
  static bool _doesActivityOverlapWithBlock({
    required DateTime activityDate,
    required String activityTime,
    required int durationMinutes,
    required Map<String, dynamic> block,
  }) {
    final isRecurring = block['recurring'] as bool;

    if (isRecurring) {
      /// Weekly recurring pattern validation (e.g., every Monday 9-10 AM)
      return _checkRecurringBlockOverlap(
        activityDate: activityDate,
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        block: block,
      );
    } else {
      /// One-time date range validation (e.g., December 20-25, 2024)
      return _checkOneTimeBlockOverlap(
        activityDate: activityDate,
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        block: block,
      );
    }
  }

  /// Validate activity against recurring weekly blocking patterns
  /// Supports day-of-week ranges and cross-week boundaries (e.g., Friday-Monday)
  static bool _checkRecurringBlockOverlap({
    required DateTime activityDate,
    required String activityTime,
    required int durationMinutes,
    required Map<String, dynamic> block,
  }) {
    final startDayOfWeek = block['startDayOfWeek'] as String?;
    final endDayOfWeek = block['endDayOfWeek'] as String?;
    final blockStartTime = block['startTime'] as String?;
    final blockEndTime = block['endTime'] as String?;

    if (startDayOfWeek == null ||
        endDayOfWeek == null ||
        blockStartTime == null ||
        blockEndTime == null) {
      return false;
    }

    /// Convert activity date to weekday name for pattern matching
    final activityDayOfWeek = _getDayOfWeekName(activityDate.weekday);

    /// Check if activity falls within blocked day range
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final startIndex = daysOfWeek.indexOf(startDayOfWeek);
    final endIndex = daysOfWeek.indexOf(endDayOfWeek);
    final activityIndex = daysOfWeek.indexOf(activityDayOfWeek);

    if (startIndex == -1 || endIndex == -1 || activityIndex == -1) {
      return false;
    }

    /// Handle day range validation including week wrap-around scenarios
    bool isDayInRange;
    if (startIndex <= endIndex) {
      isDayInRange = activityIndex >= startIndex && activityIndex <= endIndex;
    } else {
      /// Cross-week boundary (e.g., Friday-Monday blocking pattern)
      isDayInRange = activityIndex >= startIndex || activityIndex <= endIndex;
    }

    if (!isDayInRange) {
      return false;
    }

    /// Validate time overlap within the blocked day
    return _checkTimeOverlap(
      activityTime: activityTime,
      durationMinutes: durationMinutes,
      blockStartTime: blockStartTime,
      blockEndTime: blockEndTime,
    );
  }

  /// Validate activity against one-time blocking periods with multi-day support
  /// Handles single-day blocks, multi-day spans, and edge cases
  static bool _checkOneTimeBlockOverlap({
    required DateTime activityDate,
    required String activityTime,
    required int durationMinutes,
    required Map<String, dynamic> block,
  }) {
    final blockStartDate = block['startDate'] as String?;
    final blockEndDate = block['endDate'] as String?;
    final blockStartTime = block['startTime'] as String?;
    final blockEndTime = block['endTime'] as String?;

    if (blockStartDate == null ||
        blockEndDate == null ||
        blockStartTime == null ||
        blockEndTime == null) {
      return false;
    }

    final startDate = DateTime.parse(blockStartDate);
    final endDate = DateTime.parse(blockEndDate);

    /// Normalize dates for day-only comparison (ignore time components)
    final activityDateOnly = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );
    final startDateOnly = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

    /// Check if activity date falls within blocking date range
    if (activityDateOnly.isBefore(startDateOnly) ||
        activityDateOnly.isAfter(endDateOnly)) {
      return false;
    }

    /// Multi-day blocking logic with edge case handling
    final isFirstDay = activityDateOnly.isAtSameMomentAs(startDateOnly);
    final isLastDay = activityDateOnly.isAtSameMomentAs(endDateOnly);
    final isSingleDay = startDateOnly.isAtSameMomentAs(endDateOnly);

    if (isSingleDay) {
      /// Single day block: validate normal time range overlap
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: blockStartTime,
        blockEndTime: blockEndTime,
      );

      return timeOverlaps;
    } else if (isFirstDay) {
      /// First day of multi-day block: blocked from start time to end of day
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: blockStartTime,
        blockEndTime: '23:59',
      );

      return timeOverlaps;
    } else if (isLastDay) {
      /// Last day of multi-day block: blocked from start of day to end time
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: '00:00',
        blockEndTime: blockEndTime,
      );

      return timeOverlaps;
    } else {
      /// Middle day of multi-day block: entire day is blocked
      return true;
    }
  }

  /// Calculate temporal overlap between activity duration and blocking time window
  /// Uses minute-based calculations for precise scheduling validation
  static bool _checkTimeOverlap({
    required String activityTime,
    required int durationMinutes,
    required String blockStartTime,
    required String blockEndTime,
  }) {
    /// Convert all times to minutes since midnight for numeric comparison
    final activityStartMinutes = _timeToMinutes(activityTime);
    final activityEndMinutes = activityStartMinutes + durationMinutes;
    final blockStartMinutes = _timeToMinutes(blockStartTime);
    final blockEndMinutes = _timeToMinutes(blockEndTime);

    /// Overlap detection: activity starts before block ends AND activity ends after block starts
    final overlaps =
        activityStartMinutes < blockEndMinutes &&
        activityEndMinutes > blockStartMinutes;

    return overlaps;
  }

  /// Convert HH:mm time format to minutes since midnight for calculations
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Convert weekday number to standardized day name for pattern matching
  /// Maps ISO weekday standard (1=Monday, 7=Sunday) to readable names
  static String _getDayOfWeekName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}

/// Blocking status result with source attribution and reason tracking
/// Provides context for UI feedback and conflict resolution
class BlockStatus {
  BlockStatus({required this.isBlocked, this.reason, this.source});

  /// Whether the time slot is currently blocked
  final bool isBlocked;

  /// Business reason for the blocking (maintenance, training, etc.)
  final String? reason;

  /// Blocking source hierarchy: 'club' (takes precedence) or 'facility'
  final String? source;
}
