import 'package:flutter/material.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../../backend/services/product_service.dart';
import '../../widgets/product_image.dart';
import 'group_buy_detail_screen.dart';
import 'group_buy_widgets.dart';

class GroupBuyInviteScreen extends StatefulWidget {
  const GroupBuyInviteScreen({
    super.key,
    required this.shareToken,
  });

  final String shareToken;

  @override
  State<GroupBuyInviteScreen> createState() => _GroupBuyInviteScreenState();
}

class _GroupBuyInviteScreenState extends State<GroupBuyInviteScreen> {
  GroupBuy? _deal;
  Product? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    final service = GroupBuyService();
    try {
      final deal = await service.getDealByShareToken(widget.shareToken);
      if (deal == null) {
        setState(() {
          _error = 'Nhóm không tồn tại hoặc đã kết thúc';
          _loading = false;
        });
        return;
      }

      final productDoc = await ProductService().getProduct(deal.productId);
      if (!mounted) return;
      setState(() {
        _deal = deal;
        _product = productDoc;
        _loading = false;
        if (productDoc == null) {
          _error = 'Không tìm thấy sản phẩm của nhóm này';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời tham gia nhóm'),
        backgroundColor: const Color(0xFFF79009),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final deal = _deal!;
    final product = _product!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn được mời tham gia nhóm mua',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: ProductImage(product: product, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          GroupBuyPriceRow(deal: deal),
          const SizedBox(height: 12),
          GroupBuyHighlightPanel(deal: deal),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: deal.isJoinable
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupBuyDetailScreen(
                            groupBuy: deal,
                            product: product,
                          ),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF79009),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tham gia nhóm'),
            ),
          ),
        ],
      ),
    );
  }
}
