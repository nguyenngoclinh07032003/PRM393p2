import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_constants.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../../frontend/user/checkout/checkout_screen.dart';

class RebuyFlow {
  RebuyFlow._();

  static Future<void> addToCartAndCheckout({
    required BuildContext context,
    required String userId,
    required List<({String productId, int quantity})> items,
  }) async {
    if (items.isEmpty) return;

    final cartService = Provider.of<CartService>(context, listen: false);
    final targetProductIds = items.map((entry) => entry.productId).toSet();

    await cartService.loadCart(userId);

    var addedCount = 0;
    for (final item in items) {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(item.productId)
          .get();
      if (!doc.exists) continue;

      final product = Product.fromFirestore(doc);
      if (product.status != AppConstants.productActive) continue;

      try {
        await cartService.addToCart(
          userId,
          product,
          quantity: item.quantity,
        );
        addedCount++;
      } catch (_) {
        // Bỏ qua SP lỗi, tiếp tục các SP khác
      }
    }

    if (!context.mounted) return;

    if (addedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy sản phẩm để mua lại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await cartService.loadCart(userId);
    final checkoutIds = cartService.cartItems
        .where((entry) => targetProductIds.contains(entry.medicineId))
        .map((entry) => entry.id)
        .toList();

    if (!context.mounted) return;

    if (checkoutIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy sản phẩm trong giỏ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItemIds: checkoutIds),
      ),
    );
  }
}
