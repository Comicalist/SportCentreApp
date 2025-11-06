import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // for logger

/// Debug script to check clubs data
Future<void> debugClubs() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    logger.w('No authenticated user for debug clubs');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  // Get ALL clubs
  try {
    final allClubsSnapshot = await firestore.collection('clubs').get();
    logger.i('Total clubs in database: ${allClubsSnapshot.docs.length}');

    for (final doc in allClubsSnapshot.docs) {
      final data = doc.data();
      logger
          .d('Club ${doc.id}: ${data['name']} (approved: ${data['isApproved']})');
    }
  } catch (e) {
    logger.e('Error fetching all clubs: $e');
  }

  // Get clubs by ownerId
  try {
    final ownerClubsSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    logger.i('Clubs owned by current user: ${ownerClubsSnapshot.docs.length}');

    for (final doc in ownerClubsSnapshot.docs) {
      final data = doc.data();
      logger.d('Owned club ${doc.id}: ${data['name']}');
    }
  } catch (e) {
    logger.e('Error fetching owned clubs: $e');
  }

  // Get approved clubs by ownerId (simple query)
  try {
    final approvedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .get();
    logger.i('Approved clubs owned by current user: ${approvedSnapshot.docs.length}');

    for (final doc in approvedSnapshot.docs) {
      final data = doc.data();
      logger.d('Approved club ${doc.id}: ${data['name']}');
    }
  } catch (e) {
    logger.e('Error fetching approved clubs: $e');
  }

  try {
    final activeApprovedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();
    logger.i('Active approved clubs owned by current user: ${activeApprovedSnapshot.docs.length}');

    for (final doc in activeApprovedSnapshot.docs) {
      final data = doc.data();
      logger.d('Active approved club ${doc.id}: ${data['name']}');
    }
  } catch (e) {
    logger.e('Error fetching active approved clubs: $e');
  }
}
