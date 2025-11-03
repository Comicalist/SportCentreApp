import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of vouchers available in the system
enum VoucherType { 
  fitness, // Can be used for activity bookings
  stuff    // For merchandise/food purchases
}

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

/// Represents a voucher that can be purchased with points and used for discounts
/// 
/// Vouchers follow a lifecycle: created → purchased → used/expired
/// Users purchase vouchers with accumulated points and can apply them to bookings
class Voucher {
  const Voucher({
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

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
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
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasedBy: json['purchasedBy'],
      purchasedAt: json['purchasedAt'] is String
          ? DateTime.parse(json['purchasedAt'])
          : (json['purchasedAt'] as Timestamp?)?.toDate(),
      expiresAt: json['expiresAt'] is String
          ? DateTime.parse(json['expiresAt'])
          : (json['expiresAt'] as Timestamp?)?.toDate(),
      usedAt: json['usedAt'] is String
          ? DateTime.parse(json['usedAt'])
          : (json['usedAt'] as Timestamp?)?.toDate(),
      usedForBooking: json['usedForBooking'],
      code: json['code'],
    );
  }

  // Core identifiers
  final String id;
  final String clubId;
  final String createdBy;

  // Voucher details
  final String title;
  final String description;
  final VoucherType type;
  final double amount; // CHF value
  final int pointsCost; // Points required to purchase
  final bool isActive;

  // Display data (denormalized)
  final String clubName;

  // Lifecycle timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Purchase tracking (populated when bought)
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final DateTime? expiresAt; // 1 year from purchase

  // Usage tracking (populated when used)
  final DateTime? usedAt;
  final String? usedForBooking;

  // Unique voucher code (generated on purchase)
  final String? code;

  /// Check if voucher is available for purchase
  bool get isAvailableForPurchase => isActive && purchasedBy == null;

  /// Check if voucher is purchased but not yet used
  bool get isPurchasedAndUnused =>
      purchasedBy != null && usedAt == null && !isExpired;

  /// Check if voucher has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if voucher has been used
  bool get isUsed => usedAt != null;

  /// Check if voucher can be applied to activity bookings
  bool get canBeUsedForBookings =>
      type == VoucherType.fitness && isPurchasedAndUnused;

  /// Get human-readable status
  String get statusDisplayText {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    if (isPurchasedAndUnused) return 'Available';
    if (isAvailableForPurchase) return 'For Sale';
    return 'Inactive';
  }

  /// Generate unique voucher code (format: SC-V-YYYY-XXXX)
  static String generateVoucherCode() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SC-V-$year-$random';
  }

  /// Calculate expiration date (1 year from purchase)
  static DateTime calculateExpirationDate() {
    return DateTime.now().add(const Duration(days: 365));
  }

  /// Check if user can purchase same voucher type again
  /// Prevents spam purchases - 3 month cooldown per voucher type
  static Future<bool> canUserPurchaseVoucherType({
    required String userId,
    required String clubId,
    required VoucherType type,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

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
}
