import 'dart:async';
import 'package:flutter/material.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/group_buy_utils.dart';
import '../../widgets/product_image.dart';

class GroupBuyCountdown extends StatefulWidget {
  const GroupBuyCountdown({
    super.key,
    required this.endTime,
    this.style,
    this.prefix = 'Còn lại ',
  });

  final DateTime endTime;
  final TextStyle? style;
  final String prefix;

  @override
  State<GroupBuyCountdown> createState() => _GroupBuyCountdownState();
}

class _GroupBuyCountdownState extends State<GroupBuyCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.endTime.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _remaining.isNegative ? Duration.zero : _remaining;
    return Text(
      '${widget.prefix}${GroupBuyUtils.formatCountdown(duration)}',
      style: widget.style,
    );
  }
}

class GroupBuyProgressBar extends StatelessWidget {
  const GroupBuyProgressBar({
    super.key,
    required this.deal,
    this.height = 8,
    this.color = Colors.orange,
  });

  final GroupBuy deal;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = deal.maximumMember <= 0
        ? 0.0
        : (deal.currentBuyerCount / deal.maximumMember).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        color: color,
      ),
    );
  }
}

class GroupBuyStatusChip extends StatelessWidget {
  const GroupBuyStatusChip({super.key, required this.deal});

  final GroupBuy deal;

  Color get _color {
    switch (deal.lifecycleStatus) {
      case AppConstants.groupDealAlmostFull:
        return const Color(0xFFF79009);
      case AppConstants.groupDealFull:
      case AppConstants.groupDealSuccess:
        return const Color(0xFF12B76A);
      case AppConstants.groupDealExpired:
      case AppConstants.groupDealFailed:
        return const Color(0xFFF04438);
      default:
        return const Color(0xFF1570EF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        deal.lifecycleStatusLabel,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class GroupBuyHighlightPanel extends StatelessWidget {
  const GroupBuyHighlightPanel({
    super.key,
    required this.deal,
    this.compact = false,
  });

  final GroupBuy deal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEDF89)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GroupBuyUtils.formatParticipants(deal),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 14,
              color: const Color(0xFFB54708),
            ),
          ),
          const SizedBox(height: 6),
          GroupBuyCountdown(
            endTime: deal.endTime,
            style: TextStyle(
              color: const Color(0xFF667085),
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            GroupBuyUtils.formatDiscount(deal),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 14,
              color: const Color(0xFFD92D20),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            GroupBuyProgressBar(deal: deal),
            const SizedBox(height: 6),
            Text(
              GroupBuyUtils.formatMembersNeeded(deal),
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GroupBuyPriceRow extends StatelessWidget {
  const GroupBuyPriceRow({super.key, required this.deal});

  final GroupBuy deal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${GroupBuyUtils.formatPrice(deal.resolvedOriginalPrice)}đ',
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Color(0xFF98A2B3),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${GroupBuyUtils.formatPrice(deal.resolvedGroupPrice)}đ',
          style: const TextStyle(
            color: Color(0xFFD92D20),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3F2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '-${deal.discountPercent.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Color(0xFFD92D20),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class GroupBuyProductInfoPanel extends StatelessWidget {
  const GroupBuyProductInfoPanel({
    super.key,
    required this.product,
    required this.deal,
    this.imageSize = 88,
  });

  final Product product;
  final GroupBuy deal;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: imageSize,
            height: imageSize,
            child: ProductImage(
              product: product,
              fit: BoxFit.cover,
              iconSize: imageSize * 0.4,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _infoLine(
                'Giá gốc: ${GroupBuyUtils.formatPrice(deal.resolvedOriginalPrice)}đ',
                const Color(0xFF98A2B3),
                lineThrough: true,
              ),
              _infoLine(
                'Giá nhóm: ${GroupBuyUtils.formatPrice(deal.resolvedGroupPrice)}đ',
                const Color(0xFFD92D20),
                bold: true,
              ),
              _infoLine(
                'Giảm: ${deal.discountPercent.toStringAsFixed(0)}%',
                const Color(0xFFD92D20),
                bold: true,
              ),
              const SizedBox(height: 4),
              Text(
                GroupBuyUtils.formatParticipants(deal),
                style: const TextStyle(
                  color: Color(0xFFB54708),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              GroupBuyCountdown(
                endTime: deal.endTime,
                prefix: 'Còn lại ',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(String text, Color color, {bool bold = false, bool lineThrough = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          decoration: lineThrough ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

class GroupBuyActionButtons extends StatelessWidget {
  const GroupBuyActionButtons({
    super.key,
    required this.hasOpenGroups,
    required this.onJoin,
    required this.onCreate,
  });

  final bool hasOpenGroups;
  final VoidCallback onJoin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final joinPrimary = hasOpenGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          joinPrimary
              ? 'Tham gia nhóm có sẵn hoặc tạo nhóm mới cho riêng bạn.'
              : 'Chưa có nhóm khác đang mở. Bạn vẫn có thể tạo nhóm mới.',
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: joinPrimary
                  ? FilledButton(
                      onPressed: onJoin,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF79009),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tham gia nhóm'),
                    )
                  : OutlinedButton(
                      onPressed: onJoin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF79009),
                        side: const BorderSide(color: Color(0xFFF79009)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tham gia nhóm'),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: !joinPrimary
                  ? FilledButton(
                      onPressed: onCreate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF79009),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tạo nhóm mới'),
                    )
                  : OutlinedButton(
                      onPressed: onCreate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF79009),
                        side: const BorderSide(color: Color(0xFFF79009)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tạo nhóm mới'),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class YourGroupCard extends StatelessWidget {
  const YourGroupCard({
    super.key,
    required this.deal,
    required this.onInvite,
    required this.onCopyLink,
    this.onViewDetails,
  });

  final GroupBuy deal;
  final VoidCallback onInvite;
  final VoidCallback onCopyLink;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF79009), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF79009).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF79009),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'NHÓM CỦA BẠN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deal.groupName ?? 'Nhóm của bạn',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            GroupBuyUtils.formatParticipants(deal),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFB54708),
            ),
          ),
          const SizedBox(height: 8),
          GroupBuyProgressBar(deal: deal, color: const Color(0xFFF79009)),
          const SizedBox(height: 8),
          GroupBuyCountdown(
            endTime: deal.endTime,
            prefix: 'Còn lại: ',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Giá nhóm: ${GroupBuyUtils.formatPrice(deal.resolvedGroupPrice)}đ',
            style: const TextStyle(
              color: Color(0xFFD92D20),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            GroupBuyUtils.formatMembersNeeded(deal),
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onInvite,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF79009),
                ),
                child: const Text('Mời bạn bè'),
              ),
              OutlinedButton(
                onPressed: onCopyLink,
                child: const Text('Sao chép link'),
              ),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('Xem chi tiết nhóm'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class OtherGroupCard extends StatelessWidget {
  const OtherGroupCard({
    super.key,
    required this.deal,
    required this.onJoin,
    this.isLoading = false,
    this.joinDisabled = false,
  });

  final GroupBuy deal;
  final VoidCallback? onJoin;
  final bool isLoading;
  final bool joinDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deal.groupName ?? 'Nhóm đang mở',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(GroupBuyUtils.formatParticipants(deal)),
          const SizedBox(height: 4),
          Text(
            deal.remainingMembers > 0
                ? 'Chỉ còn thiếu ${deal.remainingMembers} người'
                : 'Nhóm đã đủ người',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 6),
          GroupBuyCountdown(
            endTime: deal.endTime,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: (joinDisabled || isLoading || !deal.isJoinable)
                  ? null
                  : onJoin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF79009),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Tham gia nhóm'),
            ),
          ),
        ],
      ),
    );
  }
}
