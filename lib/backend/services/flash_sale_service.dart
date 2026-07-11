import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/flash_sale.dart';
import '../utils/flash_sale_validator.dart';
import '../utils/pricing_utils.dart';
import 'product_service.dart';

class FlashSaleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  Stream<List<FlashSale>> getActiveFlashSales() {
    return _firestore
        .collection(AppConstants.flashSalesCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlashSale.fromFirestore(doc))
            .where((fs) => fs.isActive)
            .toList());
  }

  Future<List<FlashSale>> _salesForProduct(
    String productId, {
    required bool activeOnly,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.flashSalesCollection)
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs
        .map((doc) => FlashSale.fromFirestore(doc))
        .where((flashSale) => !flashSale.isScheduleEnded)
        .where((flashSale) => flashSale.appliesToProduct(productId))
        .where((flashSale) => !activeOnly || flashSale.isActive)
        .toList();
  }

  /// Flash sale đang chạy — dùng để tính giá bán.
  Future<FlashSale?> getFlashSaleForProduct(String productId) async {
    try {
      final sales = await _salesForProduct(productId, activeOnly: true);
      if (sales.isEmpty) return null;

      final product = await _productService.getProduct(productId);
      if (product == null) return sales.first;

      return PricingUtils.pickBestFlashSale(product, sales);
    } catch (e) {
      debugPrint('Get flash sale error: $e');
      return null;
    }
  }

  /// Chiến dịch flash sale (kể cả sắp diễn ra) — dùng countdown / chi tiết SP.
  Future<FlashSale?> getFlashSaleCampaignForProduct(String productId) async {
    try {
      final sales = await _salesForProduct(productId, activeOnly: false);
      if (sales.isEmpty) return null;

      final product = await _productService.getProduct(productId);
      final active = sales.where((sale) => sale.isActive).toList();
      if (active.isNotEmpty) {
        if (product == null) return active.first;
        return PricingUtils.pickBestFlashSale(product, active);
      }

      sales.sort((a, b) {
        final aStart = a.countdownStartAt() ?? a.endTime;
        final bStart = b.countdownStartAt() ?? b.endTime;
        return aStart.compareTo(bStart);
      });
      return sales.first;
    } catch (e) {
      debugPrint('Get flash sale campaign error: $e');
      return null;
    }
  }

  Future<FlashSale?> getCurrentActiveFlashSale() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.flashSalesCollection)
          .where('status', isEqualTo: 'active')
          .get();

      final sales = snapshot.docs
          .map((doc) => FlashSale.fromFirestore(doc))
          .where((flashSale) => flashSale.isActive)
          .toList()
        ..sort((a, b) => a.endTime.compareTo(b.endTime));

      return sales.isEmpty ? null : sales.first;
    } catch (e) {
      debugPrint('Get current flash sale error: $e');
      return null;
    }
  }

  Future<String?> validateBeforeSave(
    FlashSale candidate, {
    String? excludeSaleId,
  }) async {
    if (!FlashSaleValidator.isValidDateRange(
      candidate.startTime,
      candidate.endTime,
    )) {
      return 'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu';
    }

    final slotsError =
        FlashSaleValidator.validateInternalTimeSlots(candidate.timeSlots);
    if (slotsError != null) return slotsError;

    final weekdaysError =
        FlashSaleValidator.validateRepeatWeekdays(candidate.repeatWeekdays);
    if (weekdaysError != null) return weekdaysError;

    final productsError = FlashSaleValidator.validateProductItems(
      isAllProduct: candidate.isAllProduct,
      items: candidate.productItems,
    );
    if (productsError != null) return productsError;

    final snapshot = await _firestore
        .collection(AppConstants.flashSalesCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final existing = snapshot.docs
        .map((doc) => FlashSale.fromFirestore(doc))
        .where((sale) => !sale.isScheduleEnded)
        .toList();

    return FlashSaleValidator.findExternalConflict(
      candidate: candidate,
      existingSales: existing,
      excludeSaleId: excludeSaleId,
    );
  }

  Future<String?> createFlashSale(FlashSale flashSale) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.flashSalesCollection)
          .add(flashSale.toFirestore());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Create flash sale error: $e');
      rethrow;
    }
  }

  Future<void> updateFlashSale(
      String flashSaleId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.flashSalesCollection)
          .doc(flashSaleId)
          .update(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Update flash sale error: $e');
      rethrow;
    }
  }

  Future<void> endFlashSale(String flashSaleId) async {
    try {
      await _firestore
          .collection(AppConstants.flashSalesCollection)
          .doc(flashSaleId)
          .update({'status': 'inactive'});
      notifyListeners();
    } catch (e) {
      debugPrint('End flash sale error: $e');
      rethrow;
    }
  }

  double calculateFlashSalePrice(double originalPrice, double discountPercent) {
    return PricingUtils.flashSalePrice(originalPrice, discountPercent);
  }
}
