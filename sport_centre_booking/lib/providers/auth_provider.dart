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
  bool get isAnonymous => _firebaseUser?.isAnonymous == true;

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

  /// Load user data from Firestore (create it if missing)
  Future<void> _loadUserData(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // 1) Forcer un aller-serveur (pas seulement le cache local)
      var doc = await docRef.get(const GetOptions(source: Source.server));

      // 2) Si le doc n'existe pas (race sign-up), le créer sur le champ
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
        }, SetOptions(merge: true));

        // Relecture en forçant le serveur (évite un cache vide)
        doc = await docRef.get(const GetOptions(source: Source.server));
      }

      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc);
        return;
      }

      // 3) Fallback minimal si, pour une raison X, on n'a toujours rien
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        _appUser = AppUser(
          uid: fUser.uid,
          email: fUser.email ?? '',
          displayName: fUser.displayName ?? (fUser.email?.split('@').first ?? 'User'),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        return;
      }
    } catch (e) {
      // En cas d'erreur (souvent règles Firestore), on trace et on met un fallback
      debugPrint('Error loading user data: $e');

      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        _appUser = AppUser(
          uid: fUser.uid,
          email: fUser.email ?? '',
          displayName: fUser.displayName ?? (fUser.email?.split('@').first ?? 'User'),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
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
      final cred =
          await AuthService.registerWithEmail(email, password, displayName);
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
