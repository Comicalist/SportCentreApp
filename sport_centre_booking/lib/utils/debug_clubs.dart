import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug script to check clubs data
Future<void> debugClubs() async {

  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
  
    return;
  }
  
  
  
  final firestore = FirebaseFirestore.instance;
  
  // Get ALL clubs
  
  try {
    final allClubsSnapshot = await firestore.collection('clubs').get();
   
    for (var doc in allClubsSnapshot.docs) {
      final data = doc.data();
  
    }
  } catch (e) {
    
  }
  
  
  // Get clubs by ownerId

  try {
    final ownerClubsSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    print('   Count: ${ownerClubsSnapshot.docs.length}');
    for (var doc in ownerClubsSnapshot.docs) {
      final data = doc.data();
    
    }
  } catch (e) {
   
  }
 
  
  // Get approved clubs by ownerId (simple query)
  
  try {
    final approvedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .get();
   
    for (var doc in approvedSnapshot.docs) {
      final data = doc.data();
     
    }
  } catch (e) {

  }
  
  
  
  
  try {
    final activeApprovedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();
    
    for (var doc in activeApprovedSnapshot.docs) {
      final data = doc.data();
     
    }
  } catch (e) {
   
  }
 
  
 
}
