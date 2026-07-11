import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../utils/pricing_utils.dart';
import '../utils/product_image_utils.dart';
import 'flash_sale_service.dart';
import 'group_buy_service.dart';
import 'product_service.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();
  final FlashSaleService _flashSaleService = FlashSaleService();
  final GroupBuyService _groupBuyService = GroupBuyService();
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;
  int get lineCount => _cartItems.length;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCart(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.cartsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final items =
          snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
      final merged = await _mergeDuplicateCartItems(items);
      _cartItems = await _syncCartItemPrices(merged);
      notifyListeners();
    } catch (e) {
      debugPrint('Load cart error: $e');
      rethrow;
    }
  }

  Future<void> addToCart(
    String userId,
    Product product, {
    int quantity = 1,
    double? unitPrice,
    String? groupBuyId,
  }) async {
    if (quantity <= 0) {
      throw Exception('Số lượng phải lớn hơn 0');
    }

    final resolvedPrice =
        unitPrice ?? await _resolveStandardUnitPrice(product, quantity);
    await _validateStock(product.id, quantity);

    try {
      final existingSnapshot = await _firestore
          .collection(AppConstants.cartsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final existingDocs = existingSnapshot.docs.where((doc) {
        final data = doc.data();
        final sameProduct = data['medicineId'] == product.id;
        final existingGroupBuyId = data['groupBuyId'] as String?;
        final sameGroupBuy = (existingGroupBuyId ?? '') == (groupBuyId ?? '');
        return sameProduct && sameGroupBuy;
      }).toList();

      if (existingDocs.isNotEmpty) {
        final docs = existingDocs;
        final existingItems =
            docs.map((doc) => CartItem.fromFirestore(doc)).toList();
        final existingItem = existingItems.first;
        final newQuantity = existingItems.fold<int>(
          quantity,
          (sum, item) => sum + item.quantity,
        );

        if (existingItem.isGroupBuyItem) {
          throw Exception(
            'Sản phẩm mua nhóm đã có trong giỏ. Vui lòng thanh toán riêng.',
          );
        }

        final updatedPrice = await _resolveStandardUnitPrice(
          product,
          newQuantity,
        );
        await _validateStock(product.id, newQuantity);

        final keepDoc = docs.first;
        final batch = _firestore.batch();

        batch.update(keepDoc.reference, {
          'sellerId': product.sellerId,
          'medicineName': product.name,
          'price': updatedPrice,
          'imageUrl': ProductImageUtils.resolveProduct(product),
          'quantity': newQuantity,
        });

        for (final duplicateDoc in docs.skip(1)) {
          batch.delete(duplicateDoc.reference);
        }

        await batch.commit();
        await loadCart(userId);
      } else {
        final cartItem = CartItem(
          id: '',
          userId: userId,
          sellerId: product.sellerId,
          medicineId: product.id,
          medicineName: product.name,
          price: resolvedPrice,
          imageUrl: ProductImageUtils.resolveProduct(product),
          quantity: quantity,
          addedAt: DateTime.now(),
          groupBuyId: groupBuyId,
        );

        final docRef = await _firestore
            .collection(AppConstants.cartsCollection)
            .add(cartItem.toFirestore());

        _cartItems.add(cartItem.copyWith(id: docRef.id));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index == -1) {
        throw Exception('Không tìm thấy sản phẩm trong giỏ hàng');
      }

      final item = _cartItems[index];
      if (item.isGroupBuyItem && newQuantity > 1) {
        throw Exception('Sản phẩm mua nhóm chỉ được mua 1 đơn vị');
      }

      await _validateStock(item.medicineId, newQuantity);

      double updatedPrice = item.price;
      if (!item.isGroupBuyItem) {
        final product = await _productService.getProduct(item.medicineId);
        if (product == null) {
          throw Exception('Sản phẩm không còn tồn tại');
        }
        updatedPrice = await _resolveStandardUnitPrice(product, newQuantity);
      }

      await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(cartItemId)
          .update({
        'quantity': newQuantity,
        'price': updatedPrice,
      });

      _cartItems[index] = item.copyWith(
        quantity: newQuantity,
        price: updatedPrice,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Update quantity error: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      final item = _cartItems.firstWhere(
        (entry) => entry.id == cartItemId,
        orElse: () => throw Exception('Không tìm thấy sản phẩm trong giỏ hàng'),
      );

      await _leaveGroupBuyIfNeeded(item);

      await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(cartItemId)
          .delete();

      _cartItems.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Remove from cart error: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.cartsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await _leaveGroupBuyIfNeeded(CartItem.fromFirestore(doc));
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Clear cart error: $e');
      rethrow;
    }
  }

  Future<void> removeCartItems(List<String> cartItemIds) async {
    final ids = cartItemIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) return;

    try {
      for (final item in _cartItems.where((entry) => ids.contains(entry.id))) {
        await _leaveGroupBuyIfNeeded(item);
      }

      final batch = _firestore.batch();
      for (final id in ids) {
        batch.delete(
            _firestore.collection(AppConstants.cartsCollection).doc(id));
      }
      await batch.commit();

      _cartItems.removeWhere((item) => ids.contains(item.id));
      notifyListeners();
    } catch (e) {
      debugPrint('Remove cart items error: $e');
      rethrow;
    }
  }

  Future<double> _resolveStandardUnitPrice(
    Product product,
    int quantity,
  ) async {
    final flashSale =
        await _flashSaleService.getFlashSaleForProduct(product.id);
    final baseUnitPrice = PricingUtils.resolveUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
      flashSale: flashSale?.isActive == true ? flashSale : null,
      productId: product.id,
    );
    return PricingUtils.applyTierDiscount(
      baseUnitPrice,
      quantity,
      tiers: product.priceTiers,
      tierReferencePrice: product.price,
    );
  }

  /// Cập nhật giá giỏ theo flash sale hiện tại (giảm khi đang sale, về giá gốc khi hết).
  Future<List<CartItem>> _syncCartItemPrices(List<CartItem> items) async {
    final updated = <CartItem>[];
    final batch = _firestore.batch();
    var hasChanges = false;

    for (final item in items) {
      if (item.isGroupBuyItem) {
        updated.add(item);
        continue;
      }

      final product = await _productService.getProduct(item.medicineId);
      if (product == null) {
        updated.add(item);
        continue;
      }

      final newPrice = await _resolveStandardUnitPrice(product, item.quantity);
      if ((newPrice - item.price).abs() > 0.009) {
        batch.update(
          _firestore.collection(AppConstants.cartsCollection).doc(item.id),
          {'price': newPrice},
        );
        updated.add(item.copyWith(price: newPrice));
        hasChanges = true;
      } else {
        updated.add(item);
      }
    }

    if (hasChanges) {
      await batch.commit();
    }

    return updated;
  }

  Future<void> _leaveGroupBuyIfNeeded(CartItem item) async {
    if (!item.isGroupBuyItem || item.groupBuyId == null) return;
    try {
      await _groupBuyService.leaveGroupBuy(
        groupBuyId: item.groupBuyId!,
        userId: item.userId,
      );
    } catch (e) {
      debugPrint('leaveGroupBuy on cart remove: $e');
    }
  }

  Future<void> _validateStock(String productId, int requestedQuantity) async {
    final product = await _productService.getProduct(productId);
    if (product == null) {
      throw Exception('Sản phẩm không còn tồn tại');
    }
    if (product.status != AppConstants.productActive) {
      throw Exception('Sản phẩm không còn bán');
    }
    if (product.stock < requestedQuantity) {
      throw Exception(
        'Chỉ còn ${product.stock} sản phẩm trong kho',
      );
    }
  }

  Future<List<CartItem>> _mergeDuplicateCartItems(List<CartItem> items) async {
    final byKey = <String, List<CartItem>>{};
    for (final item in items) {
      final key = '${item.medicineId}::${item.groupBuyId ?? ''}';
      byKey.putIfAbsent(key, () => []).add(item);
    }

    final mergedItems = <CartItem>[];
    final batch = _firestore.batch();
    var hasChanges = false;

    for (final entries in byKey.values) {
      if (entries.length == 1) {
        mergedItems.add(entries.first);
        continue;
      }

      entries.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      final keep = entries.first;
      final totalQuantity =
          entries.fold<int>(0, (sum, item) => sum + item.quantity);
      final merged = keep.copyWith(quantity: totalQuantity);
      mergedItems.add(merged);

      batch.update(
        _firestore.collection(AppConstants.cartsCollection).doc(keep.id),
        {'quantity': totalQuantity},
      );

      for (final duplicate in entries.skip(1)) {
        batch.delete(
          _firestore.collection(AppConstants.cartsCollection).doc(duplicate.id),
        );
      }
      hasChanges = true;
    }

    if (hasChanges) {
      await batch.commit();
    }

    return mergedItems;
  }
}
