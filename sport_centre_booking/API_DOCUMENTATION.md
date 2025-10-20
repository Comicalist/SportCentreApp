# Sport Centre Booking App - API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication API](#authentication-api)
3. [User Management API](#user-management-api)
4. [Activity Management API](#activity-management-api)
5. [Booking Management API](#booking-management-api)
6. [Points & Rewards API](#points--rewards-api)
7. [Data Models](#data-models)
8. [Error Handling](#error-handling)
9. [Security Rules](#security-rules)

## Overview

### Technology Stack
- **Backend**: Firebase (Firestore NoSQL Database)
- **Authentication**: Firebase Authentication
- **Real-time**: Firestore real-time listeners
- **File Storage**: Firebase Storage (planned)

### Base Configuration
```dart
// Firebase configuration
static const FirebaseOptions currentPlatform = FirebaseOptions(
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com", 
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:platform:abcdef123456"
);
```

### Collections Structure
```
Firestore Database
├── users/{userId}           # User profiles and preferences
├── activities/{activityId}  # Available activities and classes  
├── bookings/{bookingId}     # Booking records and history
├── clubs/{clubId}           # Sport clubs and venues
└── notifications/{notifId}  # User notifications (planned)
```

## Authentication API

### Firebase Authentication Service

#### Sign Up with Email
```dart
// AuthService.registerWithEmail()
Future<UserCredential?> registerWithEmail(
  String email,
  String password, 
  String displayName, {
  bool isClubOwner = false,
}) async
```

**Parameters:**
- `email` (String): Valid email address
- `password` (String): Password meeting security requirements  
- `displayName` (String): User's full name (2-40 characters)
- `isClubOwner` (bool): Optional club owner flag

**Returns:**
- `UserCredential?`: Firebase user credential on success
- `Exception`: Firebase auth exception on failure

**Process Flow:**
1. Create Firebase Auth user
2. Update display name
3. Create Firestore user document
4. Send email verification automatically
5. Return user credential

#### Sign In with Email  
```dart
// AuthService.signInWithEmail()
Future<UserCredential?> signInWithEmail(
  String email,
  String password,
) async
```

**Parameters:**
- `email` (String): Registered email address
- `password` (String): User password

**Returns:**
- `UserCredential?`: Firebase user credential on success
- `Exception`: Authentication exception on failure

#### Password Reset
```dart  
// AuthService.resetPassword()
Future<void> resetPassword(String email) async
```

**Parameters:**
- `email` (String): Registered email address

**Effect:**
Sends password reset email via Firebase Auth

#### Email Verification
```dart
// AuthService.sendEmailVerification()
Future<void> sendEmailVerification() async

// AuthService.isEmailVerified (getter)
static bool get isEmailVerified => currentUser?.emailVerified ?? false;

// AuthService.reloadUser()
Future<void> reloadUser() async
```

## User Management API

### User Document Structure
```javascript
// users/{userId}
{
  "uid": "firebase-user-id",
  "email": "user@example.com", 
  "displayName": "John Doe",
  "createdAt": Timestamp,
  "lastLoginAt": Timestamp,
  "role": "user",           // "user" | "admin" | "clubOwner"
  "isActive": true,
  
  // Points & Rewards
  "totalPoints": 150,
  "availablePoints": 75,
  "lifetimePointsEarned": 500,
  
  // Membership
  "isMember": false,
  "membershipType": null,   // "basic" | "premium" | null
  "membershipExpiry": null,
  
  // Permissions  
  "isClubOwner": false,
  
  // Profile Data
  "bookingHistory": ["booking1", "booking2"],
  "upcomingBookings": ["booking3"], 
  "profileImageUrl": ""
}
```

### User Operations

#### Create User Document
```dart
// AuthService._createUserDocument()
Future<void> _createUserDocument(
  User user,
  String displayName, {
  bool isClubOwner = false,
}) async
```

**Firestore Operation:**
```javascript
// Creates document at users/{userId}
await userDoc.set({
  // User data with default values
}, SetOptions(merge: true));
```

#### Update Last Login
```dart
// AuthService.updateLastLogin()  
Future<void> updateLastLogin() async
```

**Firestore Operation:**
```javascript
await users.doc(userId).update({
  "lastLoginAt": FieldValue.serverTimestamp()
});
```

#### Load User Data
```dart
// AuthProvider._loadUserData()
Future<void> _loadUserData(String uid) async
```

**Firestore Operation:**
```javascript
// Try cache first, then server
const doc = await users.doc(uid).get({source: "cache"});
if (!doc.exists) {
  const doc = await users.doc(uid).get({source: "server"});
}
```

## Activity Management API

### Activity Document Structure
```javascript
// activities/{activityId}
{
  "id": "activity-unique-id",
  "name": "Morning Yoga Class",
  "description": "Beginner-friendly yoga session...",
  "category": "wellness",      // "fitness" | "wellness" | "kids" | "workshops"
  "price": 15.00,
  "duration": 60,             // minutes
  "maxParticipants": 12,
  "currentParticipants": 8,
  "location": "Studio A, Main Building", 
  "imageUrl": "https://storage.googleapis.com/...",
  "startTime": Timestamp,
  "endTime": Timestamp,
  "isActive": true,
  "createdBy": "club-owner-uid",
  "pointsReward": 25,
  "requirements": ["yoga mat", "water bottle"],
  "skillLevel": "beginner",   // "beginner" | "intermediate" | "advanced"
  "instructor": "Sarah Johnson",
  "tags": ["indoor", "relaxation", "flexibility"],
  
  // Metadata
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Activity Operations

#### Query Activities
```dart
// ActivityService.getActivities()
Stream<List<Activity>> getActivities({
  String? category,
  DateTime? startDate,
  DateTime? endDate,
  bool? availableOnly,
}) async*
```

**Firestore Query:**
```javascript
let query = activities.where("isActive", "==", true);

if (category) {
  query = query.where("category", "==", category);
}

if (startDate) {
  query = query.where("startTime", ">=", startDate);
}

if (availableOnly) {
  query = query.where("currentParticipants", "<", maxParticipants);
}

query = query.orderBy("startTime");
```

#### Create Activity (Club Owners)
```dart
// ActivityService.createActivity()
Future<String> createActivity(Activity activity) async
```

**Firestore Operation:**
```javascript
const docRef = await activities.add({
  ...activityData,
  "createdAt": FieldValue.serverTimestamp(),
  "updatedAt": FieldValue.serverTimestamp()
});
return docRef.id;
```

#### Update Activity
```dart
// ActivityService.updateActivity()  
Future<void> updateActivity(String activityId, Map<String, dynamic> updates) async
```

**Firestore Operation:**
```javascript
await activities.doc(activityId).update({
  ...updates,
  "updatedAt": FieldValue.serverTimestamp()
});
```

## Booking Management API

### Booking Document Structure
```javascript
// bookings/{bookingId}
{
  "id": "booking-unique-id",
  "activityId": "activity-reference-id",
  "userId": "user-reference-id",
  "activityName": "Morning Yoga Class",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  
  // Timing
  "bookingDate": Timestamp,
  "activityStartTime": Timestamp,
  "activityEndTime": Timestamp,
  
  // Status
  "status": "confirmed",      // "confirmed" | "cancelled" | "completed" | "waitlist"
  "cancellationReason": null,
  
  // Pricing
  "originalPrice": 15.00,
  "pointsUsed": 50,          // Points redeemed for discount
  "pointsDiscount": 5.00,    // £5 discount from points
  "totalPrice": 10.00,       // Final amount paid
  "pointsEarned": 25,        // Points earned from completing
  
  // Metadata
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "notes": null
}
```

### Booking Operations

#### Create Booking
```dart
// BookingService.createBooking()
Future<String> createBooking({
  required String activityId,
  required String userId, 
  int pointsToUse = 0,
  String? notes,
}) async
```

**Process Flow:**
1. Validate activity availability
2. Calculate pricing with points discount
3. Create booking document  
4. Update activity participant count
5. Award points to user
6. Send confirmation notification

**Firestore Transaction:**
```javascript
await firestore.runTransaction(async (transaction) => {
  // Read activity and user data
  const activity = await transaction.get(activities.doc(activityId));
  const user = await transaction.get(users.doc(userId));
  
  // Validate availability
  if (activity.data().currentParticipants >= activity.data().maxParticipants) {
    throw new Error("Activity is full");
  }
  
  // Create booking
  const bookingRef = bookings.doc();
  transaction.set(bookingRef, bookingData);
  
  // Update activity count
  transaction.update(activities.doc(activityId), {
    currentParticipants: FieldValue.increment(1)
  });
  
  // Update user points
  transaction.update(users.doc(userId), {
    availablePoints: FieldValue.increment(-pointsUsed),
    totalPoints: FieldValue.increment(pointsEarned)
  });
});
```

#### Cancel Booking  
```dart
// BookingService.cancelBooking()
Future<void> cancelBooking(String bookingId, String reason) async
```

**Process Flow:**
1. Update booking status to cancelled
2. Decrease activity participant count
3. Process refund based on cancellation policy
4. Refund used points if applicable

#### Get User Bookings
```dart
// BookingService.getUserBookings()
Stream<List<Booking>> getUserBookings(String userId) async*
```

**Firestore Query:**
```javascript
bookings
  .where("userId", "==", userId)
  .orderBy("createdAt", "desc")
  .onSnapshot()
```

## Points & Rewards API

### Points System

#### Point Values
```dart
class PointValues {
  static const int activityCompletion = 25;
  static const int firstTimeBonus = 50;
  static const int weeklyStreak = 15;
  static const int monthlyStreak = 100;
  static const int friendReferral = 75;
  static const int activityReview = 10;
  
  static const double pointsToMoney = 0.01; // £0.01 per point
  static const int minimumRedemption = 50;   // 50 points minimum
}
```

#### Award Points
```dart
// UserService.awardPoints()
Future<void> awardPoints(
  String userId,
  int points,
  String reason,
) async
```

**Firestore Operation:**
```javascript
await users.doc(userId).update({
  "availablePoints": FieldValue.increment(points),
  "totalPoints": FieldValue.increment(points),
  "lifetimePointsEarned": FieldValue.increment(points)
});

// Log points transaction
await pointsHistory.add({
  "userId": userId,
  "points": points,
  "type": "earned",
  "reason": reason,
  "timestamp": FieldValue.serverTimestamp()
});
```

#### Redeem Points
```dart
// UserService.redeemPoints()
Future<double> redeemPoints(String userId, int points) async
```

**Returns:** Discount amount in pounds

**Validation:**
- Minimum 50 points required
- Cannot exceed user's available points  
- Maximum 50% of activity price

## Data Models

### Dart Model Classes

#### AppUser Model
```dart
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String role;
  final bool isActive;
  
  // Points & Rewards
  final int totalPoints;
  final int availablePoints;
  final int lifetimePointsEarned;
  
  // Membership
  final bool isMember;
  final String? membershipType;
  final DateTime? membershipExpiry;
  
  // Permissions
  final bool isClubOwner;
  
  // Profile Data  
  final List<String> bookingHistory;
  final List<String> upcomingBookings;
  final String profileImageUrl;

  // Computed Properties
  bool get isAdmin => role == 'admin';
  String get initials => displayName.split(' ').map((n) => n[0]).take(2).join();

  // Factory constructor from Firestore
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      // ... other fields
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    // ... other fields  
  };
}
```

#### Activity Model
```dart
class Activity {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int duration;
  final int maxParticipants;
  final int currentParticipants;
  final String location;
  final String imageUrl;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final String createdBy;
  final int pointsReward;
  final List<String> requirements;
  final String skillLevel;
  final String instructor;
  final List<String> tags;

  // Computed Properties
  bool get isAvailable => currentParticipants < maxParticipants;
  bool get isFull => currentParticipants >= maxParticipants;
  int get spotsRemaining => maxParticipants - currentParticipants;
  bool get isToday => DateUtils.isSameDay(startTime, DateTime.now());
  
  // Category helpers
  bool get isFitness => category == 'fitness';
  bool get isWellness => category == 'wellness';
  bool get isKids => category == 'kids';
  bool get isWorkshop => category == 'workshops';

  // Factory constructor from Firestore
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      // ... other fields
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }
}
```

#### Booking Model  
```dart
class Booking {
  final String id;
  final String activityId;
  final String userId;
  final String activityName;
  final String userName;
  final String userEmail;
  final DateTime bookingDate;
  final DateTime activityStartTime;
  final DateTime activityEndTime;
  final BookingStatus status;
  final String? cancellationReason;
  final double originalPrice;
  final int pointsUsed;
  final double pointsDiscount;
  final double totalPrice;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  // Computed Properties
  bool get canCancel {
    final now = DateTime.now();
    final timeDiff = activityStartTime.difference(now);
    return status == BookingStatus.confirmed && timeDiff.inHours >= 24;
  }
  
  bool get isUpcoming {
    return activityStartTime.isAfter(DateTime.now()) && 
           status == BookingStatus.confirmed;
  }
  
  bool get isPast => activityEndTime.isBefore(DateTime.now());
  
  String get statusDisplay {
    switch (status) {
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.cancelled: return 'Cancelled';  
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.waitlist: return 'Waitlisted';
    }
  }
}

enum BookingStatus {
  confirmed,
  cancelled, 
  completed,
  waitlist
}
```

## Error Handling

### Firebase Error Mapping
```dart
// AuthService._handleAuthException()
static String _handleAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No account found with this email address.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'An account already exists with this email address.';
    case 'weak-password':
      return 'Password is too weak. Please choose a stronger password.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'too-many-requests':
      return 'Too many failed attempts. Please try again later.';
    case 'operation-not-allowed':
      return 'Email/password accounts are not enabled. Please contact support.';
    case 'invalid-credential':
      return 'Invalid email or password. Please check your credentials.';
    default:
      return 'Authentication failed. Please try again.';
  }
}
```

### Custom Exception Classes
```dart
class BookingException implements Exception {
  final String message;
  final String code;
  
  BookingException(this.message, this.code);
  
  @override
  String toString() => 'BookingException: $message (Code: $code)';
}

class ActivityNotAvailableException extends BookingException {
  ActivityNotAvailableException() : super('Activity is no longer available', 'ACTIVITY_FULL');
}

class InsufficientPointsException extends BookingException {
  InsufficientPointsException(int required, int available) 
    : super('Insufficient points. Required: $required, Available: $available', 'INSUFFICIENT_POINTS');
}
```

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null 
          && request.auth.uid == userId;
      
      // Admins can read all users
      allow read: if request.auth != null 
          && isAdmin(request.auth.uid);
    }
    
    // Activities are publicly readable, club owners can create/edit
    match /activities/{activityId} {
      allow read: if true;
      allow create, update: if request.auth != null 
          && (isClubOwner(request.auth.uid) || isAdmin(request.auth.uid));
      allow delete: if request.auth != null 
          && (resource.data.createdBy == request.auth.uid || isAdmin(request.auth.uid));
    }
    
    // Bookings are user-specific
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null 
          && request.auth.uid == resource.data.userId;
      
      // Club owners can read bookings for their activities
      allow read: if request.auth != null 
          && isClubOwnerOfActivity(request.auth.uid, resource.data.activityId);
      
      // Admins can read all bookings
      allow read: if request.auth != null 
          && isAdmin(request.auth.uid);
    }
    
    // Helper functions
    function isAdmin(userId) {
      return exists(/databases/$(database)/documents/users/$(userId))
          && get(/databases/$(database)/documents/users/$(userId)).data.role == 'admin';
    }
    
    function isClubOwner(userId) {
      return exists(/databases/$(database)/documents/users/$(userId))
          && get(/databases/$(database)/documents/users/$(userId)).data.isClubOwner == true;
    }
    
    function isClubOwnerOfActivity(userId, activityId) {
      return exists(/databases/$(database)/documents/activities/$(activityId))
          && get(/databases/$(database)/documents/activities/$(activityId)).data.createdBy == userId;
    }
  }
}
```

### Authentication Requirements
- ✅ **Read Activities**: Public (no auth required)  
- 🔐 **Book Activities**: Authenticated users only
- 🔐 **User Profile**: Own data only (+ admins)
- 🛡️ **Create Activities**: Club owners + admins only
- 🛡️ **User Management**: Admins only
- 🏢 **Club Management**: Club owners (own clubs) + admins

---

This API documentation provides comprehensive coverage of all backend operations, data structures, and security implementations in the Sport Centre Booking app. The Firebase-based architecture ensures scalable, real-time functionality with robust security controls.