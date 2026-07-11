import 'dart:math';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import '../models/group_buy.dart';
import '../models/product.dart';

class GroupBuyListItem {
  final GroupBuy deal;
  final Product product;

  const GroupBuyListItem({required this.deal, required this.product});
}

class GroupBuyFilter {
  final String? category;
  final double? minDiscountPercent;
  final int? maxMembersNeeded;
  final bool endingSoonOnly;
  final double? minPrice;
  final double? maxPrice;

  const GroupBuyFilter({
    this.category,
    this.minDiscountPercent,
    this.maxMembersNeeded,
    this.endingSoonOnly = false,
    this.minPrice,
    this.maxPrice,
  });

  static const none = GroupBuyFilter();
}

class GroupBuyUtils {
  static String formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String formatPrice(double price) {
    final raw = price.toStringAsFixed(0);
    return raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  static String formatParticipants(GroupBuy deal) {
    return 'Đã có ${deal.currentBuyerCount}/${deal.maximumMember} người tham gia';
  }

  static String formatDiscount(GroupBuy deal) {
    return 'Giảm đến ${deal.discountPercent.toStringAsFixed(0)}%';
  }

  static String formatMembersNeeded(GroupBuy deal) {
    if (deal.membersStillNeeded <= 0) {
      return 'Đã đủ số người tối thiểu';
    }
    return 'Còn thiếu ${deal.membersStillNeeded} người';
  }

  static String generateShareToken() {
    return const Uuid().v4().replaceAll('-', '').substring(0, 12);
  }

  static String generateGroupCode(String shareToken) {
    final code = shareToken.substring(0, min(5, shareToken.length)).toUpperCase();
    return 'GD-$code';
  }

  static String resolveShareBaseUrl() {
    return Uri.base.origin;
  }

  static String buildShareUrl(GroupBuy deal, {String? baseUrl}) {
    final origin = baseUrl ?? resolveShareBaseUrl();
    final token = deal.shareToken ?? deal.id;
    return '$origin/#${AppConstants.groupBuySharePath}/$token';
  }

  static String buildShareMessage({
    required GroupBuy deal,
    required Product product,
    String? baseUrl,
  }) {
    return buildAutoShareMessage(
      deal: deal,
      product: product,
      baseUrl: baseUrl,
    );
  }

  static String buildAutoShareMessage({
    required GroupBuy deal,
    required Product product,
    String? baseUrl,
  }) {
    final hoursLeft = deal.remainingTime.inHours.clamp(1, 999);
    return 'Cùng mình tham gia nhóm mua ${product.name} với giá '
        '${formatPrice(deal.resolvedGroupPrice)}đ. '
        'Nhóm còn thiếu ${deal.membersStillNeeded} người và sẽ kết thúc sau '
        '$hoursLeft giờ. Tham gia tại: ${buildShareUrl(deal, baseUrl: baseUrl)}';
  }

  static List<GroupBuy> sortDealsForDisplay(
    List<GroupBuy> deals, {
    String? currentUserId,
  }) {
    final sorted = List<GroupBuy>.from(deals);
    sorted.sort((a, b) {
      final aMine = _isUserDeal(a, currentUserId);
      final bMine = _isUserDeal(b, currentUserId);
      if (aMine != bMine) return aMine ? -1 : 1;

      final aAlmost = a.lifecycleStatus == AppConstants.groupDealAlmostFull;
      final bAlmost = b.lifecycleStatus == AppConstants.groupDealAlmostFull;
      if (aAlmost != bAlmost) return aAlmost ? -1 : 1;

      final fillCompare = (b.currentBuyerCount / b.maximumMember)
          .compareTo(a.currentBuyerCount / a.maximumMember);
      if (fillCompare != 0) return fillCompare;

      return a.endTime.compareTo(b.endTime);
    });
    return sorted;
  }

  static GroupBuy? findUserDeal(
    List<GroupBuy> deals,
    String? userId,
  ) {
    if (userId == null) return null;
    for (final deal in deals) {
      if (_isUserDeal(deal, userId)) return deal;
    }
    return null;
  }

  static bool _isUserDeal(GroupBuy deal, String? userId) {
    if (userId == null) return false;
    return deal.isOwnedBy(userId) || deal.includesUser(userId);
  }

  static List<GroupBuyListItem> applyFilter(
    List<GroupBuyListItem> items,
    GroupBuyFilter filter,
  ) {
    var result = items.where((item) {
      final deal = item.deal;
      final product = item.product;

      if (filter.category != null &&
          filter.category!.isNotEmpty &&
          product.category != filter.category) {
        return false;
      }
      if (filter.minDiscountPercent != null &&
          deal.discountPercent < filter.minDiscountPercent!) {
        return false;
      }
      if (filter.maxMembersNeeded != null &&
          deal.remainingMembers > filter.maxMembersNeeded!) {
        return false;
      }
      if (filter.minPrice != null &&
          deal.resolvedGroupPrice < filter.minPrice!) {
        return false;
      }
      if (filter.maxPrice != null &&
          deal.resolvedGroupPrice > filter.maxPrice!) {
        return false;
      }
      if (filter.endingSoonOnly && deal.remainingTime.inHours > 6) {
        return false;
      }
      return true;
    }).toList();

    if (filter.endingSoonOnly) {
      result.sort((a, b) => a.deal.endTime.compareTo(b.deal.endTime));
    } else {
      result.sort((a, b) {
        final discountCompare =
            b.deal.discountPercent.compareTo(a.deal.discountPercent);
        if (discountCompare != 0) return discountCompare;
        return a.deal.remainingMembers.compareTo(b.deal.remainingMembers);
      });
    }

    return result;
  }

  static double maxDiscountAmong(List<GroupBuy> deals) {
    if (deals.isEmpty) return 0;
    return deals
        .map((deal) => deal.discountPercent)
        .reduce((a, b) => a > b ? a : b);
  }

  static GroupBuy? pickBestOpenDeal(List<GroupBuy> deals) {
    final open = deals.where((deal) => deal.isJoinable).toList();
    if (open.isEmpty) return null;
    open.sort((a, b) {
      final fillA = a.currentBuyerCount / a.maximumMember;
      final fillB = b.currentBuyerCount / b.maximumMember;
      return fillB.compareTo(fillA);
    });
    return open.first;
  }
}
