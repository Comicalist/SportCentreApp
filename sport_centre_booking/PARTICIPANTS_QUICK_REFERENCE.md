# Event Participants Management - Quick Reference

## 🚀 Quick Start

### Accessing the Feature
1. Run the app: `flutter run -d chrome`
2. Log in as admin user
3. Navigate: **Admin Panel** → **Event Participants**

## 📋 Key Features

### View Participants
- ✅ Real-time list of all event participants
- ✅ Expandable cards with detailed information
- ✅ Status badges (Confirmed, Pending, Cancelled, etc.)
- ✅ Member/Guest identification

### Search & Filter
- 🔍 **Search by:** Name, Email, Confirmation Number
- 🏷️ **Filter by Status:** All, Confirmed, Pending, Cancelled, Completed, Waitlist
- 🧹 **Clear Filters:** One-click reset

### Statistics Dashboard
- 📊 **Real-time Stats:**
  - Total participants
  - Confirmed count
  - Pending count  
  - Cancelled count
  - Completed count
  - Total revenue
- 👁️ Toggle visibility with eye icon

### Edit Participant
**Fields you can edit:**
- Number of participants
- Amount paid
- Points earned
- Member/Guest status
- Notes

**How to edit:**
1. Expand participant card
2. Click "Edit" button
3. Modify fields
4. Click "Save"

### Change Status
**Available statuses:**
- Pending
- Confirmed
- Cancelled
- Completed
- Waitlist

**How to change:**
1. Expand participant card
2. Click "Change Status"
3. Select new status
4. Confirm

### Remove Participant
**⚠️ Warning:** This action:
- Deletes the booking record
- Frees up activity spots
- Removes from user's booking history
- **Cannot be undone**

**How to remove:**
1. Expand participant card
2. Click "Remove" button
3. Read confirmation message
4. Click "Remove" to confirm

## 🔄 Database Synchronization

### How It Works
- **Real-time updates** via Firestore streams
- **Automatic sync** - no manual refresh needed
- **Transaction-based** - prevents data conflicts
- **Immediate reflection** - changes appear in 1-2 seconds

### What Gets Synchronized
1. **Bookings collection** - participant/booking data
2. **Activities collection** - capacity tracking
3. **Users collection** - booking arrays
4. **Statistics** - aggregated counts and revenue

### Verification
To verify sync is working:
1. Make a change in admin panel
2. Check Firebase Console (Firestore Database)
3. Changes should appear within 1-2 seconds

## 🧪 Quick Tests

### Test Real-time Sync
```
1. Open admin panel
2. Open Firebase Console in another tab
3. Edit a participant in admin panel
4. Watch Firebase Console update immediately
```

### Test Status Change
```
1. Change status from "Confirmed" to "Cancelled"
2. Check activity capacity increases
3. Verify statistics update
```

### Test Search
```
1. Type participant name in search box
2. Results filter immediately
3. Clear search to see all again
```

### Test Filter
```
1. Click "Confirmed" status chip
2. Only confirmed bookings show
3. Click "All" to reset
```

## 📝 Common Tasks

### Find a specific participant
```
Search by name or email → Click to expand → View details
```

### Update booking amount
```
Expand card → Edit → Change "Amount Paid" → Save
```

### Cancel a booking
```
Expand card → Change Status → Select "Cancelled" → Confirm
```

### Remove a no-show
```
Expand card → Remove → Confirm deletion
```

### View activity participants
```
Use search to filter by activity name
```

### Check revenue
```
View statistics panel → See "Revenue" stat
```

## 🛠️ Troubleshooting

### Participants not loading
- Check internet connection
- Verify Firebase project is running
- Check browser console for errors

### Changes not saving
- Verify admin permissions in Firebase rules
- Check form validation errors
- Ensure all required fields are filled

### Statistics incorrect
- Click refresh button (top right)
- Verify date ranges/filters
- Check Firebase Console directly

### Search not working
- Clear existing filters first
- Try exact match vs partial match
- Check spelling

## 🔐 Permissions Required

To use this feature, user must have:
- `role: 'admin'` in Firestore users collection
- Firebase Authentication logged in
- Appropriate Firestore security rules

## 📱 Access from Main App

### Admin Panel Navigation
```
Login → Home Screen → Admin Panel (if admin role) → Event Participants
```

### Direct Access (for testing)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminParticipantsScreen(),
  ),
);
```

## 🎯 Best Practices

### Do's ✅
- Use search/filter for large datasets
- Verify changes in Firebase Console
- Test with multiple browser tabs open
- Check statistics after making changes
- Use transactions for bulk operations

### Don'ts ❌
- Don't remove participants without checking
- Don't bypass form validation
- Don't modify Firestore directly for complex changes
- Don't ignore error messages

## 📚 Related Files

### Models
- `lib/models/participant.dart` - Participant data model
- `lib/models/booking.dart` - Booking status enum

### Services  
- `lib/services/participant_service.dart` - Business logic & Firestore operations

### Screens
- `lib/screens/admin/participants_management_screen.dart` - Main UI
- `lib/screens/admin/admin_panel.dart` - Admin dashboard

### Documentation
- `PARTICIPANTS_TESTING_GUIDE.md` - Comprehensive testing procedures

## 🚀 Future Enhancements

Potential features for future development:
- [ ] Export participants to CSV
- [ ] Bulk status updates
- [ ] Email notifications to participants
- [ ] Print participant lists
- [ ] Advanced filtering (date ranges, activity types)
- [ ] Participant check-in system
- [ ] QR code scanning
- [ ] Attendance tracking

---
**Created:** 2025-10-29
**Status:** ✅ Production Ready
