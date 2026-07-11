import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/data/quality_commitment_data.dart';
import '../../../backend/models/flash_sale.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/services/group_buy_service.dart';
import '../../../backend/utils/group_buy_utils.dart';
import '../group_buy/group_buy_widgets.dart';

class HomeBenefitStrip extends StatelessWidget {
  const HomeBenefitStrip({
    super.key,
    required this.onGroupBuyTap,
    required this.onFlashSaleTap,
    required this.onQualityCommitmentTap,
  });

  final VoidCallback onGroupBuyTap;
  final VoidCallback onFlashSaleTap;
  final VoidCallback onQualityCommitmentTap;

  @override
  Widget build(BuildContext context) {
    final cards = [
      GroupBuyBenefitCard(onTap: onGroupBuyTap),
      FlashSaleBenefitCard(onTap: onFlashSaleTap),
      QualityCommitmentBenefitCard(onTap: onQualityCommitmentTap),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(cards.length, (index) {
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == cards.length - 1 ? 0 : 14),
                child: cards[index],
              ),
            );
          }),
        );
      },
    );
  }
}

class _BenefitShell extends StatelessWidget {
  const _BenefitShell({
    required this.onTap,
    required this.gradient,
    required this.child,
    this.borderRadius = 16,
    this.boxShadow,
  });

  final VoidCallback onTap;
  final Gradient gradient;
  final Widget child;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GroupBuyBenefitCard extends StatelessWidget {
  const GroupBuyBenefitCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF1CB5C9), Color(0xFF0B7A8C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final groupBuyService = context.watch<GroupBuyService>();

    return StreamBuilder<List<GroupBuy>>(
      stream: groupBuyService.getActiveGroupBuys(),
      builder: (context, snapshot) {
        final deals = snapshot.data ?? const [];
        final maxDiscount = GroupBuyUtils.maxDiscountAmong(deals);
        final featured = GroupBuyUtils.pickBestOpenDeal(deals);
        final discountLabel = maxDiscount > 0
            ? 'Tiết kiệm đến ${maxDiscount.toStringAsFixed(0)}%'
            : 'Tiết kiệm đến 20%';

        return _BenefitShell(
          onTap: onTap,
          gradient: _gradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_3_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mua nhóm nhận deal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mua càng đông, giá càng tốt hơn.',
                          style: TextStyle(
                            color: Color(0xFFDFF7FB),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GlassChip(
                    label: discountLabel,
                    foreground: Colors.white,
                    background: Colors.white.withValues(alpha: 0.16),
                  ),
                  _GlassChip(
                    label: 'Mở deal cùng bạn bè',
                    foreground: Colors.white,
                    background: Colors.white.withValues(alpha: 0.16),
                  ),
                ],
              ),
              if (featured != null) ...[
                const SizedBox(height: 12),
                _GroupBuyStatusBox(deal: featured),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF085A68).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Khám phá deal nhóm →',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupBuyStatusBox extends StatelessWidget {
  const _GroupBuyStatusBox({required this.deal});

  final GroupBuy deal;

  @override
  Widget build(BuildContext context) {
    final progress = deal.maximumMember <= 0
        ? 0.0
        : (deal.currentBuyerCount / deal.maximumMember).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEDF89)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFFDE4C3),
                  color: const Color(0xFF0B7A8C),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B7A8C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${deal.currentBuyerCount}/${deal.maximumMember} người tham gia',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  GroupBuyUtils.formatDiscount(deal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          GroupBuyCountdown(
            endTime: deal.endTime,
            prefix: 'Còn lại ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class FlashSaleBenefitCard extends StatelessWidget {
  const FlashSaleBenefitCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFFF6B4A), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.flashSalesCollection)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final sales = (snapshot.data?.docs ?? [])
            .map((doc) => FlashSale.fromFirestore(doc))
            .where((sale) => sale.isVisibleToUsers)
            .toList();
        final sale = pickFeaturedFlashSale(sales, now);
        final endTime = sale?.countdownEndAt(now);
        final startTime = sale?.countdownStartAt(now);

        return _BenefitShell(
          onTap: onTap,
          gradient: _gradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flash sale mỗi ngày',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ưu đãi công nghệ theo khung giờ.',
                          style: TextStyle(
                            color: Color(0xFFFFE4EC),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FlashSaleCountdownBoxes(
                target: endTime ?? startTime,
                fallback: const Duration(hours: 2, minutes: 15, seconds: 30),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _GlassChip(
                    label: 'Giá cực sốc',
                    icon: Icons.local_fire_department_outlined,
                    foreground: Colors.white,
                    background: Color(0x33FFFFFF),
                  ),
                  _GlassChip(
                    label: 'Số lượng giới hạn',
                    icon: Icons.hourglass_bottom_outlined,
                    foreground: Colors.white,
                    background: Color(0x33FFFFFF),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

FlashSale? pickFeaturedFlashSale(List<FlashSale> sales, DateTime now) {
  FlashSale? active;
  FlashSale? upcoming;

  for (final sale in sales) {
    if (sale.isActive) {
      active = sale;
      break;
    }
    if (sale.isVisibleToUsers &&
        sale.countdownStartAt(now) != null &&
        upcoming == null) {
      upcoming = sale;
    }
  }

  if (active != null) return active;
  if (upcoming != null) return upcoming;

  for (final sale in sales) {
    if (sale.countdownStartAt(now) != null && sale.countdownEndAt(now) != null) {
      return sale;
    }
  }
  return null;
}

class _FlashSaleCountdownBoxes extends StatefulWidget {
  const _FlashSaleCountdownBoxes({
    required this.target,
    required this.fallback,
  });

  final DateTime? target;
  final Duration fallback;

  @override
  State<_FlashSaleCountdownBoxes> createState() =>
      _FlashSaleCountdownBoxesState();
}

class _FlashSaleCountdownBoxesState extends State<_FlashSaleCountdownBoxes> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final target = widget.target;
    setState(() {
      if (target == null) {
        _remaining = widget.fallback;
      } else {
        final diff = target.difference(DateTime.now());
        _remaining = diff.isNegative ? Duration.zero : diff;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FlashSaleCountdownBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeBox(hours.toString().padLeft(2, '0')),
        _colon(),
        _timeBox(minutes.toString().padLeft(2, '0')),
        _colon(),
        _timeBox(seconds.toString().padLeft(2, '0')),
      ],
    );
  }

  Widget _colon() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          ':',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      );

  Widget _timeBox(String value) {
    return Container(
      width: 46,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w900,
          fontSize: 18,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class QualityCommitmentBenefitCard extends StatelessWidget {
  const QualityCommitmentBenefitCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFECEFF3), Color(0xFFB8BEC8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final chips = QualityCommitmentData.commitmentChips;

    return _BenefitShell(
      onTap: onTap,
      gradient: _gradient,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFD0D5DD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF344054),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QualityCommitmentData.title,
                      style: TextStyle(
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Giao nhanh, đổi trả rõ ràng.',
                      style: TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips
                    .map(
                      (chip) => SizedBox(
                        width: itemWidth,
                        child: _SilverChip(label: chip.$1, icon: chip.$2),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Xem chính sách →',
              style: TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.check_circle_outline,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SilverChip extends StatelessWidget {
  const _SilverChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF475467)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
