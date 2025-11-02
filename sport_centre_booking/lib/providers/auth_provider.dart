import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initAuthListener();
  }
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;

  // NEW: Admin check
  bool get isAdmin => _appUser?.isAdmin ?? false;

  // NEW: Club owner check
  bool get isClubOwner => _appUser?.isClubOwner ?? false;

  /// Initialize authentication state listener
  void _initAuthListener() {
    AuthService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // User is signed in, load user data
        await _loadUserData(user.uid);
        await AuthService.updateLastLogin();
      } else {
        // User is signed out
        _appUser = null;
      }

      notifyListeners();
    });
  }

  /// Load user data from Firestore (create it if missing)
  Future<void> _loadUserData(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Always try to get the latest version from the server first
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await docRef.get(const GetOptions(source: Source.server));
      } catch (e) {
        // If offline or fails, fallback to cache
        // Server fetch failed, fall back to cache
        doc = await docRef.get(const GetOptions(source: Source.cache));
      }

      // If the document doesn't exist, create it
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
          'isClubOwner': false, // Add default value
        }, SetOptions(merge: true));

        // Fetch again from server after creation
        doc = await docRef.get(const GetOptions(source: Source.server));
      }

      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc);

        notifyListeners();
        return;
      }

      // Fallback minimal
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
      // Error loading user data - will retry on next auth state change
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    return _performAuthAction(() async {
      await AuthService.signInWithEmail(email, password);
      return true;
    });
  }

  /// Register new user - UPDATED with isClubOwner parameter
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
        isClubOwner: isClubOwner, // Pass the parameter to AuthService
      );
      final uid = cred?.user?.uid;
      if (uid != null) {
        await _loadUserData(uid);
        await AuthService.updateLastLogin();
      }
      return true;
    });
  }

  /// Sign out current user
  Future<bool> signOut() async {
    return _performAuthAction(() async {
      await AuthService.signOut();
      return true;
    });
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    return _performAuthAction(() async {
      await AuthService.resetPassword(email);
      return true;
    });
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return _performAuthAction(() async {
      await AuthService.sendEmailVerification();
      return true;
    });
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => AuthService.isEmailVerified;

  /// Reload user to check verification status
  Future<void> checkEmailVerification() async {
    await AuthService.reloadUser();
    notifyListeners();
  }

  /// Helper method to perform auth actions with loading and error handling
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

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user display name or fallback
  String get userDisplayName {
    if (_appUser?.displayName.isNotEmpty ?? false) {
      return _appUser!.displayName;
    }
    if (_firebaseUser?.displayName?.isNotEmpty ?? false) {
      return _firebaseUser!.displayName!;
    }
    return _firebaseUser?.email?.split('@')[0] ?? 'User';
  }

  /// Get user first name for greetings
  String get userFirstName {
    if (_appUser != null) {
      return _appUser!.firstName; // Now uses the getter from AppUser
    }
    return userDisplayName.split(' ')[0];
  }
}
