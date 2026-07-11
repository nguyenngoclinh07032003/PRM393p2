import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../../backend/models/cart_item.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/cart_service.dart';
import '../../widgets/product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color accent = Color(0xFF24C7E8);
  static const Color surface = Color(0xFFF7F8FB);

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId != null) {
      await cartService.loadCart(userId);
    }
  }

  Future<void> _updateQuantity(
    CartService cartService,
    CartItem item,
    int newQuantity,
  ) async {
    try {
      await cartService.updateQuantity(item.id, newQuantity);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.cartItems.isEmpty) {
            return _EmptyCart(
              onContinueShopping: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cartService.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartService.cartItems[index];
                    return _CartItemCard(
                      item: item,
                      onDecrease: item.quantity > 1
                          ? () => _updateQuantity(cartService, item, item.quantity - 1)
                          : null,
                      onIncrease: item.isGroupBuyItem
                          ? null
                          : () => _updateQuantity(
                                cartService,
                                item,
                                item.quantity + 1,
                              ),
                      onDelete: () =>
                          _confirmDelete(context, cartService, item),
                    );
                  },
                ),
              ),
              _CartSummary(
                totalAmount: cartService.totalAmount,
                itemCount: cartService.itemCount,
                onCheckout: () =>
                    Navigator.pushNamed(context, AppRoutes.checkout),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CartService cartService,
    CartItem item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Xóa sản phẩm này khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cartService.removeFromCart(item.id);
    }
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 96, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onContinueShopping,
            child: const Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final CartItem item;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ProductImage(
                  url: item.imageUrl,
                  name: item.medicineName,
                  fit: BoxFit.cover,
                  iconSize: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.isGroupBuyItem)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Giá mua nhóm (đã khóa)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(item.price),
                    style: const TextStyle(
                      color: _CartScreenState.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onDecrease,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 24,
                      ),
                      Container(
                        width: 38,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onIncrease,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatCurrency(item.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.totalAmount,
    required this.itemCount,
    required this.onCheckout,
  });

  final double totalAmount;
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatCurrency(totalAmount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Thanh toán ($itemCount sản phẩm)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final text = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  return '${text}đ';
}
