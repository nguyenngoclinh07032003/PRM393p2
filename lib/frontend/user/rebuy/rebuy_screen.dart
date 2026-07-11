import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/rebuy_stat.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/pricing_utils.dart';
import '../../../backend/utils/rebuy_flow.dart';
import '../../widgets/product_image.dart';
import '../products/product_detail_screen.dart';

class RebuyScreen extends StatelessWidget {
  const RebuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua lại sản phẩm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.rebuyStatsCollection)
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có sản phẩm nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy mua sắm để xem gợi ý mua lại',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final rebuyStats = snapshot.data!.docs
              .map((doc) => RebuyStat.fromFirestore(doc))
              .where((stat) => stat.buyCount > 0)
              .toList()
            ..sort((a, b) => b.buyCount.compareTo(a.buyCount));

          if (rebuyStats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lịch sử mua hàng',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gợi ý sẽ hiện sau khi bạn đặt hàng',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rebuyStats.length,
            itemBuilder: (context, index) {
              final rebuyStat = rebuyStats[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(AppConstants.productsCollection)
                    .doc(rebuyStat.productId)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final product = Product.fromFirestore(productSnapshot.data!);
                  if (product.status != AppConstants.productActive) {
                    return const SizedBox.shrink();
                  }

                  final displayPrice = PricingUtils.regularUnitPrice(
                    listedPrice: product.price,
                    salePrice: product.salePrice,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ProductImage(
                                    product: product,
                                    fit: BoxFit.cover,
                                    iconSize: 40,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${displayPrice.toStringAsFixed(0)}đ',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.refresh,
                                                  size: 16,
                                                  color:
                                                      Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Đã mua ${rebuyStat.buyCount} lần',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.green.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (rebuyStat.shouldRebuy)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '⭐ Nên mua lại',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.orange.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  RebuyFlow.addToCartAndCheckout(
                                    context: context,
                                    userId: userId,
                                    items: [
                                      (
                                        productId: product.id,
                                        quantity: 1,
                                      ),
                                    ],
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Mua lại'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
