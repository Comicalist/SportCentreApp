# Sport Centre Booking App - Technical Documentation

## Table of Contents

1. [Overview](#1-overview)

   - [Purpose](#purpose)
   - [Links](#links)
   - [Main Features](#main-features)
   - [Target Users](#target-users)
   - [Technology Stack Summary](#technology-stack-summary)
   - [Sample User Credentials](#sample-user-credentials)

2. [Architecture & Design](#2-architecture--design)

   - [System Overview](#system-overview)
   - [Main Components](#main-components)
   - [Design Patterns](#design-patterns)

3. [Data Model](#3-data-model)

   - [Core Entities and Relationships](#core-entities-and-relationships)
   - [Firestore Collections Schema](#firestore-collections-schema)
   - [Data Flow](#data-flow)

4. [Installation & Setup](#4-installation--setup)

   - [Prerequisites](#prerequisites)
   - [Step-by-Step Setup](#step-by-step-setup)
   - [Initial Data Setup](#initial-data-setup)

5. [API Documentation](#5-api-documentation)

   - [Firebase Authentication Endpoints](#firebase-authentication-endpoints)
   - [Firestore API Operations](#firestore-api-operations)
   - [Example API Responses](#example-api-responses)

6. [Configuration & Deployment](#6-configuration--deployment)

   - [Environment Structure](#environment-structure)
   - [Build Commands](#build-commands)
   - [Secrets Management](#secrets-management)

7. [Codebase Structure](#7-codebase-structure)

   - [Folder Layout](#folder-layout)
   - [Naming Conventions](#naming-conventions)

8. [Business Logic & Core Features](#8-business-logic--core-features)

   - [Activity Booking Workflow](#activity-booking-workflow)
   - [Real-time Capacity Management](#real-time-capacity-management)
   - [Club Owner Activity Management](#club-owner-activity-management)
   - [Club Owner Booking Management](#club-owner-booking-management)
   - [Admin Oversight Features](#admin-oversight-features)
   - [Notification & Reminder System](#notification--reminder-system)
   - [Voucher & Discount System](#voucher--discount-system)
   - [Development & Testing Infrastructure](#development--testing-infrastructure)

9. [Security & Privacy](#9-security--privacy)

   - [Authentication & Authorization](#authentication--authorization)
   - [Firestore Security Rules](#firestore-security-rules)
   - [Data Protection](#data-protection)
   - [Secure Coding Practices](#secure-coding-practices)

10. [Maintenance & Monitoring](#10-maintenance--monitoring)

    - [Logging & Monitoring](#logging--monitoring)
    - [Firebase Monitoring](#firebase-monitoring)
    - [Error Tracking](#error-tracking)

11. [Contributors & Contact](#12-contributors--contact)
    - [Main Contributors](#main-contributors)
    - [Documentation Maintenance](#documentation-maintenance)

---

## 1. Overview

### Purpose

The Sport Centre Booking App is a comprehensive Flutter application designed for public access to sport centre facilities and activities. It enables users to browse, book, and manage sports activities while providing club owners and administrators with powerful management tools.

### Links

- [Project on GitHub](https://github.com/Comicalist/SportCentreApp)
- [Firebase Console](https://console.firebase.google.com/u/0/project/sportcentreapp/overview)
- [Closed Beta on Google Play](https://play.google.com/apps/internaltest/4701168419770952808) 

### Main Features

- **Public Activity Browsing**: View available activities without authentication
- **User Authentication**: Email/password registration and login with email verification
- **Activity Booking System**: Real-time booking with capacity management
- **Points & Rewards System**: Earn points from activities, redeem for vouchers and discounts
- **Multi-Role Access Control**: Regular users, club owners, and administrators with different permissions
- **Club Management**: Club owners can create and manage activities for their facilities
- **Admin Panel**: System administrators can manage users and approve clubs
- **Real-time Notifications**: Email or in-app notifications
- **Calendar Integration**: View bookings in calendar format

### Target Users

- **Public Users**: Anyone wanting to book sports activities at local centres
- **Club Owners**: Businesses managing sport facilities and offering activities
- **System Administrators**: Platform managers overseeing the entire system

### Technology Stack Summary

- **Frontend**: Flutter 3.9.2+ with Material Design 3
- **Backend**: Firebase (Firestore, Authentication, Storage, Functions)
- **State Management**: Provider pattern with ChangeNotifier
- **Real-time Features**: Firestore snapshots for live updates
- **Notifications**: Firebase Cloud Functions with NodeMailer
- **Image Handling**: Firebase Storage with local image picker
- **Calendar**: table_calendar package for booking visualization

### Sample User Credentials

The following test accounts are available for development and testing:

#### Super Admin Account

- **Email**: `admin@sportcentre.ch`
- **Password**: `Aa!12345`
- **Role**: System Administrator
- **Access**: Full system access, club approval, user management

#### Club Owner Accounts

- **Sarah Weber - FitnessPlus Zürich**

  - Email: `sarah.weber@fitnessplus.ch`
  - Password: `Aa!12345`
  - Role: Club Owner
  - Club: FitnessPlus Zürich (Fitness & Training)

- **Marco Rossi - Aquatica Basel**

  - Email: `marco.rossi@aquatica.ch`
  - Password: `Aa!12345`
  - Role: Club Owner
  - Club: Aquatica Basel (Swimming & Wellness)

- **Anna Schneider - ZenFlow Bern**
  - Email: `anna.schneider@zenflow.ch`
  - Password: `Aa!12345`
  - Role: Club Owner
  - Club: ZenFlow Wellness Bern (Yoga & Meditation)

#### Regular User Accounts

- **Lucas Zimmermann**

  - Email: `lucas.zimmermann@bluemail.ch`
  - Password: `Aa!12345`

- **Elena Fischer**

  - Email: `elena.fischer@sunrise.ch`
  - Password: `Aa!12345`

- **Julia Keller**

  - Email: `julia.keller@hotmail.ch`
  - Password: `Aa!12345`

- **Thomas Meyer**

  - Email: `thomas.meyer@gmx.ch`
  - Password: `Aa!12345`

- **David Brunner**

  - Email: `david.brunner@outlook.ch`
  - Password: `Aa!12345`

- **Nina Huber**

  - Email: `nina.huber@protonmail.ch`
  - Password: `Aa!12345`

- **Stefan Bauer**
  - Email: `stefan.bauer@icloud.ch`
  - Password: `Aa!12345`

### Sample Data Overview

The seeded database includes:

- **3 Swiss Sport Clubs** in Zürich, Basel, and Bern
- **7 Facilities** across the clubs (gyms, pools, studios)
- **80+ Activities** scheduled over 2 months
- **60+ Realistic Bookings** with different statuses
- **Voucher System** with club-specific discounts

## 2. Architecture & Design

### System Overview

The application follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   User Screens  │ │ Club Owner UI   │ │   Admin Panel   ││
│  │  (Flutter UI)   │ │  (Management)   │ │  (Dashboard)    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Providers     │ │    Services     │ │     Models      ││
│  │ (State Mgmt)    │ │ (API Calls)     │ │ (Data Entities) ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Firestore     │ │ Firebase Auth   │ │Firebase Storage ││
│  │  (Database)     │ │ (Authentication)│ │    (Images)     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                  Cloud Functions Layer                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Email Services  │ │  Notifications  │ │   Migrations    ││
│  │   (NodeJS)      │ │   (Triggers)    │ │   (Scripts)     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Main Components

1. **Authentication Wrapper**: Manages user authentication state and routing
2. **Main Navigation**: Bottom navigation with role-based screen access
3. **Provider Layer**: State management for authentication, bookings, and user data
4. **Service Layer**: Business logic and Firebase integration
5. **Model Layer**: Data structures and serialization logic
6. **Cloud Functions**: Server-side logic for notifications and automated tasks

### Design Patterns

- **Provider Pattern**: For state management and dependency injection
- **Repository Pattern**: Services abstract Firebase operations
- **Factory Pattern**: Model constructors for Firestore data conversion
- **Observer Pattern**: StreamBuilder widgets for real-time UI updates

## 3. Data Model

### Core Entities and Relationships

```mermaid
erDiagram
    %% Core User Management
    Users {
        string uid PK "Firebase Auth UID"
        string email UK "Email address"
        string displayName "Full name"
        timestamp createdAt
        timestamp lastLoginAt
        string role "user | admin"
        boolean isActive
        boolean isClubOwner
        int totalPoints
        int availablePoints "Spendable points"
        int lifetimePointsEarned
        boolean isMember
        string membershipType "basic | standard | premium"
        timestamp membershipExpiry
    }

    %% Club Management
    Clubs {
        string id PK
        string name
        string ownerId FK
        string location
        boolean isActive
        boolean isApproved "Admin approval required"
        timestamp createdAt
        json blockedTimes "Array of blocked time slots"
    }

    %% Facility Infrastructure
    Facilities {
        string id PK
        string clubId FK
        string title "Facility name"
        string description
        int maxCapacity
        string imageUrl
        boolean isActive
        timestamp createdAt
        timestamp updatedAt
        json blockedTimes "Array of blocked time slots"
    }

    %% Activity Catalog
    Activities {
        string id PK
        string clubId FK
        string facilityId FK
        string clubName "Denormalized"
        string facilityName "Denormalized"
        string name
        string description
        string category "Wellness | Fitness | Kids | Workshops"
        timestamp date
        string time "HH:mm format"
        int duration "Minutes"
        string timeCategory "Morning | Afternoon | Evening"
        int capacity
        int bookedCount
        double guestPrice
        double memberPrice
        int pointsReward
        boolean allowVouchers
        json requirements "Array of requirements"
        string imageUrl
        timestamp createdAt
        timestamp updatedAt
        string createdBy FK
    }

    %% Booking System - Main Collection
    Bookings {
        string id PK
        string activityId FK
        string userId FK
        string activityTitle "Denormalized"
        timestamp activityDate
        string activityTime
        timestamp bookingDate
        string status "pending | confirmed | cancelled | completed | waitlist"
        string clubId FK "Denormalized"
        string clubName "Denormalized"
        string facilityId FK "Denormalized"
        string facilityName "Denormalized"
        int participantCount
        double totalPrice
        double amountPaid
        int pointsEarned
        int pointsUsed
        boolean isMemberBooking
        string confirmationNumber UK
        timestamp createdAt
        string timeSlotId
        string cancellationReason
        timestamp cancelledAt
        string voucherId FK
        double voucherDiscount
    }

    %% User Subcollections
    UserBookings {
        string id PK
        string userId FK "Parent collection"
        string activityId FK
        string bookingId FK
        string activityTitle
        timestamp bookingDate
        timestamp createdAt
        string status "confirmed | cancelled | completed | waitlist"
        int participantCount
        double totalPrice
        int pointsEarned
        int pointsUsed
        boolean isMemberBooking
        string confirmationNumber
    }

    UserRewardsLedger {
        string id PK
        string userId FK "Parent collection"
        string activityId FK
        string activityTitle
        string bookingId FK
        int amount "Points amount"
        string type "earn | redeem"
        string awardedBy FK "Club owner or system"
        timestamp createdAt
    }

    %% Voucher System
    Vouchers {
        string id PK
        string clubId FK
        string createdBy FK
        string title
        string description
        string type "fitness | stuff"
        double amount "CHF value"
        int pointsCost "Points required"
        boolean isActive
        string clubName "Denormalized"
        timestamp createdAt
        timestamp updatedAt
        string purchasedBy FK
        timestamp purchasedAt
        timestamp expiresAt "1 year from purchase"
        timestamp usedAt
        string usedForBooking FK
        string code UK "Security code"
    }

    %% Notification System
    Notifications {
        string id PK
        string userId FK
        string type "bookingReminder | bookingCancellation | activityUpdate"
        string title
        string body
        timestamp timestamp
        boolean isRead
        string bookingId FK
        string activityId FK
        string activityName
    }

    %% Participant View Model (Composite)
    Participants {
        string id PK "Derived from bookingId"
        string userId FK
        string userName "From Users collection"
        string userEmail "From Users collection"
        string activityId FK
        string activityTitle
        timestamp activityDate
        string activityTime
        timestamp bookingDate
        string status
        int participantCount
        double amountPaid
        int pointsEarned
        boolean isMemberBooking
        string confirmationNumber
        string phoneNumber "Optional from Users"
        string notes "Optional"
    }

    %% Relationships
    Users ||--o{ Clubs : "owns (isClubOwner)"
    Users ||--o{ Activities : "creates"
    Users ||--o{ Bookings : "makes"
    Users ||--|| UserBookings : "has subcollection"
    Users ||--|| UserRewardsLedger : "has subcollection"
    Users ||--o{ Vouchers : "purchases"
    Users ||--o{ Notifications : "receives"

    Clubs ||--o{ Facilities : "contains"
    Clubs ||--o{ Activities : "hosts"
    Clubs ||--o{ Vouchers : "offers"

    Facilities ||--o{ Activities : "hosts"

    Activities ||--o{ Bookings : "receives"
    Activities ||--o{ Participants : "has (view)"

    Bookings ||--|| UserBookings : "synced to subcollection"
    Bookings ||--o| UserRewardsLedger : "generates points entry"
    Bookings ||--o| Vouchers : "can use"

    %% Notes on Data Architecture
    %% 1. Users collection is the primary user store
    %% 2. UserBookings and UserRewardsLedger are subcollections for user-specific queries
    %% 3. Bookings is the main collection for cross-user booking management
    %% 4. Participants is a composite view model, not a stored collection
    %% 5. Denormalized fields (clubName, facilityName, etc.) improve query performance
    %% 6. Points flow: Activities → Bookings → UserRewardsLedger → User.availablePoints
    %% 7. Voucher lifecycle: Created → Purchased → Used/Expired
```

### Firestore Collections Schema

### Users Collection (`/users/{userId}`)

```javascript
{
  "uid": "firebase-user-id",
  "email": "nina.huber@protonmail.ch",
  "displayName": "Nina Huber",

  // Account lifecycle
  "createdAt": Timestamp,
  "lastLoginAt": Timestamp,
  "isActive": true,

  // Role-based access control
  "role": "user",                       // "user" | "admin"
  "isClubOwner": false,

  // Points and rewards system
  "totalPoints": 0,
  "availablePoints": 3525,              // Current spendable points
  "lifetimePointsEarned": 0,

  // Membership system
  "isMember": false,
  "membershipType": null,
  "membershipExpiry": null

   // Notifications
  "notificationPreferences": {
    "method": "inApp", // "email" | "inApp"
    "reminderHoursBefore": 2
  }
}
```

#### Bookings Subcollection of User (`/users/{userId}/bookings/{bookingId}`)

```javascript
{
  "activityId": "R5wfYrqrc5ywEyscbJE4",      // Reference to the activity
  "bookingDate": Timestamp,
  "bookingId": "3KnjEK2NnhEpRbcIrg3h",
  "createdAt": Timestamp,
  "status": "confirmed",                     // "confirmed" | "cancelled" | "completed" | "waitlist"

  // Additional fields (inferred from main bookings collection)
  "activityTitle": "CrossFit Bootcamp",     // Activity name for display
  "participantCount": 1,
  "totalPrice": 25.00,
  "pointsEarned": 45,
  "pointsUsed": 0,
  "isMemberBooking": false,
  "confirmationNumber": "ABC123DEF"         // Booking reference number
}
```

#### Rewards Ledger Subcollection of User (`/users/{userId}/rewards_ledger/{ledgerId}`)

```javascript
{
  "activityId": "R5wfYrqrc5ywEyscbJE4",     // Source activity reference
  "activityTitle": "CrossFit Bootcamp",
  "amount": 45,
  "awardedBy": "Xb7TUTqcxuQHagyhFm5ZtQlMaK42",
  "bookingId": "3KnjEK2NnhEpRbcIrg3h",
  "createdAt": Timestamp,
  "type": "earn"                          // "earn" | "redeem"
}
```

### Activities Collection (`/activities/{activityId}`)

```javascript
{
  "id": "activity-unique-id",
  "name": "Aqua Aerobic",
  "description": "Low-impact water aerobics for fitness and rehabilitation",
  "category": "Wellness",
  "clubId": "vdEABmPpX4UwzBLKNIG",
  "clubName": "Aquatica Basel",
  "facilityId": "6Eb7TGVALSOVpZ4zrGGE",
  "facilityName": "Olympisches Schwimmbecken",
  "date": "2025-12-22T18:27:43.855Z",
  "time": "08:00",
  "duration": 45,
  "timeCategory": "morning",
  "capacity": 30,
  "bookedCount": 15,
  "guestPrice": 30,
  "memberPrice": 22,
  "pointsReward": 30,
  "allowVouchers": true,
  "requirements": ["Swimwear", "Water shoes (optional)"],
  "imageUrl": "https://images.unsplash.com/photo-1560659925966421...",
  "createdAt": "2025-10-19T18:27:43.855Z",
  "updatedAt": "2025-11-05T18:27:43.855Z",
  "createdBy": "ZbWDTepVuxMyCckUxnE3qUp13"
}
```

### Bookings Collection (`/bookings/{bookingId}`)

```javascript
{
  "id": "booking-unique-id",
  "activityId": "4SoxMRquvVgMDSKJEuw",
  "userId": "PnqMPxxngN7uzR6vgklMEqg4xY2",
  "activityTitle": "HIIT Power Session",
  "activityDate": Timestamp,
  "activityTime": "08:15",
  "bookingDate": Timestamp,
  "status": "confirmed", // "pending" | "confirmed" | "cancelled" | "completed" | "waitlist"
  "clubId": "dZHkonWHIBwOzvJLrG",
  "clubName": "FitnessPlius Zürich",
  "facilityId": "NyS5RuLWKnznGfZehTS",
  "facilityName": "Hauptfitness Studio",
  "participantCount": 1,
  "totalPrice": 30,
  "amountPaid": 30,
  "pointsEarned": 0,
  "isMemberBooking": true,
  "confirmationNumber": "SC7Z14",
  "createdAt": Timestamp,
  "timeSlotId": null,
  "cancellationReason": null,
  "cancelledAt": null,
  "metadata": null,
  "voucherId": null,
  "voucherDiscount": null
}
```

### Clubs Collection (`/clubs/{clubId}`)

```javascript
{
  "name": "ZenFlow Wellness Bern",
  "ownerId": "YrnaGTNVZ3jNMm7LpoZRLPGfG2",
  "location": "Kramgasse 88, 3011 Bern",
  "isActive": true,
  "isApproved": true,
  "createdAt": Timestamp,
  "blockedTimes": []
}
```

### Facility Collection (`/facility/{facilityId}`)

```javascript
{
  "clubId": "VdEABmPpX4UwzBLKNIG",
  "title": "Olympisches Schwimmbecken",
  "description": "50-meter Olympic standard pool for serious swimmers and competitions",
  "maxCapacity": 40,
  "imageUrl": "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=300&h=200&fit=crop",
  "isActive": true,
  "createdAt": "2025-08-21T19:27:20.583Z",
  "updatedAt": "2025-11-05T18:27:20.583Z",
  "blockedTimes": []
}
```

### Notifications Collection (/notifications/{notificationId})

```javascript
{
  "userId": "user-reference-id",
  "type": "bookingReminder", // "bookingReminder" | "bookingCancellation"
  "title": "Booking Reminder",
  "body": "Your yoga class starts in 2 hours at Studio A",
  "timestamp": Timestamp,
  "isRead": false,
  "bookingId": "booking-reference-id",
  "activityName": "Morning Yoga Class"
}
```

### Vouchers Collection (`/vouchers/{voucherId}`)

```javascript
{
  "clubId": "club-reference-id",
  "createdBy": "club-owner-uid",
  "title": "5 CHF Fitness Voucher",
  "description": "Discount voucher for fitness activities. Valid for 1 year from purchase.",
  "type": "fitness", // "fitness" | "stuff"
  "amount": 5.00,
  "pointsCost": 500,
  "isActive": true,
  "clubName": "Downtown Fitness Center",
  "createdAt": Timestamp,
  "updatedAt": Timestamp,

  // Purchase lifecycle (null until purchased)
  "purchasedBy": "user-id",
  "purchasedAt": Timestamp,
  "expiresAt": Timestamp, // 1 year from purchase

  // Usage lifecycle (null until used)
  "usedAt": Timestamp,
  "usedForBooking": "booking-reference-id",

  // Security
  "code": "SC-V-2025-1234"
}
```

### Participant (View Model - Not a Collection)

The `Participant` class is a composite model that merges:

Booking data from `/bookings/{bookingId}`
User data from `/users/{userId}`
Purpose: Provides club owners and admins with a unified view of activity participants without needing separate database queries.

Data Source: Created dynamically by calling `Participant.fromFirestore(bookingDoc, userData)` where:

- `bookingDoc` comes from the bookings collection
- `userData` comes from the users collection

### Data Flow

1. **User Registration**: Creates user document with default points and notification preferences
2. **Club Registration**: Club owners create clubs (pending admin approval) with facilities
3. **Activity Creation**: Club owners create activities linked to approved clubs and facilities
4. **Booking Process**: Creates booking in both main collection and user subcollection, updates activity capacity
5. **Activity Completion**: Club owners mark participants as completed, awards points to users, creates rewards ledger entry
6. **Voucher Lifecycle**: Users purchase vouchers with points → redeem during booking → voucher marked as used
7. **Notification Flow**: System sends booking reminders and updates based on user preferences
8. **Real-time Updates**: Firestore snapshots update UI automatically across all connected clients

#### Key Workflows:

**Points Economy Flow:**

- Activity completion → Points awarded → User purchases vouchers → Voucher used for booking discount

**Club Owner Management Flow:**

- Create club → Admin approval → Add facilities → Create activities → Manage participants → Mark completions

**Booking Lifecycle:**

- Browse activities → Authentication check → Booking creation → Confirmation → Activity attendance → Completion (points awarded)

**Admin Oversight Flow:**

- Approve clubs → Monitor activities → Manage users → System analytics → Data seeding

## 4. Installation & Setup

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK (included with Flutter)
- Firebase CLI tools
- Node.js 18+ (for Cloud Functions)
- Android Studio / Xcode for mobile development
- Chrome browser for web development

### Step-by-Step Setup

#### 1. Clone and Install Dependencies

```bash
git clone https://github.com/Comicalist/SportCentreApp.git
cd sport_centre_booking
flutter pub get
```

#### 2. Firebase Project Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init

# Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

#### 3. Environment Configuration

Create `.env` file in project root:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=sport-centre-booking-b96ce
FIREBASE_API_KEY=AIzaSyDXo9zB1VQ239vCgzWpwhwcuwEfV5YwNMU
FIREBASE_AUTH_DOMAIN=sportcentreapp.firebaseapp.com
FIREBASE_STORAGE_BUCKET=sportcentreapp.firebasestorage.app
```

#### 4. Firebase Rules Configuration

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules
```

#### 5. Run the Application

```bash
# Web development
flutter run -d chrome

# Android development
flutter run -d android

# iOS development
flutter run -d ios

# Release build
flutter build apk --release
```

### Initial Data Setup

```bash
# Access admin panel in app and run seeding tools
# Or manually create test data in Firebase Console
```

## 5. API Documentation

### Firebase Authentication Endpoints

#### User Registration

```dart
// AuthService.registerWithEmail()
Future<UserCredential?> registerWithEmail(
  String email,
  String password,
  String displayName, {
  bool isClubOwner = false,
})
```

#### User Login

```dart
// AuthService.signInWithEmail()
Future<UserCredential?> signInWithEmail(
  String email,
  String password,
)
```

### Firestore API Operations

#### Activity Management

```dart
// Get all activities
Stream<List<Activity>> getActivities({
  String? category,
  DateTime? startDate,
  bool? availableOnly,
})

// Create activity (club owners only)
Future<String> createActivity(Activity activity, String currentUserId)

// Update activity
Future<void> updateActivity(Activity activity, String currentUserId)

// Delete activity
Future<void> deleteActivity(String activityId, String clubId, String currentUserId)
```

#### Booking Management

```dart
// Create booking
Future<String> createBooking({
  required String activityId,
  required String userId,
  int pointsToUse = 0,
  int participantCount = 1,
  String? notes,
})

// Get user bookings
Stream<List<Booking>> getUserBookings(String userId)

// Cancel booking
Future<void> cancelBooking(String bookingId, String userId)

// Update booking status
Future<void> updateBookingStatus(String bookingId, BookingStatus status)

// Club owner completion method
Future<bool> markUserBookingCompleted(String bookingId)

// Enhanced authorization checking
Future<bool> hasClubOwnerAccess(String activityId, String userId)

// Participant management
Stream<List<Participant>> getActivityParticipants(String activityId)
```

### Example API Responses

#### Activity List Response

```json
{
  "activities": [
    {
      "id": "activity-123",
      "title": "Morning Yoga",
      "category": "wellness",
      "price": 15.0,
      "startTime": "2024-01-15T09:00:00Z",
      "capacity": 12,
      "bookedCount": 8,
      "isAvailable": true
    }
  ]
}
```

#### Booking Creation Response

```json
{
  "bookingId": "booking-456",
  "confirmationNumber": "ABC123DEF",
  "status": "confirmed",
  "totalPrice": 10.0,
  "pointsEarned": 25,
  "pointsUsed": 50
}
```

## 6. Configuration & Deployment

### Environment Structure

- **Development**: Local Flutter development with Firebase emulators
- **Staging**: Firebase project with test data for QA testing
- **Production**: Live Firebase project with production data

### Build Commands

```bash
# Development build
flutter run --debug

# Release builds
flutter build apk --release
flutter build ios --release
flutter build web --release

# Firebase deployment
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules
```

### Secrets Management

- Firebase configuration keys stored in environment variables
- API keys managed through Firebase project settings
- Sensitive data encrypted in Firebase security rules

## 7. Codebase Structure

### Folder Layout

```
lib/
├── main.dart                           # App entry point & configuration
├── firebase_options.dart               # Firebase configuration
├── config/                             # Configuration files
│   └── firebase_config.dart            # Firebase settings
├── models/                             # Data models
│   ├── activity.dart                   # Activity entity
│   ├── app_notification.dart           # Notification model
│   ├── app_user.dart                   # User profile entity
│   ├── booking.dart                    # Booking entity
│   ├── club.dart                       # Club entity
│   ├── facility.dart                   # Facility entity
│   ├── notification_preferences.dart   # User notification settings
│   ├── participant.dart                # Participant view model
│   └── voucher.dart                    # Voucher/rewards entity
├── services/                           # Business logic & Firebase integration
│   ├── activity_service.dart           # Activity CRUD operations
│   ├── auth_service.dart               # Authentication operations
│   ├── blocking_service.dart           # Time blocking management
│   ├── booking_service.dart            # Booking management
│   ├── club_service.dart               # Club management
│   ├── facility_service.dart           # Facility management
│   ├── image_upload_service.dart       # File upload handling
│   ├── notification_service.dart       # Notification management
│   ├── participant_service.dart        # Admin participant management
│   └── voucher_service.dart            # Voucher operations
├── providers/                          # State management
│   ├── auth_provider.dart              # Authentication state
│   └── booking_provider.dart           # Booking state & flow
├── screens/                            # UI screens
│   ├── admin/                          # Admin panel
│   ├── auth/                           # Login/register/verification
│   ├── booking/                        # Booking management
│   ├── club_owner/                     # Club management
│   ├── facilities/                     # Facility management
│   ├── home/                           # Public activity browsing
│   ├── profile/                        # User profile
│   └── rewards.dart                    # Points and vouchers
├── widgets/                            # Reusable UI components
│   ├── activity/                       # Activity display components
│   ├── auth/                           # Authentication widgets
│   ├── common/                         # Shared UI components
│   ├── navigation/                     # Navigation components
│   ├── notifications/                  # Notification widgets
│   └── profile/                        # Profile-related widgets
└── utils/                              # Helper functions & constants
    ├── activity_helpers.dart           # Activity utility functions
    ├── colors.dart                     # Color scheme
    ├── constants.dart                  # App-wide constants
    ├── debug_clubs.dart                # Development debugging tools
    ├── sample_data_seeder.dart         # Data seeding utilities
    ├── update_bookings_with_user_info.dart # Migration script
    └── validation_utils.dart           # Input validation helpers

firestore.rules                        # Database security rules
firestore.indexes.json                 # Database indexes
firebase.json                          # Firebase project configuration
```

### Naming Conventions

- **Files**: snake_case (e.g., `activity_service.dart`)
- **Classes**: PascalCase (e.g., `ActivityService`)
- **Variables**: camelCase (e.g., `activityList`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_CAPACITY`)
- **Private members**: Leading underscore (e.g., `_firestore`)

## 8. Business Logic & Core Features

### Activity Booking Workflow

1. **User browses activities**: Public access to activity listings with real-time availability
2. **Authentication check**: Anonymous users prompted to register/login before booking
3. **Booking validation**: Check activity capacity, user eligibility, and payment options
4. **Payment processing**: Calculate pricing with member discounts and points redemption
5. **Booking confirmation**: Create booking record, update activity capacity, send notifications
6. **Points award**: Add points to user account based on activity completion

### Real-time Capacity Management

- Firestore transactions ensure atomic booking operations
- Activity capacity updated immediately upon booking/cancellation
- Waitlist functionality for fully booked activities
- Automatic capacity restoration on booking cancellations

### Club Owner Activity Management

- Only approved clubs can create activities
- Activities must be linked to active facilities owned by the club
- Capacity validation against facility maximum capacity
- Automatic activity categorization and time-based filtering

### Club Owner Booking Management

- **Participant Management**: Club owners can view all participants for their activities through `ActivityParticipantsScreen`
- **Status Management**: Real-time filtering and status updates (confirmed, pending, cancelled, completed, waitlist)
- **Points Award Authorization**: Club owners can mark bookings as completed using `BookingService.markUserBookingCompleted()` which:
  - Validates club ownership authorization
  - Awards points to participants automatically
  - Creates audit trail with `awardedBy` field
  - Updates user's `availablePoints` and `lifetimePointsEarned`

### Admin Oversight Features

- Club approval workflow for new businesses
- Participant management with real-time status updates
- System analytics and reporting capabilities
- Data seeding tools for testing and development

### Notification & Reminder System

- **Booking Reminders**: Automated reminders sent based on user preferences (2 hours before by default)
- **Status Updates**: Real-time notifications for booking confirmations, cancellations, and completions
- **Delivery Methods**: In-app notifications and email notifications via Cloud Functions
- **Testing Infrastructure**: Debug panel for testing notification workflows in development
- **Cron Jobs**: Scheduled functions for periodic reminder processing

### Voucher & Discount System

- **Voucher Types**: Fitness vouchers and merchandise/stuff vouchers
- **Conversion Rate**: 100 points = 1 CHF (as seen in voucher_management_screen.dart)
- **Voucher Lifecycle**: Purchase with points → Active voucher → Booking discount → Used/Expired
- **Club-specific Vouchers**: Each club can create their own voucher offerings
- **Booking Integration**: Vouchers can be applied during booking to reduce total cost

### Development & Testing Infrastructure

- **Swiss-localized Data**: Comprehensive seeding with CHF pricing and Swiss locations
- **Multi-role Testing**: Automated creation of admin, club owner, and member accounts
- **Realistic Scenarios**: 80+ activities across 2 months with proper scheduling
- **Credential Management**: Secure test account generation with role-based access
- **Migration Tools**: Scripts for updating existing data structures during development

## 9. Security & Privacy

### Authentication & Authorization

- **Firebase Authentication**: Secure email/password authentication with email verification
- **Role-based access control**: Users, club owners, and administrators with different permissions
- **JWT tokens**: Automatic token management through Firebase SDK
- **Session management**: Secure session handling with automatic token refresh

### Firestore Security Rules

The complete Firestore security rules are defined in [firestore.rules](firestore.rules). Key security features include:

- **Role-based access control**: Users, club owners, and administrators with different permissions
- **Resource ownership**: Users can only access their own data unless they have elevated permissions
- **Club owner authorization**: Club owners can manage activities and participants for their clubs only

### Data Protection

- **PII encryption**: Sensitive user data protected through Firebase security
- **GDPR compliance**: User data deletion and export capabilities
- **Audit trails**: All booking and profile changes logged with timestamps
- **Access logging**: Admin actions tracked for security monitoring

### Secure Coding Practices

- **Input validation**: All user inputs validated on client and server side
- **SQL injection prevention**: Firestore NoSQL structure prevents injection attacks
- **XSS protection**: Flutter framework provides automatic XSS protection
- **Secure file uploads**: Image uploads validated for file type and size limits

## 10. Maintenance & Monitoring

### Logging & Monitoring

```dart
// Application-wide logging
final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

// Usage throughout app
logger.i('User successfully logged in');
logger.w('Activity capacity approaching limit');
logger.e('Booking creation failed', error: e, stackTrace: stackTrace);
```

### Firebase Monitoring

- **Performance Monitoring**: Automatic performance tracking through Firebase
- **Crashlytics**: Crash reporting and analytics for production issues
- **Analytics**: User behavior tracking and conversion funnel analysis
- **Remote Config**: Feature flags and A/B testing capabilities

### Error Tracking

```dart
// Custom exception handling
class BookingException implements Exception {
  final String message;
  final String code;
  BookingException(this.message, this.code);
}

// Error boundaries in UI
Widget build(BuildContext context) {
  return FutureBuilder<List<Activity>>(
    future: _loadActivities(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        logger.e('Failed to load activities', error: snapshot.error);
        return ErrorWidget('Unable to load activities. Please try again.');
      }
      // ... success handling
    },
  );
}
```

## 12. Contributors & Contact

### Main Contributors

- Léon Ehrwein
- Jehu Enberg
- Yohann Charbonnet
- Tu Nguyen
- Nadja Lötscher

### Documentation Maintenance

- **Last Updated**: November 2025
- **Version**: 1.0.5
