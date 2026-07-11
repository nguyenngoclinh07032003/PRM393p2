import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/cart_item.dart';
import '../models/flash_sale.dart';
import '../models/product.dart';
import '../utils/pricing_utils.dart';
import 'flash_sale_service.dart';
import 'rebuy_service.dart';

class OrderPlacementResult {
  final List<String> orderIds;

  const OrderPlacementResult({required this.orderIds});
}

class _PricedCartLine {
  const _PricedCartLine({required this.item, required this.unitPrice});

  final CartItem item;
  final double unitPrice;

  double get lineTotal => unitPrice * item.quantity;
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RebuyService _rebuyService = RebuyService();
  final FlashSaleService _flashSaleService = FlashSaleService();

  Future<OrderPlacementResult> placeOrders({
    required String userId,
    required List<CartItem> cartItems,
    required Map<String, String> deliveryInfo,
    required String paymentMethod,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Giỏ hàng trống');
    }

    final pricedLines = await _priceCartLines(cartItems);

    final requiredStock = <String, int>{};
    final productNames = <String, String>{};
    for (final line in pricedLines) {
      requiredStock[line.item.medicineId] =
          (requiredStock[line.item.medicineId] ?? 0) + line.item.quantity;
      productNames[line.item.medicineId] = line.item.medicineName;
    }

    final bySeller = <String, List<_PricedCartLine>>{};
    for (final line in pricedLines) {
      bySeller.putIfAbsent(line.item.sellerId, () => []).add(line);
    }

    final orderIds = await _firestore.runTransaction<List<String>>(
      (transaction) async {
        final createdOrderIds = <String>[];
        final productRefs = <String, DocumentReference>{};
        final productSnapshots = <String, DocumentSnapshot>{};

        for (final productId in requiredStock.keys) {
          final ref = _firestore
              .collection(AppConstants.productsCollection)
              .doc(productId);
          productRefs[productId] = ref;
          productSnapshots[productId] = await transaction.get(ref);
        }

        for (final entry in requiredStock.entries) {
          final snapshot = productSnapshots[entry.key];
          if (snapshot == null || !snapshot.exists) {
            throw Exception(
              'Sản phẩm "${productNames[entry.key]}" không còn tồn tại',
            );
          }
          final stock = ((snapshot.data() as Map<String, dynamic>?)?['stock']
                  as num?)
              ?.toInt() ??
              0;
          final status =
              (snapshot.data() as Map<String, dynamic>?)?['status']
                      as String? ??
                  '';
          if (status != AppConstants.productActive) {
            throw Exception(
              'Sản phẩm "${productNames[entry.key]}" không còn bán',
            );
          }
          if (stock < entry.value) {
            throw Exception(
              'Sản phẩm "${productNames[entry.key]}" chỉ còn $stock trong kho',
            );
          }
        }

        for (final entry in requiredStock.entries) {
          transaction.update(productRefs[entry.key]!, {
            'stock': FieldValue.increment(-entry.value),
          });
        }

        for (final sellerEntry in bySeller.entries) {
          final sellerLines = sellerEntry.value;
          final sellerTotal = sellerLines.fold<double>(
            0,
            (sum, line) => sum + line.lineTotal,
          );

          final orderRef =
              _firestore.collection(AppConstants.ordersCollection).doc();
          transaction.set(orderRef, {
            'userId': userId,
            'sellerId': sellerEntry.key,
            'totalPrice': sellerTotal,
            'status': AppConstants.orderPending,
            'paymentStatus': AppConstants.paymentUnpaid,
            'paymentMethod': paymentMethod,
            'deliveryInfo': deliveryInfo,
            'createdAt': FieldValue.serverTimestamp(),
          });
          createdOrderIds.add(orderRef.id);

          for (final line in sellerLines) {
            final orderItemRef =
                _firestore.collection(AppConstants.orderItemsCollection).doc();
            transaction.set(orderItemRef, {
              'orderId': orderRef.id,
              'productId': line.item.medicineId,
              'productName': line.item.medicineName,
              'quantity': line.item.quantity,
              'price': line.unitPrice,
              if (line.item.groupBuyId != null)
                'groupBuyId': line.item.groupBuyId,
            });
          }
        }

        return createdOrderIds;
      },
    );

    for (final line in pricedLines) {
      try {
        await _rebuyService.updateRebuyStat(
          userId,
          line.item.medicineId,
          quantity: line.item.quantity,
        );
      } catch (e) {
        debugPrint('Error updating rebuy stat for ${line.item.medicineId}: $e');
      }
    }

    return OrderPlacementResult(orderIds: orderIds);
  }

  Future<List<_PricedCartLine>> _priceCartLines(List<CartItem> cartItems) async {
    final productIds = cartItems
        .where((item) => !item.isGroupBuyItem)
        .map((item) => item.medicineId)
        .toSet();

    final resolvedFlash = <String, FlashSale?>{};
    await Future.wait(
      productIds.map((productId) async {
        resolvedFlash[productId] =
            await _flashSaleService.getFlashSaleForProduct(productId);
      }),
    );

    final priced = <_PricedCartLine>[];
    for (final item in cartItems) {
      final productSnap = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(item.medicineId)
          .get();
      if (!productSnap.exists) {
        throw Exception('Sản phẩm "${item.medicineName}" không còn tồn tại');
      }

      final product = Product.fromFirestore(productSnap);
      final unitPrice = PricingUtils.checkoutUnitPrice(
        product: product,
        quantity: item.quantity,
        flashSale: item.isGroupBuyItem ? null : resolvedFlash[item.medicineId],
        lockedGroupBuyUnitPrice: item.isGroupBuyItem ? item.price : null,
      );

      priced.add(_PricedCartLine(item: item, unitPrice: unitPrice));
    }

    return priced;
  }
}
