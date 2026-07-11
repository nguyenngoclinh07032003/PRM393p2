import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../backend/config/app_constants.dart';
import '../../../backend/models/flash_sale.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/pricing_utils.dart';
import '../../widgets/flash_sale_countdown.dart';
import '../../widgets/product_image.dart';
import '../products/product_detail_screen.dart';

class FlashSaleScreen extends StatefulWidget {
  const FlashSaleScreen({super.key});

  @override
  State<FlashSaleScreen> createState() => _FlashSaleScreenState();
}

class _FlashSaleScreenState extends State<FlashSaleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Sale Giờ Vàng'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.flashSalesCollection)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải Flash Sale: ${snapshot.error}'));
          }

          final sales = (snapshot.data?.docs ?? [])
              .map((doc) => FlashSale.fromFirestore(doc))
              .where((sale) => sale.isVisibleToUsers)
              .toList()
            ..sort((a, b) {
              final now = DateTime.now();
              final aStart = a.countdownStartAt(now) ?? a.endTime;
              final bStart = b.countdownStartAt(now) ?? b.endTime;
              return aStart.compareTo(bStart);
            });

          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 92,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có Flash Sale trong thời gian này',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kiểm tra lại ngày chiến dịch và khung giờ sale.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) => _FlashSaleCard(
              flashSale: sales[index],
              formatCurrency: _formatCurrency,
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}đ';
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({
    required this.flashSale,
    required this.formatCurrency,
  });

  final FlashSale flashSale;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final phase = flashSale.countdownPhase(now);
    final slotRange = flashSale.highlightedSlotRange(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade500],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flashSale.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Giảm ${flashSale.discountPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (flashSale.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              flashSale.note.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                          Text(
                            flashSale.formatCampaignRange(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (flashSale.timeSlots.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Khung giờ: ${flashSale.timeSlotsSummary}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (phase == FlashSaleCountdownPhase.upcomingSlot ||
                              phase == FlashSaleCountdownPhase.beforeCampaign)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Chưa tới giờ sale — đồng hồ đếm tới lúc bắt đầu',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.red),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FlashSaleCountdown(
                          startTime: flashSale.countdownStartAt(now),
                          endTime: flashSale.countdownEndAt(now),
                          phase: phase,
                          slotRangeText: slotRange,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sản phẩm áp dụng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (flashSale.isAllProduct)
                  const Text(
                    'Áp dụng cho tất cả sản phẩm',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (flashSale.productIds.isEmpty)
                  const Text('Chưa chọn sản phẩm cho Flash Sale này.')
                else
                  ...flashSale.productIds.map(
                    (productId) => _FlashSaleProductTile(
                      productId: productId,
                      flashSale: flashSale,
                      formatCurrency: formatCurrency,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleProductTile extends StatelessWidget {
  const _FlashSaleProductTile({
    required this.productId,
    required this.flashSale,
    required this.formatCurrency,
  });

  final String productId;
  final FlashSale flashSale;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }

        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final product = Product.fromFirestore(productSnapshot.data!);
        final regularPrice = PricingUtils.regularUnitPrice(
          listedPrice: product.price,
          salePrice: product.salePrice,
        );
        final isLive = flashSale.isActive;
        final displayPrice = isLive
            ? PricingUtils.resolveUnitPrice(
                listedPrice: product.price,
                salePrice: product.salePrice,
                flashSale: flashSale,
                productId: product.id,
              )
            : regularPrice;
        final showDiscount = isLive && displayPrice < regularPrice;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _ProductThumb(product: product),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDiscount)
                  Text(
                    formatCurrency(regularPrice),
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                Text(
                  formatCurrency(displayPrice),
                  style: TextStyle(
                    color: showDiscount ? Colors.red : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (!isLive && flashSale.isVisibleToUsers)
                  const Text(
                    'Giá flash sale khi khung giờ bắt đầu',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mua ngay'),
            ),
          ),
        );
      },
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ProductImage(
        product: product,
        fit: BoxFit.cover,
        iconSize: 40,
      ),
    );
  }
}
