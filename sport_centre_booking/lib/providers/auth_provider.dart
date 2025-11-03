import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Central authentication state management with role-based access control
/// 
/// Manages Firebase Auth integration, user profile synchronization, and
/// role-based permissions (admin, club owner, member). Provides real-time
/// authentication state updates throughout the app.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initAuthListener();
  }

  // Authentication state
  User? _firebaseUser; // Firebase Auth user
  AppUser? _appUser; // Extended user profile from Firestore
  bool _isLoading = false;
  String? _errorMessage;

  // Core authentication getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;

  // Role-based access control
  bool get isAdmin => _appUser?.isAdmin ?? false;
  bool get isClubOwner => _appUser?.isClubOwner ?? false;

  /// Initialize real-time authentication state monitoring
  void _initAuthListener() {
    AuthService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // User signed in - load extended profile from Firestore
        await _loadUserData(user.uid);
        await AuthService.updateLastLogin();
      } else {
        // User signed out - clear profile data
        _appUser = null;
      }

      notifyListeners();
    });
  }

  /// Load or create user profile in Firestore with offline fallback
  Future<void> _loadUserData(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Attempt server-first fetch for latest data
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await docRef.get(const GetOptions(source: Source.server));
      } catch (e) {
        // Network issues - fallback to cached data
        doc = await docRef.get(const GetOptions(source: Source.cache));
      }

      // Create new user profile if doesn't exist
      if (!doc.exists) {
        final fUser = FirebaseAuth.instance.currentUser;
        await docRef.set({
          'uid': uid,
          'email': fUser?.email ?? '',
          'displayName': fUser?.displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'role': 'user',
          'isActive': true,
          'totalPoints': 0,
          'availablePoints': 0,
          'lifetimePointsEarned': 0,
          'isMember': false,
          'membershipType': null,
          'membershipExpiry': null,
          'isClubOwner': false,
        }, SetOptions(merge: true));

        // Fetch the newly created document
        doc = await docRef.get(const GetOptions(source: Source.server));
      }

      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc);
        notifyListeners();
        return;
      }

      // Emergency fallback - create minimal local profile
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        _appUser = AppUser(
          uid: fUser.uid,
          email: fUser.email ?? '',
          displayName:
              fUser.displayName ?? (fUser.email?.split('@').first ?? 'User'),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      // Silent failure - will retry on next auth state change
    }
  }

  /// Authenticate user with email and password
  Future<bool> signIn(String email, String password) async {
    return _performAuthAction(() async {
      await AuthService.signInWithEmail(email, password);
      return true;
    });
  }

  /// Register new user with optional club owner privileges
  Future<bool> register(
    String email,
    String password,
    String displayName, {
    bool isClubOwner = false,
  }) async {
    return _performAuthAction(() async {
      final cred = await AuthService.registerWithEmail(
        email,
        password,
        displayName,
        isClubOwner: isClubOwner,
      );
      final uid = cred?.user?.uid;
      if (uid != null) {
        await _loadUserData(uid);
        await AuthService.updateLastLogin();
      }
      return true;
    });
  }

  /// Sign out current user and clear state
  Future<bool> signOut() async {
    return _performAuthAction(() async {
      await AuthService.signOut();
      return true;
    });
  }

  /// Send password reset email to user
  Future<bool> resetPassword(String email) async {
    return _performAuthAction(() async {
      await AuthService.resetPassword(email);
      return true;
    });
  }

  /// Send email verification to current user
  Future<bool> sendEmailVerification() async {
    return _performAuthAction(() async {
      await AuthService.sendEmailVerification();
      return true;
    });
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => AuthService.isEmailVerified;

  /// Refresh user data to check verification status
  Future<void> checkEmailVerification() async {
    await AuthService.reloadUser();
    notifyListeners();
  }

  /// Standardized auth action wrapper with loading states and error handling
  Future<bool> _performAuthAction(Future<bool> Function() action) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await action();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message and notify listeners
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Public method to clear error state
  void clearError() {
    _clearError();
  }

  /// Internal error clearing
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user display name with intelligent fallbacks
  String get userDisplayName {
    if (_appUser?.displayName.isNotEmpty ?? false) {
      return _appUser!.displayName;
    }
    if (_firebaseUser?.displayName?.isNotEmpty ?? false) {
      return _firebaseUser!.displayName!;
    }
    return _firebaseUser?.email?.split('@')[0] ?? 'User';
  }

  /// Extract first name for personalized greetings
  String get userFirstName {
    if (_appUser != null) {
      return _appUser!.firstName;
    }
    return userDisplayName.split(' ')[0];
  }
}
