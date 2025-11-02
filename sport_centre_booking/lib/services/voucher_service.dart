import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voucher.dart';

/// Service for managing voucher operations
class VoucherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all available vouchers for purchase (not yet purchased)
  static Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .where('purchasedBy', isEqualTo: null)
          .orderBy('clubName')
          .orderBy('amount')
          .get();

      return querySnapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load available vouchers: $e');
    }
  }

  /// Get vouchers purchased by a specific user
  static Future<List<Voucher>> getUserVouchers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('purchasedBy', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user vouchers: $e');
    }
  }

  /// Get unused vouchers for a user that can be used for bookings
  static Future<List<Voucher>> getUsableVouchers(String userId, String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('purchasedBy', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: VoucherType.fitness.value)
          .where('usedAt', isEqualTo: null)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();

      return querySnapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load usable vouchers: $e');
    }
  }

  /// Get vouchers created by a club (for club owners)
  static Future<List<Voucher>> getClubVouchers(String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('clubId', isEqualTo: clubId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load club vouchers: $e');
    }
  }

  /// Stream of available vouchers for real-time updates
  static Stream<List<Voucher>> streamAvailableVouchers() {
    return _firestore
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .where('purchasedBy', isEqualTo: null)
        .snapshots()
        .map((snapshot) {
          final vouchers = snapshot.docs
              .map((doc) => Voucher.fromFirestore(doc))
              .toList();
          
          // Sort in memory to avoid index requirements
          vouchers.sort((a, b) {
            final clubNameComparison = a.clubName.compareTo(b.clubName);
            if (clubNameComparison != 0) return clubNameComparison;
            return a.amount.compareTo(b.amount);
          });
          
          return vouchers;
        });
  }

  /// Stream of user's vouchers for real-time updates
  static Stream<List<Voucher>> streamUserVouchers(String userId) {
    return _firestore
        .collection('vouchers')
        .where('purchasedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final vouchers = snapshot.docs
              .map((doc) => Voucher.fromFirestore(doc))
              .toList();
          
          // Sort in memory to avoid index requirements
          vouchers.sort((a, b) => b.purchasedAt?.compareTo(a.purchasedAt ?? DateTime.now()) ?? 0);
          
          return vouchers;
        });
  }

  /// Purchase a voucher with user's points
  static Future<void> purchaseVoucher(String voucherId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get current user
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get voucher document
        final voucherRef = _firestore.collection('vouchers').doc(voucherId);
        final voucherDoc = await transaction.get(voucherRef);

        if (!voucherDoc.exists) {
          throw Exception('Voucher not found');
        }

        final voucher = Voucher.fromFirestore(voucherDoc);

        // Check if voucher is available for purchase
        if (voucher.purchasedBy != null) {
          throw Exception('This voucher has already been purchased');
        }

        if (!voucher.isActive) {
          throw Exception('This voucher is no longer available');
        }

        // Get user document
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User profile not found');
        }

        final userData = userDoc.data()!;
        final availablePoints = userData['availablePoints'] ?? 0;

        // Check if user has enough points
        if (availablePoints < voucher.pointsCost) {
          throw Exception('Insufficient points. You need ${voucher.pointsCost} points but only have $availablePoints.');
        }

        // Generate voucher code and set purchase/expiration dates
        final voucherCode = Voucher.generateVoucherCode();
        final purchaseDate = DateTime.now();
        final expirationDate = Voucher.calculateExpirationDate();

        // Update voucher with purchase information
        transaction.update(voucherRef, {
          'purchasedBy': user.uid,
          'purchasedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expirationDate),
          'code': voucherCode,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Deduct points from user
        final newAvailablePoints = availablePoints - voucher.pointsCost;
        transaction.update(userRef, {
          'availablePoints': newAvailablePoints,
        });
      });
    } catch (e) {
      throw Exception('Failed to purchase voucher: $e');
    }
  }

  /// Use a voucher for a booking
  static Future<void> useVoucher(String voucherId, String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to use vouchers');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Get voucher document
        final voucherRef = _firestore.collection('vouchers').doc(voucherId);
        final voucherDoc = await transaction.get(voucherRef);

        if (!voucherDoc.exists) {
          throw Exception('Voucher not found');
        }

        final voucher = Voucher.fromFirestore(voucherDoc);

        // Verify voucher ownership and usability
        if (voucher.purchasedBy != user.uid) {
          throw Exception('You do not own this voucher');
        }

        if (voucher.isUsed) {
          throw Exception('Voucher has already been used');
        }

        if (voucher.isExpired) {
          throw Exception('Voucher has expired');
        }

        if (!voucher.canBeUsedForBookings) {
          throw Exception('This voucher cannot be used for bookings');
        }

        // Mark voucher as used
        transaction.update(voucherRef, {
          'usedAt': Timestamp.fromDate(DateTime.now()),
          'usedForBooking': bookingId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Failed to use voucher: $e');
    }
  }

  /// Create a new voucher (for club owners)
  static Future<Voucher> createVoucher({
    required String clubId,
    required String clubName,
    required String title,
    required String description,
    required VoucherType type,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to create vouchers');
    }

    try {
      // Calculate points cost (100 points = 1 CHF)
      final pointsCost = (amount * 100).round();
      final now = DateTime.now();

      final voucherData = {
        'clubId': clubId,
        'createdBy': user.uid,
        'title': title,
        'description': description,
        'type': type.value,
        'amount': amount,
        'pointsCost': pointsCost,
        'isActive': true,
        'clubName': clubName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'purchasedBy': null,
        'purchasedAt': null,
        'expiresAt': null,
        'usedAt': null,
        'usedForBooking': null,
        'code': null,
      };

      final docRef = await _firestore.collection('vouchers').add(voucherData);
      voucherData['id'] = docRef.id;

      return Voucher.fromJson({
        'id': docRef.id,
        ...voucherData,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }

  /// Get vouchers created by a specific club owner
  static Future<List<Voucher>> getVouchersByClubOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('createdBy', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vouchers by club owner: $e');
    }
  }

  /// Create a new voucher type (by club owner)
  static Future<String> createVoucherType({
    required String clubId,
    required String createdBy,
    required VoucherType type,
    required String title,
    required String description,
    required double amount,
    required int pointsCost,  // Changed from 'value' to 'pointsCost'
  }) async {
    try {
      // Get club information for denormalized data
      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }
      
      final clubData = clubDoc.data()!;
      final clubName = clubData['name'] as String;

      // Generate unique voucher code
      final code = _generateVoucherCode();

      final voucherData = {
        'code': code,
        'clubId': clubId,
        'clubName': clubName,
        'createdBy': createdBy,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'pointsCost': pointsCost,  // Changed from 'value' to 'pointsCost'
        'amount': amount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),  // Add updatedAt
        
        // Purchase info (null until purchased)
        'purchasedBy': null,
        'purchasedAt': null,
        
        // Usage info (null until used)
        'usedAt': null,
        'usedForBooking': null,
        'expiresAt': null, // Set when purchased
      };

      final docRef = await _firestore.collection('vouchers').add(voucherData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }

  /// Update voucher
  static Future<void> updateVoucher(String voucherId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('vouchers')
          .doc(voucherId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update voucher: $e');
    }
  }

  /// Delete voucher (only if not purchased)
  static Future<void> deleteVoucher(String voucherId) async {
    try {
      final doc = await _firestore.collection('vouchers').doc(voucherId).get();
      if (!doc.exists) {
        throw Exception('Voucher not found');
      }

      final voucher = Voucher.fromFirestore(doc);
      if (voucher.purchasedBy != null) {
        throw Exception('Cannot delete voucher that has been purchased');
      }

      await _firestore.collection('vouchers').doc(voucherId).delete();
    } catch (e) {
      throw Exception('Failed to delete voucher: $e');
    }
  }

  /// Generate unique voucher code
  static String _generateVoucherCode() {
    final now = DateTime.now();
    final year = now.year;
    final random = now.millisecondsSinceEpoch % 10000;
    return 'SC-V-$year-${random.toString().padLeft(4, '0')}';
  }

  /// Get voucher usage statistics for a club
  static Future<Map<String, dynamic>> getClubVoucherStats(String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('clubId', isEqualTo: clubId)
          .get();

      int totalCreated = 0;
      int totalPurchased = 0;
      int totalUsed = 0;
      double totalRevenue = 0.0;

      for (final doc in querySnapshot.docs) {
        final voucher = Voucher.fromFirestore(doc);
        totalCreated++;

        if (voucher.purchasedBy != null) {
          totalPurchased++;
          totalRevenue += voucher.amount;
        }

        if (voucher.isUsed) {
          totalUsed++;
        }
      }

      return {
        'totalCreated': totalCreated,
        'totalPurchased': totalPurchased,
        'totalUsed': totalUsed,
        'totalRevenue': totalRevenue,
        'purchaseRate': totalCreated > 0 ? (totalPurchased / totalCreated) : 0.0,
        'usageRate': totalPurchased > 0 ? (totalUsed / totalPurchased) : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get voucher statistics: $e');
    }
  }
}