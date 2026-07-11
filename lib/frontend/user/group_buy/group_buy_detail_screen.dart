import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../../backend/utils/group_buy_utils.dart';
import '../../widgets/product_image.dart';
import 'group_buy_flow.dart';
import 'group_buy_join_groups_sheet.dart';
import 'group_buy_share_sheet.dart';
import 'group_buy_widgets.dart';

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
  bool _isLoading = false;

  GroupBuyService get _groupBuyService => context.read<GroupBuyService>();

  Future<void> _createNewGroup() async {
    setState(() => _isLoading = true);
    await GroupBuyFlow.createGroup(context, product: widget.product);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _joinGroupBuy(GroupBuy deal) async {
    setState(() => _isLoading = true);
    await GroupBuyFlow.joinGroup(
      context,
      product: widget.product,
      deal: deal,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _copyDealLink(GroupBuy deal) async {
    final url = GroupBuyUtils.buildShareUrl(deal);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép liên kết nhóm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Chi tiết deal nhóm'),
        backgroundColor: const Color(0xFFF79009),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<GroupBuy>>(
        stream: _groupBuyService.watchDealsForProduct(widget.product.id),
        builder: (context, snapshot) {
          final deals = GroupBuyUtils.sortDealsForDisplay(
            snapshot.data ?? const [],
            currentUserId: userId,
          );
          final myDeal = GroupBuyUtils.findUserDeal(deals, userId);
          final otherDeals = deals
              .where((deal) => myDeal == null || deal.id != myDeal.id)
              .where((deal) => deal.isJoinable)
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 260,
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
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giá nhóm: ${GroupBuyUtils.formatPrice(GroupBuyFlow.previewDeal(widget.product).resolvedGroupPrice)}đ',
                        style: const TextStyle(
                          color: Color(0xFFD92D20),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (myDeal != null) ...[
                        YourGroupCard(
                          deal: myDeal,
                          onInvite: () => showGroupBuyInviteSheet(
                            context: context,
                            deal: myDeal,
                            product: widget.product,
                            mode: myDeal.isOwnedBy(userId)
                                ? GroupBuyInviteMode.created
                                : GroupBuyInviteMode.joined,
                          ),
                          onCopyLink: () => _copyDealLink(myDeal),
                        ),
                        const SizedBox(height: 18),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFEDF89)),
                          ),
                          child: const Text(
                            'Bạn muốn tham gia nhóm có sẵn hay tạo nhóm mới?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB54708),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (otherDeals.isNotEmpty) ...[
                        const Text(
                          'Các nhóm khác đang tuyển thành viên',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...otherDeals.map(
                          (deal) => OtherGroupCard(
                            deal: deal,
                            isLoading: _isLoading,
                            joinDisabled: myDeal != null,
                            onJoin: () => _joinGroupBuy(deal),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (myDeal == null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _createNewGroup,
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo nhóm mới'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF79009),
                              side: const BorderSide(color: Color(0xFFFEDF89)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      const Text(
                        'Mô tả sản phẩm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.product.description),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<List<GroupBuy>>(
        stream: _groupBuyService.watchDealsForProduct(widget.product.id),
        builder: (context, snapshot) {
          final deals = snapshot.data ?? const [];
          final myDeal = GroupBuyUtils.findUserDeal(deals, userId);
          final bestDeal = GroupBuyUtils.pickBestOpenDeal(
            deals.where((deal) => myDeal == null || deal.id != myDeal.id).toList(),
          );

          if (myDeal != null) {
            return _bottomBar(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _copyDealLink(myDeal),
                    child: const Text('Sao chép liên kết'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () => showGroupBuyInviteSheet(
                              context: context,
                              deal: myDeal,
                              product: widget.product,
                              mode: myDeal.isOwnedBy(userId)
                                  ? GroupBuyInviteMode.created
                                  : GroupBuyInviteMode.joined,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF79009),
                    ),
                    child: const Text('Mời bạn bè'),
                  ),
                ),
              ],
            );
          }

          return _bottomBar(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _createNewGroup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF79009),
                    side: const BorderSide(color: Color(0xFFFEDF89)),
                  ),
                  child: const Text('Tạo nhóm mới'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: (_isLoading || bestDeal == null)
                      ? null
                      : () => showJoinGroupsSheet(
                            context: context,
                            product: widget.product,
                            deals: deals,
                            userId: userId,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF79009),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Tham gia nhóm'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomBar({required List<Widget> children}) {
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
      child: Row(children: children),
    );
  }
}
