# Event Participants Management - Testing Guide

## Overview
This document provides comprehensive testing procedures for the Admin Event Participants Management feature, including database synchronization verification.

## Features Implemented

### 1. Participant Model (`lib/models/participant.dart`)
- Combines booking and user data for comprehensive participant view
- Includes all necessary fields: user info, activity details, booking status, payment info
- Type-safe Firestore data conversion
- Helper methods for formatting and display

### 2. Participant Service (`lib/services/participant_service.dart`)
- **CRUD Operations:**
  - `getAllParticipants()` - Stream of all participants with real-time updates
  - `getParticipantsByActivity(activityId)` - Filter by specific activity
  - `getParticipantsByStatus(status)` - Filter by booking status
  - `getParticipant(bookingId)` - Get single participant details
  - `updateParticipant(bookingId, updates)` - Update participant details
  - `updateParticipantStatus(bookingId, status)` - Change booking status
  - `removeParticipant(bookingId)` - Delete participant booking

- **Additional Features:**
  - `searchParticipants(query)` - Search by name, email, confirmation number
  - `getParticipantStats()` - Get aggregated statistics
  - `bulkUpdateStatus(bookingIds, status)` - Batch status updates
  - `exportParticipants()` - Export data for reports

- **Database Synchronization:**
  - Uses Firestore transactions for atomic operations
  - Automatically updates activity capacity when bookings change
  - Updates user booking arrays
  - Real-time streaming with `snapshots()`

### 3. Admin UI (`lib/screens/admin/participants_management_screen.dart`)
- **List View:**
  - Real-time participant list with StreamBuilder
  - Expandable cards showing detailed information
  - Status badges (Confirmed, Pending, Cancelled, etc.)
  - Member/Guest identification

- **Search & Filter:**
  - Text search (name, email, confirmation number)
  - Filter by booking status
  - Clear filters option

- **Statistics Dashboard:**
  - Total participants count
  - Status breakdowns (confirmed, pending, cancelled, completed)
  - Total revenue calculation
  - Toggle visibility

- **Edit Functionality:**
  - Edit participant count
  - Update amount paid
  - Modify points earned
  - Change member/guest status
  - Add/edit notes
  - Form validation

- **Status Management:**
  - Quick status change dialog
  - Visual status selection
  - Automatic capacity updates

- **Remove Functionality:**
  - Confirmation dialog with impact details
  - Safe deletion with transaction
  - Automatic capacity restoration

## Testing Procedures

### Test 1: Real-time Synchronization (Manual Test)

**Purpose:** Verify that changes in the admin panel immediately reflect in Firestore and vice versa.

**Steps:**
1. Open the app in Chrome browser
2. Navigate to Admin Panel → Event Participants
3. Open Firebase Console in another browser tab
4. Go to Firestore Database → `bookings` collection

**Test Case 1.1: View Real-time Updates**
- [ ] Observe participants loading from Firestore
- [ ] Check that all data fields display correctly
- [ ] Verify statistics match actual database counts

**Test Case 1.2: Edit Participant**
1. [ ] Click "Edit" on any participant
2. [ ] Change participant count (e.g., from 1 to 2)
3. [ ] Change amount paid
4. [ ] Add notes
5. [ ] Click "Save"
6. [ ] **Verify:** Immediately check Firebase Console - document should update within 1-2 seconds
7. [ ] **Verify:** UI reflects changes without page refresh

**Test Case 1.3: Change Status**
1. [ ] Click "Change Status" on a confirmed booking
2. [ ] Select "Cancelled"
3. [ ] **Verify:** Firebase Console shows status change
4. [ ] **Verify:** Activity capacity increases (check `activities` collection)
5. [ ] **Verify:** Statistics update automatically

**Test Case 1.4: Remove Participant**
1. [ ] Click "Remove" on any participant
2. [ ] Confirm deletion
3. [ ] **Verify:** Document deleted from Firestore `bookings` collection
4. [ ] **Verify:** Activity `bookedCount` decreases by participant count
5. [ ] **Verify:** Activity `spotsLeft` increases
6. [ ] **Verify:** Booking ID removed from user's `upcomingBookings` array
7. [ ] **Verify:** Participant disappears from list immediately

### Test 2: Search and Filter Functionality

**Test Case 2.1: Text Search**
1. [ ] Enter participant name in search box
2. [ ] Verify only matching participants appear
3. [ ] Try partial matches
4. [ ] Search by email address
5. [ ] Search by confirmation number

**Test Case 2.2: Status Filters**
1. [ ] Click "Confirmed" filter chip
2. [ ] Verify only confirmed bookings show
3. [ ] Try each status filter (Pending, Cancelled, Completed, Waitlist)
4. [ ] Click "All" to clear filter
5. [ ] Verify all participants return

**Test Case 2.3: Combined Filters**
1. [ ] Apply status filter
2. [ ] Add text search
3. [ ] Verify results match both criteria
4. [ ] Click "Clear Filters"
5. [ ] Verify all filters reset

### Test 3: Statistics Accuracy

**Test Case 3.1: Statistics Calculation**
1. [ ] Open participants screen
2. [ ] Note statistics displayed
3. [ ] Count manually in Firebase Console:
   - Total bookings
   - Confirmed count
   - Pending count
   - Cancelled count
   - Sum of `amountPaid` for confirmed + completed
4. [ ] Verify statistics match manual counts

**Test Case 3.2: Statistics Update**
1. [ ] Note current statistics
2. [ ] Add a new booking (use app or Firebase Console)
3. [ ] Click refresh button
4. [ ] **Verify:** Total increases
5. [ ] Cancel a booking
6. [ ] **Verify:** Cancelled count increases, others adjust

### Test 4: Data Integrity & Validation

**Test Case 4.1: Edit Validation**
1. [ ] Try to set participant count to 0 or negative
2. [ ] Verify error message appears
3. [ ] Try negative amount
4. [ ] Verify error message
5. [ ] Try non-numeric values
6. [ ] Verify validation prevents save

**Test Case 4.2: Capacity Management**
1. [ ] Note activity capacity (e.g., 20 spots)
2. [ ] Note current `bookedCount`
3. [ ] Edit a booking to increase participant count
4. [ ] **Verify:** Firestore `bookedCount` increases by difference
5. [ ] **Verify:** `spotsLeft` decreases by difference
6. [ ] Cancel the booking
7. [ ] **Verify:** Capacity is restored

**Test Case 4.3: Transaction Consistency**
1. [ ] Disable internet connection temporarily
2. [ ] Try to edit a participant
3. [ ] **Verify:** Operation fails gracefully
4. [ ] Re-enable internet
5. [ ] Retry operation
6. [ ] **Verify:** Succeeds and syncs

### Test 5: Concurrent Updates

**Purpose:** Test behavior when multiple admins edit simultaneously.

**Steps:**
1. Open app in two different browser windows/tabs
2. Log in as admin in both
3. Navigate to participants management in both

**Test Case 5.1: Simultaneous Edits**
1. [ ] Select the same participant in both windows
2. [ ] Edit different fields in each window
3. [ ] Save in Window 1 first
4. [ ] **Verify:** Window 2 shows update immediately
5. [ ] Save in Window 2
6. [ ] **Verify:** Both windows reflect latest state
7. [ ] Check Firebase Console for final state

**Test Case 5.2: Conflicting Deletes**
1. [ ] Open same participant in both windows
2. [ ] Click delete in Window 1 and confirm
3. [ ] Try to delete in Window 2
4. [ ] **Verify:** Graceful error handling (participant already deleted)

### Test 6: Performance & Scalability

**Test Case 6.1: Large Dataset**
1. [ ] Add 50+ test bookings to Firestore
2. [ ] Open participants management
3. [ ] **Verify:** Loads within 3 seconds
4. [ ] Scroll through list
5. [ ] **Verify:** Smooth scrolling
6. [ ] Try search with large dataset
7. [ ] **Verify:** Filters quickly

**Test Case 6.2: Memory & Resource Usage**
1. [ ] Open participants screen
2. [ ] Leave open for 10 minutes
3. [ ] Check Chrome DevTools → Performance Monitor
4. [ ] **Verify:** No memory leaks
5. [ ] **Verify:** CPU usage reasonable

## Expected Results

### ✅ Real-time Synchronization
- Changes in admin panel appear in Firestore within 1-2 seconds
- Changes in Firestore appear in admin panel immediately via stream
- Multiple admin users see updates in real-time
- No need to refresh page manually

### ✅ Data Consistency
- Activity capacity always accurate
- User booking arrays stay synchronized
- Statistics reflect actual database state
- Transactions prevent race conditions

### ✅ User Experience
- Smooth, responsive UI
- Clear visual feedback for all actions
- Helpful error messages
- Intuitive search and filter

## Troubleshooting

### Issue: Changes not appearing
**Solution:** 
- Check internet connection
- Verify Firebase rules allow admin access
- Check browser console for errors
- Ensure StreamBuilder is active

### Issue: Transaction failures
**Solution:**
- Check for concurrent modifications
- Verify all referenced documents exist
- Check Firestore security rules
- Review error logs

### Issue: Statistics incorrect
**Solution:**
- Click refresh button
- Check date filters aren't affecting count
- Manually verify in Firebase Console
- Review query logic in `getParticipantStats()`

## Automated Testing Commands

To run automated widget tests (if implemented):
```bash
cd sport_centre_booking
flutter test test/participants_test.dart
```

To run integration tests:
```bash
flutter drive --target=test_driver/participants_test.dart
```

## Firebase Security Rules

Ensure these rules are set for proper access control:

```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{bookingId} {
      // Admins can read/write all bookings
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Users can read their own bookings
      allow read: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## Conclusion

This comprehensive testing guide ensures the Event Participants Management feature works reliably with proper database synchronization. Follow each test case and check all verification points. Document any issues found and retest after fixes.

---
**Last Updated:** 2025-10-29
**Version:** 1.0
**Feature Status:** ✅ Ready for Testing
