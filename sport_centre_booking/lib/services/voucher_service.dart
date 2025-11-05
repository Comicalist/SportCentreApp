import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voucher.dart';

/// Manages voucher lifecycle including creation, purchase, usage and analytics
/// Implements points-based discount system for sport centre activities
class VoucherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves active voucher templates available for purchase by club
  /// These are reusable templates - users can purchase them multiple times
  static Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .orderBy('clubName')
          .orderBy('amount')
          .get();

      return querySnapshot.docs.map(Voucher.fromFirestore).toList();
    } catch (e) {
      throw Exception('Failed to load available vouchers: $e');
    }
  }

  /// Retrieves user's purchased voucher instances ordered by purchase date
  /// These are in the user's subcollection, not the main vouchers collection
  static Future<List<Voucher>> getUserVouchers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_vouchers')
          .orderBy('purchasedAt', descending: true)
          .get();

      return querySnapshot.docs.map(Voucher.fromFirestore).toList();
    } catch (e) {
      throw Exception('Failed to load user vouchers: $e');
    }
  }

  /// Finds valid voucher instances for booking discounts at specific club
  /// Searches user's purchased vouchers that are unused and not expired
  static Future<List<Voucher>> getUsableVouchers(
    String userId,
    String clubId,
  ) async {
    try {
      // Fetch all user vouchers for the club and filter in memory
      // This avoids Firestore composite index limitations
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_vouchers')
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: VoucherType.fitness.value)
          .get();

      final now = DateTime.now();
      
      // Filter vouchers in memory to ensure accuracy
      final usableVouchers = querySnapshot.docs
          .map(Voucher.fromFirestore)
          .where((voucher) {
            // Must not be used
            if (voucher.usedAt != null) return false;
            
            // Must not be expired
            if (voucher.expiresAt != null && voucher.expiresAt!.isBefore(now)) {
              return false;
            }
            
            return true;
          })
          .toList();

      return usableVouchers;
    } catch (e) {
      throw Exception('Failed to load usable vouchers: $e');
    }
  }

  /// Retrieves all vouchers created by club for management dashboard
  static Future<List<Voucher>> getClubVouchers(String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('clubId', isEqualTo: clubId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Voucher.fromFirestore).toList();
    } catch (e) {
      throw Exception('Failed to load club vouchers: $e');
    }
  }

  /// Real-time stream of available voucher templates for marketplace updates
  /// Shows reusable templates - users can purchase same voucher multiple times
  static Stream<List<Voucher>> streamAvailableVouchers() {
    return _firestore
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final vouchers = snapshot.docs.map(Voucher.fromFirestore).toList();

          vouchers.sort((a, b) {
            final clubNameComparison = a.clubName.compareTo(b.clubName);
            if (clubNameComparison != 0) return clubNameComparison;
            return a.amount.compareTo(b.amount);
          });

          return vouchers;
        });
  }

  /// Real-time stream of user's purchased voucher instances for profile updates
  /// Streams from user's subcollection of purchased vouchers
  static Stream<List<Voucher>> streamUserVouchers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('user_vouchers')
        .snapshots()
        .map((snapshot) {
          final vouchers = snapshot.docs.map(Voucher.fromFirestore).toList();

          vouchers.sort(
            (a, b) =>
                b.purchasedAt?.compareTo(a.purchasedAt ?? DateTime.now()) ?? 0,
          );

          return vouchers;
        });
  }

  /// Executes voucher purchase transaction with points validation
  /// Creates a new voucher instance in user's subcollection - templates remain unchanged
  static Future<void> purchaseVoucher(String voucherId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get the voucher template (not modified)
        final voucherRef = _firestore.collection('vouchers').doc(voucherId);
        final voucherDoc = await transaction.get(voucherRef);

        if (!voucherDoc.exists) {
          throw Exception('Voucher not found');
        }

        final voucher = Voucher.fromFirestore(voucherDoc);

        if (!voucher.isActive) {
          throw Exception('This voucher is no longer available');
        }

        // Check user points
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User profile not found');
        }

        final userData = userDoc.data()!;
        final availablePoints = userData['availablePoints'] ?? 0;

        if (availablePoints < voucher.pointsCost) {
          throw Exception(
            'Insufficient points. You need ${voucher.pointsCost} points but only have $availablePoints.',
          );
        }

        // Create a new voucher instance in user's subcollection
        final voucherCode = Voucher.generateVoucherCode();
        final expirationDate = Voucher.calculateExpirationDate();
        final now = Timestamp.fromDate(DateTime.now());

        final userVoucherRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('user_vouchers')
            .doc(); // Generate new ID

        transaction.set(userVoucherRef, {
          'voucherTemplateId': voucherId, // Link to original template
          'clubId': voucher.clubId,
          'clubName': voucher.clubName,
          'title': voucher.title,
          'description': voucher.description,
          'type': voucher.type.value,
          'amount': voucher.amount,
          'pointsCost': voucher.pointsCost,
          'purchasedBy': user.uid,
          'purchasedAt': now,
          'expiresAt': Timestamp.fromDate(expirationDate),
          'code': voucherCode,
          'createdAt': now,
          'updatedAt': now,
          'isActive': true,
          'usedAt': null,
          'usedForBooking': null,
          'createdBy': voucher.createdBy,
        });

        // Deduct points from user
        final newAvailablePoints = availablePoints - voucher.pointsCost;
        transaction.update(userRef, {'availablePoints': newAvailablePoints});
      });
    } catch (e) {
      throw Exception('Failed to purchase voucher: $e');
    }
  }

  /// Marks voucher instance as used for booking discount application
  /// Operates on user's purchased voucher subcollection
  static Future<void> useVoucher(
    String userId,
    String voucherId,
    String bookingId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to use vouchers');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final voucherRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('user_vouchers')
            .doc(voucherId);
        final voucherDoc = await transaction.get(voucherRef);

        if (!voucherDoc.exists) {
          throw Exception('Voucher not found');
        }

        final voucher = Voucher.fromFirestore(voucherDoc);

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

  /// Creates new voucher template with automatic points cost calculation
  /// Templates do NOT include purchaser-related fields - those are added when purchased
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
      final pointsCost = (amount * 100).round();
      final now = DateTime.now();

      // Template data - NO purchaser-related fields
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
        // Do NOT include: purchasedBy, purchasedAt, expiresAt, usedAt, usedForBooking, code
      };

      final docRef = await _firestore.collection('vouchers').add(voucherData);

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

  /// Retrieves vouchers created by specific club owner for management
  static Future<List<Voucher>> getVouchersByClubOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('createdBy', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Voucher.fromFirestore).toList();
    } catch (e) {
      throw Exception('Failed to load vouchers by club owner: $e');
    }
  }

  /// Creates new voucher type template for club (legacy method)
  static Future<String> createVoucherType({
    required String clubId,
    required String createdBy,
    required VoucherType type,
    required String title,
    required String description,
    required double amount,
    required int pointsCost,
  }) async {
    try {
      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data()!;
      final clubName = clubData['name'] as String;

      final code = _generateVoucherCode();

      final voucherData = {
        'code': code,
        'clubId': clubId,
        'clubName': clubName,
        'createdBy': createdBy,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'pointsCost': pointsCost,
        'amount': amount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'purchasedBy': null,
        'purchasedAt': null,
        'usedAt': null,
        'usedForBooking': null,
        'expiresAt': null,
      };

      final docRef = await _firestore.collection('vouchers').add(voucherData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }

  /// Updates voucher properties for club management
  static Future<void> updateVoucher(
    String voucherId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('vouchers').doc(voucherId).update(data);
    } catch (e) {
      throw Exception('Failed to update voucher: $e');
    }
  }

  /// Removes unpurchased vouchers to prevent customer confusion
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

  /// Generates unique voucher code with year and timestamp
  static String _generateVoucherCode() {
    final now = DateTime.now();
    final year = now.year;
    final random = now.millisecondsSinceEpoch % 10000;
    return 'SC-V-$year-${random.toString().padLeft(4, '0')}';
  }

  /// Calculates voucher performance metrics for club analytics
  static Future<Map<String, dynamic>> getClubVoucherStats(String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vouchers')
          .where('clubId', isEqualTo: clubId)
          .get();

      var totalCreated = 0;
      var totalPurchased = 0;
      var totalUsed = 0;
      var totalRevenue = 0.0;

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
        'purchaseRate': totalCreated > 0
            ? (totalPurchased / totalCreated)
            : 0.0,
        'usageRate': totalPurchased > 0 ? (totalUsed / totalPurchased) : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get voucher statistics: $e');
    }
  }
}
