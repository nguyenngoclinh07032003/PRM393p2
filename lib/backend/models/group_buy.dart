import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';

class GroupBuy {
  final String id;
  final String productId;
  final String? groupName;
  final String? creatorId;
  final int minimumMember;
  final int maximumMember;
  final int currentBuyerCount;
  final double? originalPrice;
  final double? groupPrice;
  final double priceUnder50;
  final double priceFrom50;
  final double priceFrom100;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<String> participantIds;
  final String? groupCode;
  final String? shareToken;

  GroupBuy({
    required this.id,
    required this.productId,
    this.groupName,
    this.creatorId,
    int? minimumMember,
    int? maximumMember,
    this.currentBuyerCount = 0,
    this.originalPrice,
    this.groupPrice,
    required this.priceUnder50,
    required this.priceFrom50,
    required this.priceFrom100,
    required this.startTime,
    required this.endTime,
    this.status = AppConstants.groupDealRecruiting,
    this.participantIds = const [],
    this.groupCode,
    this.shareToken,
  })  : minimumMember =
            minimumMember ?? AppConstants.groupBuyDefaultMinMembers,
        maximumMember =
            maximumMember ?? AppConstants.groupBuyDefaultMaxMembers;

  factory GroupBuy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final legacyUnder50 = (data['priceUnder50'] ?? 0).toDouble();
    final legacyFrom100 = (data['priceFrom100'] ?? 0).toDouble();

    return GroupBuy(
      id: doc.id,
      productId: data['productId'] ?? '',
      groupName: data['groupName'] as String?,
      creatorId: data['creatorId'] as String?,
      minimumMember: data['minimumMember'] as int? ??
          AppConstants.groupBuyDefaultMinMembers,
      maximumMember: data['maximumMember'] as int? ??
          (data['minimumMember'] != null
              ? AppConstants.groupBuyDefaultMaxMembers
              : AppConstants.groupBuyThreshold100),
      currentBuyerCount: data['currentBuyerCount'] ??
          data['currentMember'] ??
          0,
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ??
          (legacyUnder50 > 0 ? legacyUnder50 : null),
      groupPrice: (data['groupPrice'] as num?)?.toDouble() ??
          (legacyFrom100 > 0 ? legacyFrom100 : null),
      priceUnder50: legacyUnder50,
      priceFrom50: (data['priceFrom50'] ?? 0).toDouble(),
      priceFrom100: legacyFrom100,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? AppConstants.groupDealRecruiting,
      participantIds: List<String>.from(data['participantIds'] ?? const []),
      groupCode: data['groupCode'] as String?,
      shareToken: data['shareToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      if (groupName != null) 'groupName': groupName,
      if (creatorId != null) 'creatorId': creatorId,
      'minimumMember': minimumMember,
      'maximumMember': maximumMember,
      'currentBuyerCount': currentBuyerCount,
      'currentMember': currentBuyerCount,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (groupPrice != null) 'groupPrice': groupPrice,
      'priceUnder50': priceUnder50,
      'priceFrom50': priceFrom50,
      'priceFrom100': priceFrom100,
      'discountPercent': discountPercent,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'participantIds': participantIds,
      if (groupCode != null) 'groupCode': groupCode,
      if (shareToken != null) 'shareToken': shareToken,
    };
  }

  bool get usesGroupPriceModel =>
      groupPrice != null && groupPrice! > 0 && originalPrice != null;

  double get resolvedOriginalPrice =>
      originalPrice ?? priceUnder50;

  double get resolvedGroupPrice =>
      groupPrice ?? priceFrom100;

  double get discountPercent {
    final original = resolvedOriginalPrice;
    if (original <= 0) return 0;
    final discount = ((original - resolvedGroupPrice) / original) * 100;
    return discount.clamp(0, 100);
  }

  int get remainingMembers =>
      (maximumMember - currentBuyerCount).clamp(0, maximumMember);

  int get membersStillNeeded =>
      (minimumMember - currentBuyerCount).clamp(0, minimumMember);

  Duration get remainingTime {
    final diff = endTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => DateTime.now().isAfter(endTime);

  bool get isWithinSchedule {
    final now = DateTime.now();
    return !now.isBefore(startTime) && !now.isAfter(endTime);
  }

  String get lifecycleStatus {
    if (status == AppConstants.groupDealPaid) {
      return AppConstants.groupDealPaid;
    }
    if (status == AppConstants.groupDealCancelled) {
      return AppConstants.groupDealCancelled;
    }
    if (status == AppConstants.groupDealSuccess) {
      return AppConstants.groupDealSuccess;
    }
    if (status == AppConstants.groupDealFailed) {
      return AppConstants.groupDealFailed;
    }
    if (isExpired) {
      return currentBuyerCount >= minimumMember
          ? AppConstants.groupDealSuccess
          : AppConstants.groupDealExpired;
    }
    if (currentBuyerCount >= maximumMember) {
      return AppConstants.groupDealFull;
    }
    if (currentBuyerCount >= minimumMember) {
      return AppConstants.groupDealSuccess;
    }
    if (currentBuyerCount >= (minimumMember * 0.8).ceil()) {
      return AppConstants.groupDealAlmostFull;
    }
    const openStatuses = {
      AppConstants.groupDealRecruiting,
      AppConstants.groupDealActive,
      AppConstants.groupDealAlmostFull,
    };
    if (openStatuses.contains(status)) {
      return status == AppConstants.groupDealAlmostFull
          ? AppConstants.groupDealAlmostFull
          : AppConstants.groupDealRecruiting;
    }
    return status;
  }

  bool get isJoinable {
    const closed = {
      AppConstants.groupDealFull,
      AppConstants.groupDealSuccess,
      AppConstants.groupDealExpired,
      AppConstants.groupDealFailed,
      AppConstants.groupDealPaid,
      AppConstants.groupDealCancelled,
    };
    if (closed.contains(lifecycleStatus)) return false;
    if (isExpired) return false;
    if (!isWithinSchedule) return false;
    return currentBuyerCount < maximumMember;
  }

  bool get isActive => isJoinable;

  double get currentPrice {
    if (usesGroupPriceModel) {
      return resolvedGroupPrice;
    }
    if (currentBuyerCount >= AppConstants.groupBuyThreshold100) {
      return priceFrom100;
    }
    if (currentBuyerCount >= AppConstants.groupBuyThreshold50) {
      return priceFrom50;
    }
    return priceUnder50;
  }

  String get lifecycleStatusLabel {
    switch (lifecycleStatus) {
      case AppConstants.groupDealRecruiting:
      case AppConstants.groupDealActive:
        return 'Đang tuyển thành viên';
      case AppConstants.groupDealAlmostFull:
        return 'Sắp đủ người';
      case AppConstants.groupDealFull:
        return 'Đã đủ người';
      case AppConstants.groupDealSuccess:
        return 'Deal thành công';
      case AppConstants.groupDealExpired:
        return 'Hết thời gian';
      case AppConstants.groupDealFailed:
        return 'Deal thất bại';
      case AppConstants.groupDealPaid:
        return 'Đã thanh toán';
      case AppConstants.groupDealCancelled:
        return 'Đã hủy';
      default:
        return 'Đang mở';
    }
  }

  bool isOwnedBy(String? userId) =>
      userId != null && creatorId != null && creatorId == userId;

  bool includesUser(String? userId) =>
      userId != null && participantIds.contains(userId);
}
