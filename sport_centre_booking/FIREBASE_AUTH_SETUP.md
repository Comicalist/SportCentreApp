# Firebase Authentication Setup Guide

## Step 1: Enable Email/Password Authentication in Firebase Console

1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project: `sport-centre-booking`
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Email/Password** and enable it
5. Save the changes

## Step 2: Configure Firestore Database

1. Go to **Firestore Database** in your Firebase Console
2. If not already created, create a Firestore database in production mode
3. Update your Firestore security rules to allow authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow all users to read activities (anonymous browsing)
    match /activities/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Only authenticated users can manage bookings
    match /bookings/{document} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## Step 3: Test the Authentication Flow

1. Run your Flutter app: `flutter run`
2. Try browsing activities as an anonymous user
3. Click "Book Now" on any activity - you should see the login prompt
4. Test the sign-up flow by creating a new account
5. Test the sign-in flow with your new account
6. Verify the personalized greeting appears when logged in

## Authentication Features Implemented

### ✅ Anonymous Browsing
- Users can view all activities without signing in
- Personalized greeting for authenticated users
- Generic message for anonymous users

### ✅ Email/Password Authentication
- Sign up with email, password, and display name
- Sign in with email and password
- Password reset functionality
- Email validation and password strength requirements

### ✅ Protected Booking
- Anonymous users see login prompt when trying to book
- Authenticated users can proceed with booking
- Smooth transition between auth states

### ✅ User Profile Management
- User document created in Firestore on registration
- Profile screen shows user info when authenticated
- Sign out functionality
- Auth options for non-authenticated users

### ✅ State Management
- Provider pattern for authentication state
- Real-time auth state updates across the app
- Proper error handling and loading states

## Error Handling

The app includes comprehensive error handling for:
- Invalid email formats
- Weak passwords
- Network connectivity issues
- Firebase Auth exceptions
- User-friendly error messages

## Security Features

- Passwords are never stored locally
- Firebase handles secure authentication
- Firestore security rules protect user data
- Email verification available (can be enabled)

## Next Steps

After setting up Firebase Authentication, you can:
1. Implement actual booking functionality
2. Add email verification requirements
3. Create admin roles and permissions
4. Add social authentication (Google, Facebook)
5. Implement the rewards/points system
6. Add push notifications for bookings

## Testing Accounts

For testing purposes, you can create test accounts:
- Email: test@example.com
- Password: test123

Remember to use real email addresses if you enable email verification.