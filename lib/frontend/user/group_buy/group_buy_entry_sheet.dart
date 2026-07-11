import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
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

Future<void> showGroupBuyEntrySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF9FAFB),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _GroupBuyEntrySheetBody(scrollController: scrollController);
        },
      );
    },
  );
}

class _GroupBuyEntrySheetBody extends StatelessWidget {
  const _GroupBuyEntrySheetBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final groupBuyService = context.watch<GroupBuyService>();
    final userId = context.watch<AuthService>().currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mua nhóm nhận deal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'Các sản phẩm mọi người đang tham gia mua nhóm. '
                'Bạn muốn tham gia nhóm có sẵn hay tạo nhóm mới?',
                style: TextStyle(color: Color(0xFF667085), height: 1.45),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GroupBuy>>(
            stream: groupBuyService.getActiveGroupBuys(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final deals = snapshot.data ?? [];
              if (deals.isEmpty) {
                return _EmptyEntryState(
                  onExplore: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.groupBuy);
                  },
                );
              }

              return FutureBuilder<List<_EntryItem>>(
                future: _loadEntryItems(deals),
                builder: (context, itemSnapshot) {
                  if (itemSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = itemSnapshot.data ?? const [];
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, AppRoutes.groupBuy);
                            },
                            child: const Text('Xem tất cả deal nhóm'),
                          ),
                        );
                      }

                      return _EntryProductSection(
                        item: items[index],
                        userId: userId,
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

  Future<List<_EntryItem>> _loadEntryItems(List<GroupBuy> deals) async {
    final grouped = <String, List<GroupBuy>>{};
    for (final deal in deals) {
      grouped.putIfAbsent(deal.productId, () => []).add(deal);
    }

    final items = <_EntryItem>[];
    for (final entry in grouped.entries) {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(entry.key)
          .get();
      if (!doc.exists) continue;

      final product = Product.fromFirestore(doc);
      final sorted = GroupBuyUtils.sortDealsForDisplay(entry.value);
      final featured = GroupBuyUtils.pickBestOpenDeal(sorted) ?? sorted.first;
      items.add(
        _EntryItem(product: product, featuredDeal: featured, deals: sorted),
      );
    }

    items.sort((a, b) => b.featuredDeal.currentBuyerCount
        .compareTo(a.featuredDeal.currentBuyerCount));
    return items;
  }
}

class _EntryItem {
  final Product product;
  final GroupBuy featuredDeal;
  final List<GroupBuy> deals;

  const _EntryItem({
    required this.product,
    required this.featuredDeal,
    required this.deals,
  });
}

class _EntryProductSection extends StatelessWidget {
  const _EntryProductSection({
    required this.item,
    required this.userId,
  });

  final _EntryItem item;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final featuredDeal = item.featuredDeal;
    final groupBuyService = context.watch<GroupBuyService>();

    return StreamBuilder<List<GroupBuy>>(
      stream: groupBuyService.watchDealsForProduct(product.id),
      builder: (context, snapshot) {
        final deals = GroupBuyUtils.sortDealsForDisplay(
          snapshot.data ?? item.deals,
          currentUserId: userId,
        );
        final myDeal = GroupBuyUtils.findUserDeal(deals, userId);
        final otherOpenDeals = deals
            .where((d) =>
                d.isJoinable &&
                (myDeal == null || d.id != myDeal.id) &&
                !d.includesUser(userId ?? ''))
            .toList();
        final displayDeal = myDeal ?? featuredDeal;
        final hasOpenGroups = otherOpenDeals.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupBuyProductInfoPanel(
                product: product,
                deal: displayDeal,
              ),
              const SizedBox(height: 16),
              GroupBuyActionButtons(
                hasOpenGroups: hasOpenGroups,
                onJoin: () {
                  if (userId == null) {
                    _requireLogin(context);
                    return;
                  }
                  showJoinGroupsSheet(
                    context: context,
                    product: product,
                    deals: deals,
                    userId: userId,
                  );
                },
                onCreate: () {
                  if (userId == null) {
                    _requireLogin(context);
                    return;
                  }
                  if (myDeal != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bạn đã có nhóm cho sản phẩm này. '
                          'Hãy mời thêm bạn bè hoặc tham gia nhóm khác.',
                        ),
                      ),
                    );
                    return;
                  }
                  GroupBuyFlow.createGroup(context, product: product);
                },
              ),
              if (myDeal != null) ...[
                const SizedBox(height: 14),
                YourGroupCard(
                  deal: myDeal,
                  onInvite: () => openInviteSheet(
                    context,
                    deal: myDeal,
                    product: product,
                    isCreator: myDeal.isOwnedBy(userId),
                  ),
                  onCopyLink: () => copyGroupDealLink(context, myDeal),
                  onViewDetails: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupBuyDetailScreen(
                          groupBuy: myDeal,
                          product: product,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

void _requireLogin(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Vui lòng đăng nhập để tham gia mua nhóm')),
  );
}

class _EmptyEntryState extends StatelessWidget {
  const _EmptyEntryState({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Chưa có nhóm nào đang mở',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy khám phá trang mua nhóm để tạo nhóm mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF79009),
              ),
              child: const Text('Khám phá deal nhóm'),
            ),
          ],
        ),
      ),
    );
  }
}
