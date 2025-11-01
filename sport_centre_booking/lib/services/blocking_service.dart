import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class BlockingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
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
  

      // 3. Check club blocks first
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

      // 4. Check facility blocks
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

  /// Get activities that overlap with a block time range (for warning dialog)
  static Future<List<Activity>> getActivitiesInTimeRange({
    required String clubId,
    required Map<String, dynamic> blockData,
  }) async {
    try {
      // Get all activities for this club
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('clubId', isEqualTo: clubId)
          .get();

      final conflictingActivities = <Activity>[];

      for (final doc in activitiesSnapshot.docs) {
        final activityData = doc.data();
        activityData['id'] = doc.id; // Add id to the data
        final activity = Activity.fromJson(activityData);

        // Check if this activity overlaps with the block
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

  /// Get activities in a specific facility that overlap with a block
  static Future<List<Activity>> getActivitiesInFacilityTimeRange({
    required String facilityId,
    required Map<String, dynamic> blockData,
  }) async {
    try {
      // Get all activities for this facility
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('facilityId', isEqualTo: facilityId)
          .get();

      final conflictingActivities = <Activity>[];

      for (final doc in activitiesSnapshot.docs) {
        final activityData = doc.data();
        activityData['id'] = doc.id; // Add id to the data
        final activity = Activity.fromJson(activityData);

        // Check if this activity overlaps with the block
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

  /// Helper: Check if activity time overlaps with a block
  static bool _doesActivityOverlapWithBlock({
    required DateTime activityDate,
    required String activityTime,
    required int durationMinutes,
    required Map<String, dynamic> block,
  }) {
    final isRecurring = block['recurring'] as bool;

    if (isRecurring) {
      // Check recurring block (weekly pattern)
      return _checkRecurringBlockOverlap(
        activityDate: activityDate,
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        block: block,
      );
    } else {
      // Check one-time block (specific dates)
      return _checkOneTimeBlockOverlap(
        activityDate: activityDate,
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        block: block,
      );
    }
  }

  /// Check if activity overlaps with recurring weekly block
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

    if (startDayOfWeek == null || endDayOfWeek == null || 
        blockStartTime == null || blockEndTime == null) {
      return false;
    }

    // Get activity day of week
    final activityDayOfWeek = _getDayOfWeekName(activityDate.weekday);

    // Check if activity day is within blocked days range
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final startIndex = daysOfWeek.indexOf(startDayOfWeek);
    final endIndex = daysOfWeek.indexOf(endDayOfWeek);
    final activityIndex = daysOfWeek.indexOf(activityDayOfWeek);

    if (startIndex == -1 || endIndex == -1 || activityIndex == -1) {
      return false;
    }

    // Check if activity day is within range (handle wrap-around week)
    bool isDayInRange;
    if (startIndex <= endIndex) {
      isDayInRange = activityIndex >= startIndex && activityIndex <= endIndex;
    } else {
      // Wrap-around case (e.g., Friday to Monday)
      isDayInRange = activityIndex >= startIndex || activityIndex <= endIndex;
    }

    if (!isDayInRange) {
      return false;
    }

    // Check time overlap
    return _checkTimeOverlap(
      activityTime: activityTime,
      durationMinutes: durationMinutes,
      blockStartTime: blockStartTime,
      blockEndTime: blockEndTime,
    );
  }

  /// Check if activity overlaps with one-time block
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

   
    if (blockStartDate == null || blockEndDate == null || 
        blockStartTime == null || blockEndTime == null) {
   
      return false;
    }

    // Parse block dates
    final startDate = DateTime.parse(blockStartDate);
    final endDate = DateTime.parse(blockEndDate);

    // Normalize dates to compare only year/month/day
    final activityDateOnly = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

   

    // Check if activity date is within blocked date range
    if (activityDateOnly.isBefore(startDateOnly) ||
        activityDateOnly.isAfter(endDateOnly)) {
     
      return false;
    }

   
    
    // NEW LOGIC: Handle multi-day blocks properly
    final isFirstDay = activityDateOnly.isAtSameMomentAs(startDateOnly);
    final isLastDay = activityDateOnly.isAtSameMomentAs(endDateOnly);
    final isSingleDay = startDateOnly.isAtSameMomentAs(endDateOnly);
    
    if (isSingleDay) {
      // Single day block: check time range normally
     
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: blockStartTime,
        blockEndTime: blockEndTime,
      );
     
      return timeOverlaps;
    } else if (isFirstDay) {
      // First day: block from startTime to end of day
    
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: blockStartTime,
        blockEndTime: '23:59',
      );
     
      return timeOverlaps;
    } else if (isLastDay) {
      // Last day: block from start of day to endTime
    
      final timeOverlaps = _checkTimeOverlap(
        activityTime: activityTime,
        durationMinutes: durationMinutes,
        blockStartTime: '00:00',
        blockEndTime: blockEndTime,
      );
    
      return timeOverlaps;
    } else {
      
     
      return true;
    }
  }

  /// Check if activity time overlaps with block time
  static bool _checkTimeOverlap({
    required String activityTime,
    required int durationMinutes,
    required String blockStartTime,
    required String blockEndTime,
  }) {
    // Parse times to minutes since midnight
    final activityStartMinutes = _timeToMinutes(activityTime);
    final activityEndMinutes = activityStartMinutes + durationMinutes;
    final blockStartMinutes = _timeToMinutes(blockStartTime);
    final blockEndMinutes = _timeToMinutes(blockEndTime);

   

    // Check for overlap: activity starts before block ends AND activity ends after block starts
    final overlaps = activityStartMinutes < blockEndMinutes &&
        activityEndMinutes > blockStartMinutes;
        
   
    return overlaps;
  }

  /// Convert time string "HH:mm" to minutes since midnight
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Get day of week name from weekday number (1=Monday, 7=Sunday)
  static String _getDayOfWeekName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

/// Result class for blocking status
class BlockStatus {
  final bool isBlocked;
  final String? reason;
  final String? source; // 'club' or 'facility'

  BlockStatus({
    required this.isBlocked,
    this.reason,
    this.source,
  });
}
