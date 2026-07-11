import 'package:flutter/material.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/group_buy_utils.dart';

class GroupBuyDialogResult {
  final int quantity;

  const GroupBuyDialogResult({required this.quantity});
}

Future<GroupBuyDialogResult?> showCreateGroupDialog({
  required BuildContext context,
  required Product product,
  required GroupBuy dealPreview,
}) {
  var quantity = 1;

  return showDialog<GroupBuyDialogResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tạo nhóm mua mới'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giá nhóm: ${GroupBuyUtils.formatPrice(dealPreview.resolvedGroupPrice)}đ',
                  style: const TextStyle(color: Color(0xFFD92D20)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cần ${dealPreview.minimumMember} người • '
                  'Thời hạn ${AppConstants.groupBuyDurationHours} giờ',
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số lượng mua'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: quantity <
                                  AppConstants.groupBuyMaxQuantityPerMember
                              ? () => setState(() => quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  GroupBuyDialogResult(quantity: quantity),
                ),
                child: const Text('Tạo nhóm'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<GroupBuyDialogResult?> showJoinGroupDialog({
  required BuildContext context,
  required GroupBuy deal,
  required Product product,
}) {
  var quantity = 1;

  return showDialog<GroupBuyDialogResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tham gia nhóm mua'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.groupName ?? product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(GroupBuyUtils.formatParticipants(deal)),
                Text(GroupBuyUtils.formatMembersNeeded(deal)),
                const SizedBox(height: 6),
                Text(
                  'Giá ưu đãi: ${GroupBuyUtils.formatPrice(deal.resolvedGroupPrice)}đ',
                  style: const TextStyle(
                    color: Color(0xFFD92D20),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                GroupBuyCountdownLabel(endTime: deal.endTime),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số lượng mua'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: quantity <
                                  AppConstants.groupBuyMaxQuantityPerMember
                              ? () => setState(() => quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: deal.isJoinable
                    ? () => Navigator.pop(
                          context,
                          GroupBuyDialogResult(quantity: quantity),
                        )
                    : null,
                child: const Text('Xác nhận tham gia'),
              ),
            ],
          );
        },
      );
    },
  );
}

class GroupBuyCountdownLabel extends StatefulWidget {
  const GroupBuyCountdownLabel({super.key, required this.endTime});

  final DateTime endTime;

  @override
  State<GroupBuyCountdownLabel> createState() => _GroupBuyCountdownLabelState();
}

class _GroupBuyCountdownLabelState extends State<GroupBuyCountdownLabel> {
  @override
  Widget build(BuildContext context) {
    final remaining = widget.endTime.difference(DateTime.now());
    return Text(
      'Thời gian còn lại: ${GroupBuyUtils.formatCountdown(remaining.isNegative ? Duration.zero : remaining)}',
      style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
    );
  }
}
