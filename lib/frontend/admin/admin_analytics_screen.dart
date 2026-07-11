import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../backend/config/app_constants.dart';
import 'admin_theme.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminAnalyticsBody();
}

class AdminAnalyticsBody extends StatelessWidget {
  const AdminAnalyticsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .snapshots(),
      builder: (context, ordersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.productsCollection)
              .snapshots(),
          builder: (context, productsSnapshot) {
            final orders = ordersSnapshot.data?.docs ?? [];
            final products = productsSnapshot.data?.docs ?? [];

            final totalRevenue = orders.fold<double>(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              return sum + ((data['totalPrice'] ?? 0) as num).toDouble();
            });

            final categoryCounts = <String, int>{};
            for (final doc in products) {
              final data = doc.data() as Map<String, dynamic>;
              final category = (data['category'] as String?)?.trim();
              if (category == null || category.isEmpty) continue;
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }

            return AdminPage(
              title: 'Phân Tích & Báo Cáo',
              subtitle: 'Doanh thu và phân bổ sản phẩm theo danh mục',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chart = _RevenueChart(revenue: totalRevenue);
                  final sideStats = Column(
                    children: [
                      AdminStatCard(
                        label: 'Tổng doanh thu',
                        value: '${AdminTheme.formatCurrency(totalRevenue)}đ',
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 12),
                      AdminStatCard(
                        label: 'Tổng đơn hàng',
                        value: '${orders.length}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(height: 12),
                      AdminStatCard(
                        label: 'Sản phẩm',
                        value: '${products.length}',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ],
                  );

                  final categoryPanel =
                      _CategoryDonutPanel(categoryCounts: categoryCounts);

                  if (constraints.maxWidth < 960) {
                    return Column(
                      children: [
                        chart,
                        const SizedBox(height: 16),
                        sideStats,
                        const SizedBox(height: 16),
                        categoryPanel,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: chart),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: sideStats),
                        ],
                      ),
                      const SizedBox(height: 16),
                      categoryPanel,
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.revenue});

  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo thời gian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _RevenueLinePainter(revenue: revenue),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueLinePainter extends CustomPainter {
  _RevenueLinePainter({required this.revenue});

  final double revenue;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AdminTheme.accent.withValues(alpha: 0.35),
          AdminTheme.accent.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = AdminTheme.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    final base = revenue <= 0 ? 1.0 : revenue;
    for (var i = 0; i < 8; i++) {
      final x = size.width * i / 7;
      final wave = 0.55 + 0.45 * ((i % 3) / 2);
      final y = size.height - (size.height * 0.15) -
          (size.height * 0.65 * wave * (0.4 + (i + 1) / 10));
      points.add(Offset(x, y.clamp(12.0, size.height - 8)));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(
        point,
        4,
        Paint()..color = AdminTheme.accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueLinePainter oldDelegate) {
    return oldDelegate.revenue != revenue;
  }
}

class _CategoryDonutPanel extends StatelessWidget {
  const _CategoryDonutPanel({required this.categoryCounts});

  final Map<String, int> categoryCounts;

  static const _colors = [
    Color(0xFF24C7E8),
    Color(0xFF7A5AF8),
    Color(0xFFF79009),
    Color(0xFF12B76A),
    Color(0xFFF04438),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AdminPanel(
      title: 'Sản phẩm theo phân loại',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: entries.isEmpty
            ? const Text(
                'Chưa có dữ liệu danh mục',
                style: TextStyle(color: AdminTheme.textSecondary),
              )
            : Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        values: entries.map((e) => e.value.toDouble()).toList(),
                        colors: _colors,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _colors[i % _colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entries[i].key} (${entries[i].value})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var start = -3.14 / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 3.14 * 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;
      canvas.drawArc(rect.deflate(11), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
