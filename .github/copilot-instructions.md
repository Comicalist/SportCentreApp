# Sport Centre Booking App - AI Coding Guidelines

## Project Overview
Comprehensive Flutter app for public sport centre booking with Firebase backend. Enables public access to club facilities, activity bookings, points rewards system, and admin management. Currently in early development with basic UI foundation.

## Business Requirements Context
- **Public Access**: Non-members can view and book activities with guest rates
- **Member Benefits**: Reduced rates and enhanced point earning for members
- **Points System**: Activities earn points convertible to cash vouchers
- **Admin Panel**: Club staff manage activities, block bookings, and facility availability
- **Real-time Booking**: Live availability, cancellations, and rescheduling
- **Notifications**: Email/push notifications for bookings and updates

## Architecture & Structure

### Core Models (`lib/models/`)
- **Activity**: Main entity with scheduling, pricing, capacity tracking, guest vs. member rates
- **Booking**: Links users to activities with status tracking (`confirmed`, `completed`, `cancelled`)  
- **UserProfile**: User data with points system, member status, and booking history
- **Resource**: Facilities (gym slots, yoga rooms, courts) for booking
- **BlockBooking**: Admin-managed recurring reservations (e.g., club training slots)
- All models follow consistent JSON serialization pattern with `fromJson()` and `toJson()`

### Planned Service Layer (`lib/services/`)
- **AuthService**: Public registration, member authentication, guest access
- **ActivityService**: CRUD operations, category filtering, availability checking
- **BookingService**: Real-time booking management, cancellations, waitlists
- **PointsService**: Earning, tracking, and voucher redemption logic
- **NotificationService**: Push notifications and email alerts
- **AdminService**: Club management, block booking, facility controls

### UI Design System
- Material 3 design with `ColorScheme.fromSeed(seedColor: Colors.teal)`
- Bottom navigation with 4 tabs: Activities, My Bookings, Rewards, Profile
- Category-based filtering with pill-shaped buttons (`All`, `Wellness`, `Fitness`, `Kids`, `Workshops`)
- Card-based layout for activities and bookings with rounded corners
- Status badges: `Confirmed` (teal), `Completed` (gray), colored category tags
- Points display with star icons and orange accent color
- Image loading from Unsplash with consistent aspect ratios

### Screen-Specific Patterns
**Club Activities (Home)**:
- Personalized greeting: "Welcome back, [Name]!"
- Horizontal scrolling category filters
- Activity cards with image, category tag, title, date/time, location, price, and points
- Availability indicators: "5 left" (green), "3 left" (orange), "1 left" (red)

**My Bookings**:
- Chronological list with booking type headers ("Activity Booking", "Resource Booking")
- Status badges and cancel buttons (X) for confirmed bookings
- Points earned display for completed activities
- Clean card layout with date, time, and price information

**Rewards**:
- Points balance prominently displayed with star icon
- Reward cards with category tags (`FOOD`, `MERCHANDISE`)
- Redemption flow with point cost and "Redeem" buttons
- Expiration dates for vouchers

## Development Workflow

### Key Commands
```bash
# Run the app
flutter run

# Get dependencies 
flutter pub get

# Run tests
flutter test

# Build for release
flutter build apk    # Android
flutter build ios    # iOS

# Firebase setup (if reconfiguring)
flutterfire configure
```

## Project-Specific Conventions

### State Management Strategy
- Currently uses StatefulWidget for local state in `HomeScreen`
- Provider package ready for implementation - use for:
  - User authentication state
  - Real-time booking data
  - Points and profile management
  - Admin panel state

### Data Models Pattern
- All models include both guest and member pricing fields
- Status enums: `BookingStatus` (`confirmed`, `waitlist`, `cancelled`, `completed`)
- Points calculation: Activity participation → points → cash voucher conversion
- Block booking conflicts: Check against `BlockBooking` model before allowing public bookings
- Reward categories: `FOOD`, `MERCHANDISE` with point costs and expiration dates
- Booking types: `Activity Booking`, `Resource Booking` with different UI treatments

### Screen Architecture Planning
```
lib/screens/
├── main_navigation.dart     # Bottom nav wrapper with 4 tabs
├── activities/             # Club Activities (home) - current HomeScreen
├── bookings/              # My Bookings - user's activity & resource bookings
├── rewards/               # Rewards & points redemption system
├── profile/               # User profile, settings, history
├── auth/                  # Login, registration, guest access
├── admin/                 # Club management panel (separate from main nav)
└── booking_flow/          # Activity/resource booking process
```

### Navigation Structure
**Bottom Navigation Tabs**:
1. **Activities** (Home): Browse and book activities/resources
2. **My Bookings**: View confirmed, completed, and upcoming bookings
3. **Rewards**: Points balance and voucher redemption
4. **Profile**: User account, settings, booking history

### Firebase Collections Structure
```
/activities         # Activity listings with capacity tracking
/bookings          # Individual user bookings
/users             # Public users + member profiles
/block_bookings    # Admin-managed recurring reservations
/points_history    # Points earning and redemption tracking
/notifications     # Push notification queue
```

## Integration Points

### Firebase Services Implementation Priority
1. **AuthService**: Guest access + member registration/login
2. **ActivityService**: Real-time availability with capacity tracking
3. **BookingService**: Conflict checking against block bookings, waitlist management
4. **AdminService**: Block booking management, facility controls
5. **NotificationService**: Booking confirmations, schedule changes, new events
6. **PointsService**: Activity completion tracking, voucher generation

### Critical Business Logic
- **Booking Conflicts**: Always check `BlockBooking` before allowing public reservations
- **Capacity Management**: Real-time spots tracking with waitlist functionality  
- **Dual Pricing**: Guest vs. member rates in all booking flows
- **Points Calculation**: Activity type → base points + member multiplier
- **Admin Overrides**: Allow releasing blocked slots back to public when needed

### External Dependencies
- Unsplash API for activity images (`https://images.unsplash.com/photo-{id}?w=300&h=200&fit=crop`)
- Email service for notifications (Firebase Functions + SendGrid/similar)
- Payment processing for bookings (Stripe/PayPal integration planned)

### Real-time Features Requirements
- Live activity availability updates
- Booking confirmation notifications
- Waitlist position updates
- Schedule change alerts
- Admin booking management

## Development Priorities
1. Complete core models: `Resource`, `BlockBooking`, expanded `Activity` with member pricing
2. Implement authentication with guest/member differentiation
3. Build booking conflict detection system
4. Create admin panel for block booking management  
5. Implement points system with voucher redemption
6. Add real-time availability updates
7. Build notification system for booking updates

## Code Quality Standards
- Flutter lints with custom rules for Firebase async patterns
- Null safety with proper error handling for booking conflicts
- Consistent status enums across all models
- Material 3 design with accessibility considerations