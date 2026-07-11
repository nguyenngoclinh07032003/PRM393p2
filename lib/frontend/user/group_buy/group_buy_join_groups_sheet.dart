import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/group_buy_utils.dart';
import 'group_buy_flow.dart';
import 'group_buy_share_sheet.dart';
import 'group_buy_widgets.dart';

Future<void> showJoinGroupsSheet({
  required BuildContext context,
  required Product product,
  required List<GroupBuy> deals,
  String? userId,
}) {
  final openDeals = deals
      .where((deal) => deal.isJoinable && !deal.includesUser(userId ?? ''))
      .toList()
    ..sort((a, b) {
      final fillA = a.currentBuyerCount / a.maximumMember;
      final fillB = b.currentBuyerCount / b.maximumMember;
      return fillB.compareTo(fillA);
    });

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF9FAFB),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Chọn nhóm để tham gia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: openDeals.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Chưa có nhóm nào đang mở cho sản phẩm này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF667085)),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: openDeals.length,
                        itemBuilder: (context, index) {
                          final deal = openDeals[index];
                          return _JoinGroupListTile(
                            deal: deal,
                            onJoin: () async {
                              Navigator.pop(context);
                              await GroupBuyFlow.joinGroup(
                                context,
                                product: product,
                                deal: deal,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _JoinGroupListTile extends StatelessWidget {
  const _JoinGroupListTile({
    required this.deal,
    required this.onJoin,
  });

  final GroupBuy deal;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deal.groupName ?? 'Nhóm ${deal.groupCode ?? deal.id.substring(0, 6)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              '${deal.currentBuyerCount}/${deal.maximumMember} người',
              style: const TextStyle(
                color: Color(0xFFB54708),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              deal.remainingMembers > 0
                  ? 'Còn thiếu ${deal.remainingMembers} người'
                  : 'Đã đủ chỗ',
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
            const SizedBox(height: 4),
            GroupBuyCountdown(
              endTime: deal.endTime,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: deal.isJoinable ? onJoin : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF79009),
                ),
                child: const Text('Tham gia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> copyGroupDealLink(BuildContext context, GroupBuy deal) async {
  final url = GroupBuyUtils.buildShareUrl(deal);
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết nhóm')),
    );
  }
}

Future<void> openInviteSheet(
  BuildContext context, {
  required GroupBuy deal,
  required Product product,
  required bool isCreator,
}) {
  return showGroupBuyInviteSheet(
    context: context,
    deal: deal,
    product: product,
    mode: isCreator ? GroupBuyInviteMode.created : GroupBuyInviteMode.joined,
  );
}
