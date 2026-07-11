// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../backend/models/cart_item.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/cart_service.dart';
import '../../../backend/services/order_service.dart';
import '../orders/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.cartItemIds});

  /// Chỉ thanh toán các dòng giỏ có id trong danh sách (dùng cho Mua lại).
  final List<String>? cartItemIds;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final OrderService _orderService = OrderService();

  String _paymentMethod = 'cod';
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryProfile();
  }

  Future<void> _loadDeliveryProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getUserProfile();

    if (!mounted) return;

    if (profile != null) {
      _nameController.text = (profile['fullName'] as String?)?.trim() ?? '';
      _phoneController.text = (profile['phone'] as String?)?.trim() ?? '';
      _addressController.text = (profile['address'] as String?)?.trim() ?? '';
    }

    setState(() => _isLoadingProfile = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int _sellerCount(CartService cartService) {
    return _itemsToCheckout(cartService)
        .map((item) => item.sellerId)
        .toSet()
        .length;
  }

  List<CartItem> _itemsToCheckout(CartService cartService) {
    final all = cartService.cartItems;
    final filter = widget.cartItemIds;
    if (filter == null) {
      return List<CartItem>.from(all);
    }
    if (filter.isEmpty) {
      return const [];
    }
    final allowed = filter.toSet();
    return all.where((item) => allowed.contains(item.id)).toList();
  }

  double _checkoutTotal(CartService cartService) {
    return _itemsToCheckout(cartService)
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _placeOrder() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập trước khi đặt hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await cartService.loadCart(userId);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tải được giỏ hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final itemsToOrder = _itemsToCheckout(cartService);
    if (itemsToOrder.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final deliveryInfo = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      await authService.updateDeliveryProfile(
        fullName: deliveryInfo['name']!,
        phone: deliveryInfo['phone']!,
        address: deliveryInfo['address']!,
      );

      final result = await _orderService.placeOrders(
        userId: userId,
        cartItems: itemsToOrder,
        deliveryInfo: deliveryInfo,
        paymentMethod: _paymentMethod,
      );

      await cartService.removeCartItems(
        itemsToOrder.map((item) => item.id).toList(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderIds: result.orderIds,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final checkoutItems = _itemsToCheckout(cartService);
    final sellerCount = _sellerCount(cartService);
    final checkoutQty =
        checkoutItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (sellerCount > 1)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Giỏ hàng có sản phẩm từ $sellerCount người bán. '
                                'Hệ thống sẽ tạo $sellerCount đơn hàng riêng.',
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (sellerCount > 1) const SizedBox(height: 16),
                  const _SectionTitle('Thông tin giao hàng'),
                  const SizedBox(height: 8),
                  Text(
                    'Thông tin lấy từ tài khoản đăng ký. Bạn có thể chỉnh sửa trước khi đặt hàng.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập số điện thoại'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ giao hàng *',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập địa chỉ'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Phương thức thanh toán'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    value: 'cod',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Chuyển khoản ngân hàng'),
                    value: 'bank',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Ví điện tử (MoMo, ZaloPay)'),
                    value: 'ewallet',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Thông tin đơn hàng'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Số lượng:',
                            value: '$checkoutQty sản phẩm',
                          ),
                          if (sellerCount > 1)
                            _SummaryRow(
                              label: 'Số đơn hàng:',
                              value: '$sellerCount đơn',
                            ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Tổng cộng:',
                            value: _formatCurrency(_checkoutTotal(cartService)),
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              sellerCount > 1
                                  ? 'Đặt $sellerCount đơn hàng'
                                  : 'Đặt hàng',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasized ? 18 : 14,
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 20 : 14,
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
            color: emphasized ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(double value) {
  final text = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  return '${text}đ';
}
