import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../../backend/utils/group_buy_utils.dart';
import 'group_buy_detail_screen.dart';
import 'group_buy_flow.dart';
import 'group_buy_join_groups_sheet.dart';
import 'group_buy_widgets.dart';
import '../../widgets/product_image.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  GroupBuyFilter _filter = GroupBuyFilter.none;
  String? _selectedCategory;

  static const _categories = [
    'Tất cả',
    'Điện thoại',
    'Laptop',
    'Đồng hồ',
    'Máy ảnh',
    'Âm thanh',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    final groupBuyService = context.watch<GroupBuyService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mua nhóm nhận deal'),
        backgroundColor: const Color(0xFFF79009),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<GroupBuy>>(
        stream: groupBuyService.getActiveGroupBuys(),
        builder: (context, dealSnapshot) {
          if (dealSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dealSnapshot.hasError) {
            return Center(child: Text('Lỗi: ${dealSnapshot.error}'));
          }

          final deals = dealSnapshot.data ?? [];
          if (deals.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder<List<GroupBuyListItem>>(
            future: _loadProductsForDeals(deals),
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = GroupBuyUtils.applyFilter(
                itemSnapshot.data ?? const [],
                _filter,
              );

              return Column(
                children: [
                  _buildIntroBanner(),
                  _buildFilterBar(),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có deal phù hợp bộ lọc',
                              style: TextStyle(color: Color(0xFF667085)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _GroupDealProductCard(
                                item: items[index],
                                onOpen: () => _openDetail(items[index]),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEDF89)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm mọi người đang tham gia',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Bạn muốn tham gia nhóm có sẵn hay tạo nhóm mới cho từng sản phẩm?',
            style: TextStyle(color: Color(0xFF667085), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_2_outlined, size: 88, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có deal mua nhóm',
            style: TextStyle(fontSize: 18, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy quay lại sau hoặc seed dữ liệu mẫu từ trang chủ.',
            style: TextStyle(color: Color(0xFF98A2B3)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(
                label: 'Sắp kết thúc',
                selected: _filter.endingSoonOnly,
                onTap: () => setState(() {
                  _filter = GroupBuyFilter(
                    category: _filter.category,
                    minDiscountPercent: _filter.minDiscountPercent,
                    maxMembersNeeded: _filter.maxMembersNeeded,
                    endingSoonOnly: !_filter.endingSoonOnly,
                    minPrice: _filter.minPrice,
                    maxPrice: _filter.maxPrice,
                  );
                }),
              ),
              _filterChip(
                label: 'Giảm ≥ 15%',
                selected: _filter.minDiscountPercent == 15,
                onTap: () => setState(() {
                  _filter = GroupBuyFilter(
                    category: _filter.category,
                    minDiscountPercent:
                        _filter.minDiscountPercent == 15 ? null : 15,
                    maxMembersNeeded: _filter.maxMembersNeeded,
                    endingSoonOnly: _filter.endingSoonOnly,
                    minPrice: _filter.minPrice,
                    maxPrice: _filter.maxPrice,
                  );
                }),
              ),
              _filterChip(
                label: 'Thiếu ≤ 5 người',
                selected: _filter.maxMembersNeeded == 5,
                onTap: () => setState(() {
                  _filter = GroupBuyFilter(
                    category: _filter.category,
                    minDiscountPercent: _filter.minDiscountPercent,
                    maxMembersNeeded:
                        _filter.maxMembersNeeded == 5 ? null : 5,
                    endingSoonOnly: _filter.endingSoonOnly,
                    minPrice: _filter.minPrice,
                    maxPrice: _filter.maxPrice,
                  );
                }),
              ),
              _filterChip(
                label: 'Giá < 5 triệu',
                selected: _filter.maxPrice == 5000000,
                onTap: () => setState(() {
                  _filter = GroupBuyFilter(
                    category: _filter.category,
                    minDiscountPercent: _filter.minDiscountPercent,
                    maxMembersNeeded: _filter.maxMembersNeeded,
                    endingSoonOnly: _filter.endingSoonOnly,
                    minPrice: _filter.minPrice,
                    maxPrice: _filter.maxPrice == 5000000 ? null : 5000000,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory ?? 'Tất cả',
            decoration: const InputDecoration(
              labelText: 'Danh mục sản phẩm',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _filter = GroupBuyFilter(
                  category: value == null || value == 'Tất cả' ? null : value,
                  minDiscountPercent: _filter.minDiscountPercent,
                  maxMembersNeeded: _filter.maxMembersNeeded,
                  endingSoonOnly: _filter.endingSoonOnly,
                  minPrice: _filter.minPrice,
                  maxPrice: _filter.maxPrice,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFF6ED),
      checkmarkColor: const Color(0xFFF79009),
    );
  }

  Future<List<GroupBuyListItem>> _loadProductsForDeals(
    List<GroupBuy> deals,
  ) async {
    final productIds = deals.map((deal) => deal.productId).toSet();
    final products = <String, Product>{};

    for (final productId in productIds) {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();
      if (doc.exists) {
        products[productId] = Product.fromFirestore(doc);
      }
    }

    final grouped = <String, List<GroupBuy>>{};
    for (final deal in deals) {
      grouped.putIfAbsent(deal.productId, () => []).add(deal);
    }

    final items = <GroupBuyListItem>[];
    for (final entry in grouped.entries) {
      final product = products[entry.key];
      if (product == null) continue;
      final bestDeal = GroupBuyUtils.pickBestOpenDeal(entry.value) ??
          entry.value.first;
      items.add(GroupBuyListItem(deal: bestDeal, product: product));
    }
    return items;
  }

  void _openDetail(GroupBuyListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupBuyDetailScreen(
          groupBuy: item.deal,
          product: item.product,
        ),
      ),
    );
  }
}

class _GroupDealProductCard extends StatelessWidget {
  const _GroupDealProductCard({
    required this.item,
    required this.onOpen,
  });

  final GroupBuyListItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final deal = item.deal;
    final product = item.product;
    final groupBuyService = context.watch<GroupBuyService>();
    final userId = context.watch<AuthService>().currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<GroupBuy>>(
          stream: groupBuyService.watchDealsForProduct(product.id),
          builder: (context, snapshot) {
            final deals = GroupBuyUtils.sortDealsForDisplay(
              snapshot.data ?? const [],
              currentUserId: userId,
            );
            final myDeal = GroupBuyUtils.findUserDeal(deals, userId);
            final otherOpenDeals = deals
                .where((d) =>
                    d.isJoinable &&
                    (myDeal == null || d.id != myDeal.id) &&
                    !d.includesUser(userId ?? ''))
                .toList();
            final displayDeal = myDeal ?? deal;
            final hasOpenGroups = otherOpenDeals.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: ProductImage(
                            product: product,
                            fit: BoxFit.cover,
                            iconSize: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GroupBuyStatusChip(deal: myDeal ?? deal),
                          const Spacer(),
                          Text(
                            '${deal.currentBuyerCount} người đang tham gia',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giá gốc: ${GroupBuyUtils.formatPrice(displayDeal.resolvedOriginalPrice)}đ',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF98A2B3),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Giá nhóm: ${GroupBuyUtils.formatPrice(displayDeal.resolvedGroupPrice)}đ • Giảm ${displayDeal.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFFD92D20),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GroupBuyHighlightPanel(deal: displayDeal, compact: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GroupBuyActionButtons(
                  hasOpenGroups: hasOpenGroups,
                  onJoin: () => showJoinGroupsSheet(
                    context: context,
                    product: product,
                    deals: deals,
                    userId: userId,
                  ),
                  onCreate: () {
                    if (myDeal != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bạn đã có nhóm cho sản phẩm này.',
                          ),
                        ),
                      );
                      return;
                    }
                    GroupBuyFlow.createGroup(context, product: product);
                  },
                ),
                if (myDeal != null) ...[
                  const SizedBox(height: 12),
                  YourGroupCard(
                    deal: myDeal,
                    onInvite: () => openInviteSheet(
                      context,
                      deal: myDeal,
                      product: product,
                      isCreator: myDeal.isOwnedBy(userId),
                    ),
                    onCopyLink: () => copyGroupDealLink(context, myDeal),
                    onViewDetails: onOpen,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
