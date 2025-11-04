import 'package:cloud_firestore/cloud_firestore.dart';

/// Voucher type enumeration
enum VoucherType {
  fitness,
  stuff
}

/// Extension to convert VoucherType to/from string
extension VoucherTypeExtension on VoucherType {
  String get value {
    switch (this) {
      case VoucherType.fitness:
        return 'fitness';
      case VoucherType.stuff:
        return 'stuff';
    }
  }

  static VoucherType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'fitness':
        return VoucherType.fitness;
      case 'stuff':
        return VoucherType.stuff;
      default:
        return VoucherType.fitness;
    }
  }
}

/// Voucher model for managing club vouchers
class Voucher {
  // === IDENTIFIERS & RELATIONSHIPS ===
  final String id;
  final String clubId;              // Reference to club that created this voucher
  final String createdBy;           // Admin user who created this voucher
  
  // === VOUCHER INFORMATION ===
  final String title;               // e.g., "5 CHF off Fitness Classes"
  final String description;         // Detailed description
  final VoucherType type;           // fitness or stuff
  final double amount;              // CHF value (e.g., 5.0)
  final int pointsCost;             // Points required to purchase (e.g., 500)
  final bool isActive;              // Can be purchased/used
  
  // === DENORMALIZED DATA ===
  final String clubName;            // Club name for display
  
  // === TIMESTAMPS ===
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // === PURCHASE & USAGE INFO (null until purchased) ===
  final String? purchasedBy;        // User ID who bought this voucher
  final DateTime? purchasedAt;      // When it was purchased
  final DateTime? expiresAt;        // Expiration date (1 year from purchase)
  
  // === USAGE INFO (null until used) ===
  final DateTime? usedAt;           // When it was used
  final String? usedForBooking;     // Booking ID where this voucher was used
  
  // === VOUCHER CODE (generated on purchase) ===
  final String? code;               // e.g., "SC-V-2024-1234"

  Voucher({
    required this.id,
    required this.clubId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.type,
    required this.amount,
    required this.pointsCost,
    this.isActive = true,
    required this.clubName,
    required this.createdAt,
    required this.updatedAt,
    this.purchasedBy,
    this.purchasedAt,
    this.expiresAt,
    this.usedAt,
    this.usedForBooking,
    this.code,
  });

  /// Check if voucher is available for purchase
  bool get isAvailableForPurchase => isActive && purchasedBy == null;

  /// Check if voucher is purchased but not used
  bool get isPurchasedAndUnused => purchasedBy != null && usedAt == null && !isExpired;

  /// Check if voucher is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if voucher is used
  bool get isUsed => usedAt != null;

  /// Check if voucher can be used for bookings
  bool get canBeUsedForBookings => type == VoucherType.fitness && isPurchasedAndUnused;

  /// Get status display text
  String get statusDisplayText {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    if (isPurchasedAndUnused) return 'Available';
    if (isAvailableForPurchase) return 'For Sale';
    return 'Inactive';
  }

  /// Generate voucher code (SC-V-YYYY-XXXX format)
  static String generateVoucherCode() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SC-V-$year-$random';
  }

  /// Calculate expiration date (1 year from now)
  static DateTime calculateExpirationDate() {
    return DateTime.now().add(const Duration(days: 365));
  }

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Voucher(
      id: doc.id,
      clubId: data['clubId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: VoucherTypeExtension.fromString(data['type'] ?? 'fitness'),
      amount: (data['amount'] ?? 0.0).toDouble(),
      pointsCost: data['pointsCost'] ?? 0,
      isActive: data['isActive'] ?? true,
      clubName: data['clubName'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      purchasedBy: data['purchasedBy'],
      purchasedAt: data['purchasedAt'] != null
          ? (data['purchasedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
      usedForBooking: data['usedForBooking'],
      code: data['code'],
    );
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: VoucherTypeExtension.fromString(json['type'] ?? 'fitness'),
      amount: (json['amount'] ?? 0.0).toDouble(),
      pointsCost: json['pointsCost'] ?? 0,
      isActive: json['isActive'] ?? true,
      clubName: json['clubName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      purchasedBy: json['purchasedBy'],
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'])
          : null,
      usedForBooking: json['usedForBooking'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'type': type.value,
      'amount': amount,
      'pointsCost': pointsCost,
      'isActive': isActive,
      'clubName': clubName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'purchasedBy': purchasedBy,
      'purchasedAt': purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedForBooking': usedForBooking,
      'code': code,
    };
  }

  /// CopyWith method for creating modified copies
  Voucher copyWith({
    String? id,
    String? clubId,
    String? createdBy,
    String? title,
    String? description,
    VoucherType? type,
    double? amount,
    int? pointsCost,
    bool? isActive,
    String? clubName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? purchasedBy,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedForBooking,
    String? code,
  }) {
    return Voucher(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      pointsCost: pointsCost ?? this.pointsCost,
      isActive: isActive ?? this.isActive,
      clubName: clubName ?? this.clubName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedForBooking: usedForBooking ?? this.usedForBooking,
      code: code ?? this.code,
    );
  }

  /// Helper to check if user can purchase this voucher again
  /// Users can't buy same voucher type for 3 months after last purchase
  static Future<bool> canUserPurchaseVoucherType({
    required String userId,
    required String clubId,
    required VoucherType type,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90)); // 3 months
      
      final recentPurchases = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('purchasedBy', isEqualTo: userId)
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: type.value)
          .where('purchasedAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      return recentPurchases.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}