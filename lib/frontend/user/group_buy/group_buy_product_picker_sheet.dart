import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../../backend/utils/group_buy_utils.dart';
import '../../widgets/product_image.dart';

Future<Product?> showGroupBuyProductPickerSheet(
  BuildContext context, {
  Product? initialProduct,
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF9FAFB),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _GroupBuyProductPickerBody(
            scrollController: scrollController,
            initialProduct: initialProduct,
          );
        },
      );
    },
  );
}

class _GroupBuyProductPickerBody extends StatefulWidget {
  const _GroupBuyProductPickerBody({
    required this.scrollController,
    this.initialProduct,
  });

  final ScrollController scrollController;
  final Product? initialProduct;

  @override
  State<_GroupBuyProductPickerBody> createState() =>
      _GroupBuyProductPickerBodyState();
}

class _GroupBuyProductPickerBodyState extends State<_GroupBuyProductPickerBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().currentUser?.uid;
    final groupBuyService = context.watch<GroupBuyService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Chọn sản phẩm cho nhóm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'Chọn sản phẩm bạn muốn mở nhóm mua để cấu hình deal.',
                style: TextStyle(color: Color(0xFF667085), height: 1.4),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<GroupBuy>>(
            stream: groupBuyService.getActiveGroupBuys(),
            builder: (context, dealSnapshot) {
              final userProductIds = <String>{};
              if (userId != null) {
                for (final deal in dealSnapshot.data ?? const []) {
                  if (deal.includesUser(userId)) {
                    userProductIds.add(deal.productId);
                  }
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.productsCollection)
                    .where('status', isEqualTo: AppConstants.productActive)
                    .snapshots(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var products = (productSnapshot.data?.docs ?? [])
                      .map((doc) => Product.fromFirestore(doc))
                      .toList();

                  if (_query.isNotEmpty) {
                    products = products
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(_query) ||
                              p.category.toLowerCase().contains(_query),
                        )
                        .toList();
                  }

                  products.sort((a, b) => a.name.compareTo(b.name));

                  if (widget.initialProduct != null) {
                    final initial = widget.initialProduct!;
                    products.removeWhere((p) => p.id == initial.id);
                    products.insert(0, initial);
                  }

                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không tìm thấy sản phẩm phù hợp',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isInitial = widget.initialProduct?.id == product.id;
                      final hasGroup = userProductIds.contains(product.id);
                      final preview = GroupBuyFlowPreview.dealFor(product);

                      return _ProductPickTile(
                        product: product,
                        preview: preview,
                        isSuggested: isInitial,
                        hasExistingGroup: hasGroup,
                        onTap: hasGroup
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bạn đã có nhóm cho sản phẩm này.',
                                    ),
                                  ),
                                );
                              }
                            : () => Navigator.pop(context, product),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class GroupBuyFlowPreview {
  static GroupBuy dealFor(Product product) {
    final original = product.price;
    final groupPrice = (original * 0.8).roundToDouble();
    return GroupBuy(
      id: '',
      productId: product.id,
      originalPrice: original,
      groupPrice: groupPrice,
      priceUnder50: original,
      priceFrom50: (original * 0.9).roundToDouble(),
      priceFrom100: groupPrice,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(
        const Duration(hours: AppConstants.groupBuyDurationHours),
      ),
      minimumMember: AppConstants.groupBuyDefaultMinMembers,
      maximumMember: AppConstants.groupBuyDefaultMaxMembers,
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  const _ProductPickTile({
    required this.product,
    required this.preview,
    required this.isSuggested,
    required this.hasExistingGroup,
    required this.onTap,
  });

  final Product product;
  final GroupBuy preview;
  final bool isSuggested;
  final bool hasExistingGroup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSuggested
                  ? const Color(0xFFF79009)
                  : const Color(0xFFE4E7EC),
              width: isSuggested ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ProductImage(
                    product: product,
                    fit: BoxFit.cover,
                    iconSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSuggested)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6ED),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Gợi ý từ sản phẩm hiện tại',
                          style: TextStyle(
                            color: Color(0xFFB54708),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giá nhóm dự kiến: '
                      '${GroupBuyUtils.formatPrice(preview.resolvedGroupPrice)}đ',
                      style: const TextStyle(
                        color: Color(0xFFD92D20),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (hasExistingGroup) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Bạn đã có nhóm cho sản phẩm này',
                        style: TextStyle(
                          color: Color(0xFFF79009),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                hasExistingGroup ? Icons.block : Icons.chevron_right,
                color: hasExistingGroup
                    ? const Color(0xFF98A2B3)
                    : const Color(0xFFF79009),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
