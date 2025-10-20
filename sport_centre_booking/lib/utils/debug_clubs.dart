import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug script to check clubs data
Future<void> debugClubs() async {
  print('\n========== 🔍 DEBUG CLUBS ==========\n');
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return;
  }
  
  print('👤 Current User:');
  print('   UID: ${user.uid}');
  print('   Email: ${user.email}');
  print('');
  
  final firestore = FirebaseFirestore.instance;
  
  // Get ALL clubs
  print('📦 ALL CLUBS IN DATABASE:');
  try {
    final allClubsSnapshot = await firestore.collection('clubs').get();
    print('   Total count: ${allClubsSnapshot.docs.length}');
    for (var doc in allClubsSnapshot.docs) {
      final data = doc.data();
      print('   - ${data['name']}:');
      print('       ID: ${doc.id}');
      print('       ownerId: ${data['ownerId']}');
      print('       isApproved: ${data['isApproved']}');
      print('       isActive: ${data['isActive']}');
      print('       Match current user: ${data['ownerId'] == user.uid}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');
  
  // Get clubs by ownerId
  print('🏢 CLUBS BY OWNER ID (${user.uid}):');
  try {
    final ownerClubsSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    print('   Count: ${ownerClubsSnapshot.docs.length}');
    for (var doc in ownerClubsSnapshot.docs) {
      final data = doc.data();
      print('   - ${data['name']} (isApproved: ${data['isApproved']}, isActive: ${data['isActive']})');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');
  
  // Get approved clubs by ownerId (simple query)
  print('✅ APPROVED CLUBS BY OWNER (2 where clauses):');
  try {
    final approvedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .get();
    print('   Count: ${approvedSnapshot.docs.length}');
    for (var doc in approvedSnapshot.docs) {
      final data = doc.data();
      print('   - ${data['name']} (isActive: ${data['isActive']})');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  print('');
  
  // Get approved AND active clubs (3 where clauses - needs index)
  print('✅🟢 APPROVED AND ACTIVE CLUBS (3 where clauses):');
  try {
    final activeApprovedSnapshot = await firestore
        .collection('clubs')
        .where('ownerId', isEqualTo: user.uid)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();
    print('   Count: ${activeApprovedSnapshot.docs.length}');
    for (var doc in activeApprovedSnapshot.docs) {
      final data = doc.data();
      print('   - ${data['name']}');
    }
  } catch (e) {
    print('   ❌ Error (likely needs composite index): $e');
  }
  print('');
  
  print('========== END DEBUG ==========\n');
}
