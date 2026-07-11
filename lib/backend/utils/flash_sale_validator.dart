import '../models/flash_sale.dart';

/// Kiểm tra cấu hình Flash Sale: ngày, khung giờ, trùng chương trình.
class FlashSaleValidator {
  FlashSaleValidator._();

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} – ${formatDate(end)}';
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isValidDateRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !endDay.isBefore(startDay);
  }

  /// Hai khung giờ trong cùng ngày có chồng lấn không.
  static bool slotsOverlap(FlashSaleTimeSlot a, FlashSaleTimeSlot b) {
    final aStart = a.startHour * 60 + a.startMinute;
    final aEnd = a.endHour * 60 + a.endMinute;
    final bStart = b.startHour * 60 + b.startMinute;
    final bEnd = b.endHour * 60 + b.endMinute;
    if (aEnd <= aStart || bEnd <= bStart) return false;
    return aStart < bEnd && bStart < aEnd;
  }

  /// Kiểm tra các khung giờ trong một chương trình không chồng nhau.
  static String? validateInternalTimeSlots(List<FlashSaleTimeSlot> slots) {
    if (slots.isEmpty) {
      return 'Cần ít nhất một khung giờ trong ngày';
    }

    for (final slot in slots) {
      final start = slot.startHour * 60 + slot.startMinute;
      final end = slot.endHour * 60 + slot.endMinute;
      if (start == end) {
        return 'Khung "${slot.label}" có giờ bắt đầu trùng giờ kết thúc';
      }
      if (end < start) {
        return 'Khung "${slot.label}": giờ kết thúc (${slot.formatEnd()}) phải sau giờ bắt đầu (${slot.formatStart()})';
      }
    }

    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        if (slotsOverlap(slots[i], slots[j])) {
          return 'Khung "${slots[i].label}" và "${slots[j].label}" bị trùng thời gian trong ngày';
        }
      }
    }

    return null;
  }

  static bool productsOverlap(FlashSale a, FlashSale b) {
    if (a.isAllProduct || b.isAllProduct) return true;
    final aIds = a.effectiveProductIds;
    final bIds = b.effectiveProductIds;
    if (aIds.isEmpty || bIds.isEmpty) return false;
    return aIds.intersection(bIds).isNotEmpty;
  }

  static bool repeatWeekdaysOverlap(FlashSale a, FlashSale b) {
    final allDays = {1, 2, 3, 4, 5, 6, 7};
    final aDays =
        a.repeatWeekdays.isEmpty ? allDays : a.repeatWeekdays.toSet();
    final bDays =
        b.repeatWeekdays.isEmpty ? allDays : b.repeatWeekdays.toSet();
    return aDays.intersection(bDays).isNotEmpty;
  }

  static String? validateRepeatWeekdays(List<int> weekdays) {
    if (weekdays.isEmpty) {
      return 'Chọn ít nhất một ngày lặp lại trong tuần';
    }
    return null;
  }

  static String? validateProductItems({
    required bool isAllProduct,
    required List<FlashSaleProductItem> items,
  }) {
    if (isAllProduct) return null;
    if (items.isEmpty) {
      return 'Vui lòng chọn ít nhất một sản phẩm và cấu hình giá Flash Sale';
    }
    for (final item in items) {
      if (item.flashSalePrice <= 0) {
        return 'Giá Flash Sale phải lớn hơn 0 cho mỗi sản phẩm';
      }
      if (item.quantityPerDay <= 0) {
        return 'Số lượng/ngày phải lớn hơn 0';
      }
      if (item.limitPerCustomer <= 0) {
        return 'Giới hạn/khách phải lớn hơn 0';
      }
    }
    return null;
  }

  static bool campaignDatesOverlap(FlashSale a, FlashSale b) {
    final aStart = DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
    final aEnd = DateTime(
      a.endTime.year,
      a.endTime.month,
      a.endTime.day,
      23,
      59,
      59,
    );
    final bStart = DateTime(b.startTime.year, b.startTime.month, b.startTime.day);
    final bEnd = DateTime(
      b.endTime.year,
      b.endTime.month,
      b.endTime.day,
      23,
      59,
      59,
    );
    return !aStart.isAfter(bEnd) && !bStart.isAfter(aEnd);
  }

  /// Khung giờ giữa hai chiến dịch có trùng không (áp dụng mỗi ngày trong khoảng ngày giao nhau).
  static bool dailySlotsOverlap(FlashSale a, FlashSale b) {
    final slotsA = a.timeSlots;
    final slotsB = b.timeSlots;

    if (slotsA.isEmpty || slotsB.isEmpty) return true;

    for (final slotA in slotsA) {
      for (final slotB in slotsB) {
        if (slotsOverlap(slotA, slotB)) return true;
      }
    }
    return false;
  }

  /// Tìm chương trình đang active trùng sản phẩm + khung giờ.
  static String? findExternalConflict({
    required FlashSale candidate,
    required List<FlashSale> existingSales,
    String? excludeSaleId,
  }) {
    for (final existing in existingSales) {
      if (existing.id == excludeSaleId) continue;
      if (existing.status != 'active' || existing.isScheduleEnded) continue;
      if (!productsOverlap(candidate, existing)) continue;
      if (!campaignDatesOverlap(candidate, existing)) continue;
      if (!repeatWeekdaysOverlap(candidate, existing)) continue;
      if (!dailySlotsOverlap(candidate, existing)) continue;

      final productLabel = candidate.isAllProduct || existing.isAllProduct
          ? 'toàn bộ sản phẩm'
          : 'cùng sản phẩm';
      return 'Trùng khung giờ với chương trình "${existing.name}" ($productLabel). '
          'Vui lòng đổi ngày, khung giờ hoặc sản phẩm.';
    }
    return null;
  }

  /// Dòng hiển thị bảng xem trước lịch áp dụng.
  static List<({String dateRange, String timeRange, String note})> buildScheduleRows({
    required DateTime startDate,
    required DateTime endDate,
    required List<FlashSaleTimeSlot> slots,
  }) {
    if (slots.isEmpty) return const [];

    final dateLabel = formatDateRange(startDate, endDate);
    final sameDay = isSameCalendarDay(startDate, endDate);
    final multiDayNote = sameDay ? '' : ' (lặp mỗi ngày trong khoảng ngày)';

    return slots
        .map(
          (slot) => (
            dateRange: dateLabel,
            timeRange: slot.formatRange(),
            note: sameDay ? 'Chỉ trong ngày này' : multiDayNote.trim(),
          ),
        )
        .toList();
  }
}
