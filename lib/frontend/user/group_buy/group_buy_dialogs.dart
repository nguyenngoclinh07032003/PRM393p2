import 'package:flutter/material.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/group_buy_utils.dart';
import '../../widgets/product_image.dart';

class GroupBuyDialogResult {
  final int quantity;
  final String? groupName;
  final int minMembers;
  final int maxMembers;
  final int durationHours;

  const GroupBuyDialogResult({
    required this.quantity,
    this.groupName,
    required this.minMembers,
    required this.maxMembers,
    required this.durationHours,
  });
}

Future<GroupBuyDialogResult?> showCreateGroupDialog({
  required BuildContext context,
  required Product product,
  required GroupBuy dealPreview,
}) {
  var quantity = 1;
  var minMembers = AppConstants.groupBuyDefaultMinMembers;
  var maxMembers = AppConstants.groupBuyDefaultMaxMembers;
  var durationHours = AppConstants.groupBuyDurationHours;
  final groupNameController = TextEditingController();

  return showModalBottomSheet<GroupBuyDialogResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF9FAFB),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          void syncMaxMembers() {
            if (maxMembers < minMembers) {
              maxMembers = minMembers;
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cấu hình nhóm mua',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thiết lập thông tin nhóm trước khi mời bạn bè tham gia.',
                    style: TextStyle(color: Color(0xFF667085), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: ProductImage(
                              product: product,
                              fit: BoxFit.cover,
                              iconSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                'Giá gốc: ${GroupBuyUtils.formatPrice(dealPreview.resolvedOriginalPrice)}đ',
                                style: const TextStyle(
                                  color: Color(0xFF98A2B3),
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                'Giá nhóm: ${GroupBuyUtils.formatPrice(dealPreview.resolvedGroupPrice)}đ',
                                style: const TextStyle(
                                  color: Color(0xFFD92D20),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên nhóm (tuỳ chọn)',
                      hintText: 'VD: Nhóm săn ${product.name}',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StepperRow(
                    label: 'Số người tối thiểu',
                    value: minMembers,
                    min: 2,
                    max: 100,
                    onChanged: (value) => setState(() {
                      minMembers = value;
                      syncMaxMembers();
                    }),
                  ),
                  const SizedBox(height: 12),
                  _StepperRow(
                    label: 'Số người tối đa',
                    value: maxMembers,
                    min: minMembers,
                    max: 100,
                    onChanged: (value) => setState(() => maxMembers = value),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thời hạn nhóm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [24, 48, 72].map((hours) {
                      final selected = durationHours == hours;
                      return ChoiceChip(
                        label: Text('$hours giờ'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => durationHours = hours),
                        selectedColor: const Color(0xFFFFF6ED),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFFB54708)
                              : const Color(0xFF667085),
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _StepperRow(
                    label: 'Số lượng mua của bạn',
                    value: quantity,
                    min: 1,
                    max: AppConstants.groupBuyMaxQuantityPerMember,
                    onChanged: (value) => setState(() => quantity = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(
                            context,
                            GroupBuyDialogResult(
                              quantity: quantity,
                              groupName: groupNameController.text.trim(),
                              minMembers: minMembers,
                              maxMembers: maxMembers,
                              durationHours: durationHours,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF79009),
                          ),
                          child: const Text('Tạo nhóm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
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
                          GroupBuyDialogResult(
                            quantity: quantity,
                            minMembers: deal.minimumMember,
                            maxMembers: deal.maximumMember,
                            durationHours: AppConstants.groupBuyDurationHours,
                          ),
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
