import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/cart_service.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../widgets/product_image.dart';

class GroupBuyDetailScreen extends StatefulWidget {
  final GroupBuy groupBuy;
  final Product product;

  const GroupBuyDetailScreen({
    super.key,
    required this.groupBuy,
    required this.product,
  });

  @override
  State<GroupBuyDetailScreen> createState() => _GroupBuyDetailScreenState();
}

class _GroupBuyDetailScreenState extends State<GroupBuyDetailScreen> {
  final GroupBuyService _groupBuyService = GroupBuyService();
  bool _isLoading = false;
  bool _hasJoined = false;
  bool _checkingJoinStatus = true;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _checkingJoinStatus = false);
      return;
    }

    final joined = await _groupBuyService.hasUserJoined(
      widget.groupBuy.id,
      userId,
    );
    if (mounted) {
      setState(() {
        _hasJoined = joined;
        _checkingJoinStatus = false;
      });
    }
  }

  Future<void> _joinGroupBuy() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final joinResult = await _groupBuyService.joinGroupBuy(
        groupBuyId: widget.groupBuy.id,
        userId: userId,
        productId: widget.product.id,
      );

      try {
        await cartService.addToCart(
          userId,
          widget.product,
          quantity: 1,
          unitPrice: joinResult.unitPrice,
          groupBuyId: widget.groupBuy.id,
        );
      } catch (e) {
        await _groupBuyService.leaveGroupBuy(
          groupBuyId: widget.groupBuy.id,
          userId: userId,
        );
        rethrow;
      }

      if (!mounted) return;

      setState(() => _hasJoined = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tham gia mua nhóm với giá '
            '${joinResult.unitPrice.toStringAsFixed(0)}đ. Sản phẩm đã được thêm vào giỏ.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamed(context, AppRoutes.cart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết mua nhóm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: ProductImage(
                product: widget.product,
                fit: BoxFit.cover,
                iconSize: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Số người tham gia:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${widget.groupBuy.currentBuyerCount} người',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Giá hiện tại:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.groupBuy.currentPrice.toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.product.description),
                  const SizedBox(height: 12),
                  Text(
                    _hasJoined
                        ? 'Bạn đã tham gia chương trình này. Giá đã được khóa trong giỏ hàng.'
                        : 'Tham gia để mua với giá nhóm. Mỗi tài khoản chỉ tham gia một lần.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: ElevatedButton(
          onPressed: (_isLoading || _hasJoined || _checkingJoinStatus)
              ? null
              : _joinGroupBuy,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
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
                  _hasJoined
                      ? 'Đã tham gia'
                      : 'Tham gia mua nhóm & thêm vào giỏ',
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }
}
