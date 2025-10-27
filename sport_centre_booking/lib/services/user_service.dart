import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService extends ChangeNotifier { // Add extends ChangeNotifier
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserProfile? _currentUserProfile;
  
  UserProfile? get currentUser => _currentUserProfile;
  
  // Load user profile from Firestore
  Future<UserProfile?> loadUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserProfile = UserProfile(
          id: data['uid'] ?? userId,
          name: data['displayName'] ?? 'User',
          email: data['email'] ?? '',
          totalPoints: data['totalPoints'] ?? 0,
          bookingHistory: List<String>.from(data['bookingHistory'] ?? []),
          upcomingBookings: List<String>.from(data['upcomingBookings'] ?? []),
          profileImageUrl: data['profileImageUrl'] ?? '',
          joinDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          role: data['role'] ?? 'user',
        );
        notifyListeners();
        return _currentUserProfile;
      }
    } catch (e) {
      // Handle error if needed
    }
    return null;
  }
  
  // Clear user profile on logout
  void clearUserProfile() {
    _currentUserProfile = null;
    notifyListeners();
  }
  
  // Check if current user is admin
  bool get isAdmin => _currentUserProfile?.isAdmin ?? false;
}