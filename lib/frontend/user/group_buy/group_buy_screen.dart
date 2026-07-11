import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../widgets/product_image.dart';
import 'group_buy_detail_screen.dart';

class GroupBuyScreen extends StatelessWidget {
  const GroupBuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua nhóm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.groupBuysCollection)
            .where('status', isEqualTo: 'active')
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
                  Icon(Icons.group, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có chương trình mua nhóm',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final groupBuy = GroupBuy.fromFirestore(doc);

              // Check if still active
              if (!groupBuy.isActive) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(AppConstants.productsCollection)
                    .doc(groupBuy.productId)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final product = Product.fromFirestore(productSnapshot.data!);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupBuyDetailScreen(
                              groupBuy: groupBuy,
                              product: product,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            child: ProductImage(
                              product: product,
                              fit: BoxFit.cover,
                              iconSize: 80,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '🔥 MUA NHÓM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Product Name
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Current Buyers
                                Row(
                                  children: [
                                    Icon(Icons.group, color: Colors.orange[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${groupBuy.currentBuyerCount} người đã tham gia',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Price Table
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildPriceRow(
                                        '< 50 người:',
                                        groupBuy.priceUnder50,
                                        groupBuy.currentBuyerCount < 50,
                                      ),
                                      const Divider(),
                                      _buildPriceRow(
                                        '50-99 người:',
                                        groupBuy.priceFrom50,
                                        groupBuy.currentBuyerCount >= 50 &&
                                            groupBuy.currentBuyerCount < 100,
                                      ),
                                      const Divider(),
                                      _buildPriceRow(
                                        '≥ 100 người:',
                                        groupBuy.priceFrom100,
                                        groupBuy.currentBuyerCount >= 100,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Current Price
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Giá hiện tại:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${groupBuy.currentPrice.toStringAsFixed(0)}đ',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Join Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GroupBuyDetailScreen(
                                            groupBuy: groupBuy,
                                            product: product,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Text(
                                      'Tham gia ngay',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildPriceRow(String label, double price, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.orange[900] : Colors.grey[700],
          ),
        ),
        Text(
          '${price.toStringAsFixed(0)}đ',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.red : Colors.grey[700],
            fontSize: isActive ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
