import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling Firebase Authentication
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update last login
      await updateLastLogin();
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Register new user with email and password
  /// 
  /// Creates a new Firebase user account and automatically sends email verification.
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password (must meet validation requirements)
  /// - [displayName]: User's full name
  /// - [isClubOwner]: Optional flag to mark user as club owner (default: false)
  /// 
  /// Returns [UserCredential] on success or throws exception on failure.
  static Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName, {
    bool isClubOwner = false,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
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
        
        // Send email verification automatically
        await result.user!.sendEmailVerification();
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error sending password reset email. Please try again.';
    }
  }

  /// Send email verification
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

  /// Check if current user's email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reload current user to check verification status
  /// 
  /// Refreshes the current user's data from Firebase to get updated
  /// email verification status and other user properties.
  static Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      // Silently fail - not critical for app functionality
    }
  }

  /// Create user document in Firestore with default values
  /// 
  /// Creates a comprehensive user profile document in Firestore with
  /// default values for points, membership, and booking history.
  /// 
  /// Parameters:
  /// - [user]: Firebase user instance
  /// - [displayName]: User's display name
  /// - [isClubOwner]: Flag indicating if user is a club owner
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

      // Points and rewards system
      'totalPoints': 0,
      'availablePoints': 0,
      'lifetimePointsEarned': 0,
      
      // Membership system
      'isMember': false,
      'membershipType': null,
      'membershipExpiry': null,
      
      // User type flags
      'isClubOwner': isClubOwner,
      
      // Booking and profile data
      'bookingHistory': [],
      'upcomingBookings': [],
      'profileImageUrl': '',
    }, SetOptions(merge: true));
  }

  /// Update user's last login time
  static Future<void> updateLastLogin() async {
    final user = currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Silently fail - not critical for user experience
      }
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
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