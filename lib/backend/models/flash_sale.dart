import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FlashSaleCountdownPhase {
  beforeCampaign,
  upcomingSlot,
  active,
  ended,
}

/// Cách reset số lượng Flash Sale mỗi ngày.
enum FlashSaleQuantityResetMode {
  perSlot,
  sharedDaily,
}

/// Cấu hình từng sản phẩm trong Flash Sale.
class FlashSaleProductItem {
  const FlashSaleProductItem({
    required this.productId,
    required this.flashSalePrice,
    this.quantityPerDay = 100,
    this.limitPerCustomer = 2,
    this.soldToday = 0,
  });

  final String productId;
  final double flashSalePrice;
  final int quantityPerDay;
  final int limitPerCustomer;
  final int soldToday;

  factory FlashSaleProductItem.fromMap(Map<String, dynamic> data) {
    return FlashSaleProductItem(
      productId: data['productId'] as String? ?? '',
      flashSalePrice: (data['flashSalePrice'] as num?)?.toDouble() ?? 0,
      quantityPerDay: (data['quantityPerDay'] as num?)?.toInt() ?? 100,
      limitPerCustomer: (data['limitPerCustomer'] as num?)?.toInt() ?? 2,
      soldToday: (data['soldToday'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'flashSalePrice': flashSalePrice,
      'quantityPerDay': quantityPerDay,
      'limitPerCustomer': limitPerCustomer,
      'soldToday': soldToday,
    };
  }

  FlashSaleProductItem copyWith({
    String? productId,
    double? flashSalePrice,
    int? quantityPerDay,
    int? limitPerCustomer,
    int? soldToday,
  }) {
    return FlashSaleProductItem(
      productId: productId ?? this.productId,
      flashSalePrice: flashSalePrice ?? this.flashSalePrice,
      quantityPerDay: quantityPerDay ?? this.quantityPerDay,
      limitPerCustomer: limitPerCustomer ?? this.limitPerCustomer,
      soldToday: soldToday ?? this.soldToday,
    );
  }

  int get remainingToday => (quantityPerDay - soldToday).clamp(0, quantityPerDay);

  bool get hasStockToday => remainingToday > 0;
}

/// Một khung giờ sale trong ngày (ví dụ 9:00 - 12:00).
class FlashSaleTimeSlot {
  const FlashSaleTimeSlot({
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  TimeOfDay get start => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get end => TimeOfDay(hour: endHour, minute: endMinute);

  factory FlashSaleTimeSlot.fromMap(Map<String, dynamic> data) {
    return FlashSaleTimeSlot(
      label: data['label'] as String? ?? 'Khung giờ',
      startHour: (data['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (data['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (data['endHour'] as num?)?.toInt() ?? 12,
      endMinute: (data['endMinute'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  FlashSaleTimeSlot copyWith({
    String? label,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return FlashSaleTimeSlot(
      label: label ?? this.label,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  String formatRange() {
    return '${formatStart()} - ${formatEnd()}';
  }

  String formatStart() {
    return _two(startHour, startMinute);
  }

  String formatEnd() {
    return _two(endHour, endMinute);
  }

  static String _two(int hour, int minute) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(hour)}:${two(minute)}';
  }

  bool isNowInSlot(DateTime now) {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    if (startMinutes == endMinutes) return false;
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  int get durationMinutes {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (end >= start) return end - start;
    return (24 * 60 - start) + end;
  }
}

class FlashSale {
  final String id;
  final String name;
  final List<String> productIds;
  final bool isAllProduct;
  final double discountPercent;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<FlashSaleTimeSlot> timeSlots;
  final List<int> repeatWeekdays;
  final String note;
  final List<FlashSaleProductItem> productItems;
  final FlashSaleQuantityResetMode quantityResetMode;
  final int dailyResetHour;
  final int dailyResetMinute;
  final bool allowRegularPriceAfterStockOut;

  FlashSale({
    required this.id,
    required this.name,
    required this.productIds,
    this.isAllProduct = false,
    required this.discountPercent,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
    this.timeSlots = const [],
    this.repeatWeekdays = const [],
    this.note = '',
    this.productItems = const [],
    this.quantityResetMode = FlashSaleQuantityResetMode.sharedDaily,
    this.dailyResetHour = 0,
    this.dailyResetMinute = 0,
    this.allowRegularPriceAfterStockOut = true,
  });

  static FlashSaleQuantityResetMode _parseResetMode(String? raw) {
    if (raw == 'perSlot') return FlashSaleQuantityResetMode.perSlot;
    return FlashSaleQuantityResetMode.sharedDaily;
  }

  static String _resetModeToString(FlashSaleQuantityResetMode mode) {
    return mode == FlashSaleQuantityResetMode.perSlot ? 'perSlot' : 'sharedDaily';
  }

  factory FlashSale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawSlots = data['timeSlots'] as List<dynamic>? ?? [];
    final rawItems = data['productItems'] as List<dynamic>? ?? [];
    return FlashSale(
      id: doc.id,
      name: data['name'] ?? '',
      productIds: List<String>.from(data['productIds'] ?? []),
      isAllProduct: data['isAllProduct'] ?? false,
      discountPercent: (data['discountPercent'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      timeSlots: rawSlots
          .whereType<Map>()
          .map((e) => FlashSaleTimeSlot.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      repeatWeekdays: List<int>.from(data['repeatWeekdays'] ?? []),
      note: data['note'] as String? ?? '',
      productItems: rawItems
          .whereType<Map>()
          .map((e) => FlashSaleProductItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      quantityResetMode: _parseResetMode(data['quantityResetMode'] as String?),
      dailyResetHour: (data['dailyResetHour'] as num?)?.toInt() ?? 0,
      dailyResetMinute: (data['dailyResetMinute'] as num?)?.toInt() ?? 0,
      allowRegularPriceAfterStockOut:
          data['allowRegularPriceAfterStockOut'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'productIds': productIds,
      'isAllProduct': isAllProduct,
      'discountPercent': discountPercent,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'timeSlots': timeSlots.map((s) => s.toMap()).toList(),
      'repeatWeekdays': repeatWeekdays,
      'note': note,
      'productItems': productItems.map((item) => item.toMap()).toList(),
      'quantityResetMode': _resetModeToString(quantityResetMode),
      'dailyResetHour': dailyResetHour,
      'dailyResetMinute': dailyResetMinute,
      'allowRegularPriceAfterStockOut': allowRegularPriceAfterStockOut,
    };
  }

  Set<String> get effectiveProductIds {
    if (isAllProduct) return {};
    if (productItems.isNotEmpty) {
      return productItems.map((item) => item.productId).toSet();
    }
    return productIds.toSet();
  }

  FlashSaleProductItem? itemForProduct(String productId) {
    for (final item in productItems) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  bool appliesOnWeekday(int weekday) {
    if (repeatWeekdays.isEmpty) return true;
    return repeatWeekdays.contains(weekday);
  }

  String formatRepeatWeekdays() {
    if (repeatWeekdays.isEmpty) return 'Mỗi ngày';
    const labels = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    final sorted = [...repeatWeekdays]..sort();
    return sorted.map((day) => labels[day] ?? '?').join(', ');
  }

  bool hasFlashStockFor(String productId) {
    final item = itemForProduct(productId);
    if (item == null) return true;
    return item.hasStockToday;
  }

  bool appliesToProduct(String productId) {
    if (isAllProduct) return true;
    if (productItems.isNotEmpty) {
      return productItems.any((item) => item.productId == productId);
    }
    return productIds.contains(productId);
  }

  bool _isInCampaignDateRange(DateTime now) {
    final campaignStart =
        DateTime(startTime.year, startTime.month, startTime.day);
    final campaignEnd = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      23,
      59,
      59,
    );
    return !now.isBefore(campaignStart) && !now.isAfter(campaignEnd);
  }

  bool get isActive {
    final now = DateTime.now();
    if (status != 'active') return false;
    if (!_isInCampaignDateRange(now)) return false;
    if (!appliesOnWeekday(now.weekday)) return false;

    if (timeSlots.isNotEmpty) {
      return timeSlots.any((slot) => slot.isNowInSlot(now));
    }

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Chương trình đã qua thời gian kết thúc (kể cả khi status vẫn là active).
  bool get isScheduleEnded {
    final now = DateTime.now();
    if (status != 'active') return true;

    final campaignEnd = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      23,
      59,
      59,
    );
    if (now.isAfter(campaignEnd)) return true;

    if (timeSlots.isEmpty) {
      return !now.isBefore(endTime);
    }

    return now.isAfter(campaignEnd);
  }

  /// Chương trình chưa tới thời gian bắt đầu.
  bool get isUpcoming {
    final now = DateTime.now();
    if (status != 'active') return false;
    if (!_isInCampaignDateRange(now) && now.isBefore(
      DateTime(startTime.year, startTime.month, startTime.day),
    )) {
      return true;
    }
    if (!appliesOnWeekday(now.weekday) && _isInCampaignDateRange(now)) {
      return true;
    }

    if (timeSlots.isEmpty) {
      return now.isBefore(startTime);
    }

    if (now.isAfter(DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      23,
      59,
      59,
    ))) {
      return false;
    }

    return !timeSlots.any((slot) => slot.isNowInSlot(now)) &&
        now.isBefore(endTime);
  }

  /// Giờ kết thúc của khung sale đang chạy (dùng cho countdown).
  DateTime? activeSlotEndAt([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    if (timeSlots.isEmpty) return endTime;

    for (final slot in timeSlots) {
      if (slot.isNowInSlot(now)) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          slot.endHour,
          slot.endMinute,
        );
      }
    }
    return null;
  }

  DateTime? currentOrNextStartAt([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    if (status != 'active' || isScheduleEnded) return null;

    if (timeSlots.isEmpty) return startTime;

    for (final slot in timeSlots) {
      if (slot.isNowInSlot(now)) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          slot.startHour,
          slot.startMinute,
        );
      }
    }

    final campaignStart =
        DateTime(startTime.year, startTime.month, startTime.day);
    final campaignEnd = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      23,
      59,
      59,
    );
    final firstDay = now.isAfter(campaignStart) ? now : campaignStart;

    for (var day = DateTime(firstDay.year, firstDay.month, firstDay.day);
        !day.isAfter(campaignEnd);
        day = day.add(const Duration(days: 1))) {
      if (!appliesOnWeekday(day.weekday)) continue;

      final candidates = timeSlots
          .map(
            (slot) => DateTime(
              day.year,
              day.month,
              day.day,
              slot.startHour,
              slot.startMinute,
            ),
          )
          .where((start) => !start.isBefore(now))
          .toList()
        ..sort();

      if (candidates.isNotEmpty) return candidates.first;
    }

    return null;
  }

  DateTime? _slotEndForStart(DateTime slotStart) {
    FlashSaleTimeSlot? matched;
    for (final slot in timeSlots) {
      if (slot.startHour == slotStart.hour &&
          slot.startMinute == slotStart.minute) {
        matched = slot;
        break;
      }
    }
    if (matched == null) return null;
    return DateTime(
      slotStart.year,
      slotStart.month,
      slotStart.day,
      matched.endHour,
      matched.endMinute,
    );
  }

  /// Thời điểm bắt đầu dùng cho countdown (khung đang chạy hoặc khung kế tiếp).
  DateTime? countdownStartAt([DateTime? reference]) =>
      currentOrNextStartAt(reference);

  /// Thời điểm kết thúc dùng cho countdown (khung đang chạy hoặc khung kế tiếp).
  DateTime? countdownEndAt([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    if (status != 'active' || isScheduleEnded) return null;

    if (timeSlots.isEmpty) return endTime;

    final activeEnd = activeSlotEndAt(now);
    if (activeEnd != null) return activeEnd;

    final nextStart = currentOrNextStartAt(now);
    if (nextStart == null) return null;

    return _slotEndForStart(nextStart);
  }

  DateTime? currentOrNextEndAt([DateTime? reference]) =>
      countdownEndAt(reference);

  /// Trạng thái countdown hiện tại.
  FlashSaleCountdownPhase countdownPhase([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    if (status != 'active' || isScheduleEnded) {
      return FlashSaleCountdownPhase.ended;
    }

    final campaignStart =
        DateTime(startTime.year, startTime.month, startTime.day);
    if (now.isBefore(campaignStart)) {
      return FlashSaleCountdownPhase.beforeCampaign;
    }

    if (isActive) return FlashSaleCountdownPhase.active;

    final start = countdownStartAt(now);
    if (start != null && now.isBefore(start)) {
      return FlashSaleCountdownPhase.upcomingSlot;
    }

    if (countdownStartAt(now) == null && countdownEndAt(now) == null) {
      return FlashSaleCountdownPhase.ended;
    }

    return FlashSaleCountdownPhase.upcomingSlot;
  }

  /// Có hiển thị trên app user (đang chạy hoặc sắp tới trong chiến dịch).
  bool get isVisibleToUsers {
    if (status != 'active' || isScheduleEnded) return false;
    final now = DateTime.now();
    final campaignStart =
        DateTime(startTime.year, startTime.month, startTime.day);
    final campaignEnd = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      23,
      59,
      59,
    );
    if (now.isAfter(campaignEnd)) return false;
    if (isActive || isUpcoming) return true;
    if (now.isBefore(campaignStart)) return countdownStartAt(now) != null;
    return countdownStartAt(now) != null;
  }

  String formatCampaignRange() {
    String d(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return '${d(startTime)} → ${d(endTime)}';
  }

  String? highlightedSlotRange([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    if (timeSlots.isEmpty) return null;

    for (final slot in timeSlots) {
      if (slot.isNowInSlot(now)) return slot.formatRange();
    }

    final nextStart = countdownStartAt(now);
    if (nextStart == null) return timeSlotsSummary;

    for (final slot in timeSlots) {
      if (slot.startHour == nextStart.hour &&
          slot.startMinute == nextStart.minute) {
        return slot.formatRange();
      }
    }

    return timeSlots.first.formatRange();
  }

  String get timeSlotsSummary {
    if (timeSlots.isEmpty) return '';
    return timeSlots.map((s) => s.formatRange()).join(' • ');
  }

  double flashPriceForProduct(double listedPrice, String productId) {
    final item = itemForProduct(productId);
    if (item != null && item.flashSalePrice > 0) {
      return item.flashSalePrice;
    }
    return calculateDiscountedPrice(listedPrice);
  }

  double calculateDiscountedPrice(double originalPrice) {
    return originalPrice * (1 - discountPercent / 100);
  }
}
