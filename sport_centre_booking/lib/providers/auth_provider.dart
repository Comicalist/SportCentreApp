import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
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
  bool get isAnonymous => !isLoggedIn;

  AuthProvider() {
    _initAuthListener();
  }

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

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    return await _performAuthAction(() async {
      await AuthService.signInWithEmail(email, password);
      return true;
    });
  }

  /// Register new user
  Future<bool> register(String email, String password, String displayName) async {
    return await _performAuthAction(() async {
      await AuthService.registerWithEmail(email, password, displayName);
      return true;
    });
  }

  /// Sign out current user
  Future<bool> signOut() async {
    return await _performAuthAction(() async {
      await AuthService.signOut();
      return true;
    });
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    return await _performAuthAction(() async {
      await AuthService.resetPassword(email);
      return true;
    });
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return await _performAuthAction(() async {
      await AuthService.sendEmailVerification();
      return true;
    });
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
    if (_appUser?.displayName.isNotEmpty == true) {
      return _appUser!.displayName;
    }
    if (_firebaseUser?.displayName?.isNotEmpty == true) {
      return _firebaseUser!.displayName!;
    }
    return _firebaseUser?.email?.split('@')[0] ?? 'User';
  }

  /// Get user first name for greetings
  String get userFirstName {
    if (_appUser != null) {
      return _appUser!.firstName;
    }
    return userDisplayName.split(' ')[0];
  }
}