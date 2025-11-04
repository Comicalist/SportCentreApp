import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase authentication service for sport centre booking system
/// Handles user registration, login, email verification, and profile creation
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current authenticated user instance
  static User? get currentUser => _auth.currentUser;

  /// Real-time authentication state monitoring for UI updates
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Authentication status check for access control
  static bool get isLoggedIn => currentUser != null;

  /// Secure user login with session tracking and error handling
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      /// Track login activity for user analytics and security
      await updateLastLogin();

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// User registration with automatic profile creation and email verification
  /// Creates comprehensive user document with points system and membership defaults
  ///
  /// Parameters:
  /// - [email]: User's email address for authentication and communication
  /// - [password]: Secure password meeting validation requirements
  /// - [displayName]: User's full name for personalization
  /// - [isClubOwner]: Business flag for club management permissions (default: false)
  ///
  /// Returns [UserCredential] on success or throws detailed exception on failure
  static Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName, {
    bool isClubOwner = false,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user?.updateDisplayName(displayName.trim());
      await result.user?.reload();

      if (result.user != null) {
        await _createUserDocument(
          result.user!,
          displayName.trim(),
          isClubOwner: isClubOwner,
        );

        /// Automatic email verification for account security
        await result.user!.sendEmailVerification();
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Secure user logout with session cleanup
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  /// Password recovery via secure email link
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error sending password reset email. Please try again.';
    }
  }

  /// Email verification for account security and communication reliability
  static Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Error sending verification email. Please try again.';
    }
  }

  /// Email verification status for access control and user prompting
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Refresh user authentication data for real-time verification status
  /// Updates email verification status and other user properties from Firebase
  static Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      /// Silent failure - non-critical for app functionality
    }
  }

  /// Initialize comprehensive user profile in Firestore with business defaults
  /// Creates user document with points system, membership tracking, and booking history
  ///
  /// Parameters:
  /// - [user]: Firebase authenticated user instance
  /// - [displayName]: User's display name for personalization
  /// - [isClubOwner]: Business role flag for club management permissions
  static Future<void> _createUserDocument(
    User user,
    String displayName, {
    bool isClubOwner = false,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'role': 'user',
      'isActive': true,

      /// Points and rewards system initialization
      'totalPoints': 0,
      'availablePoints': 0,
      'lifetimePointsEarned': 0,

      /// Membership system defaults for upgrade tracking
      'isMember': false,
      'membershipType': null,
      'membershipExpiry': null,

      /// Business role flags for access control
      'isClubOwner': isClubOwner,

      /// Booking system integration and profile management
      'bookingHistory': [],
      'upcomingBookings': [],
      'profileImageUrl': '',
    }, SetOptions(merge: true));
  }

  /// Track user login activity for analytics and security monitoring
  static Future<void> updateLastLogin() async {
    final user = currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        /// Silent failure - non-critical for user experience
      }
    }
  }

  /// Convert Firebase authentication errors to user-friendly messages
  /// Provides localized error handling for better user experience
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
}
