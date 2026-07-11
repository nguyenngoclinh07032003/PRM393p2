import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/services/auth_service.dart';
import 'add_seller_product_screen.dart';
import 'configure_flash_sale_screen.dart';
import 'manage_seller_products_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_revenue_report_screen.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.productsCollection)
            .where('sellerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, productSnapshot) {
          final productCount = productSnapshot.data?.docs.length ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.ordersCollection)
                .where('sellerId', isEqualTo: userId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              final orders = orderSnapshot.data?.docs ?? [];
              final orderCount = orders.length;
              final totalRevenue = orders.fold<double>(0, (sum, doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['status'] != AppConstants.orderDelivered) return sum;
                return sum + ((data['totalPrice'] ?? 0) as num).toDouble();
              });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Tổng quan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Doanh thu',
                          value: _formatCurrency(totalRevenue),
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Đơn hàng',
                          value: orderCount.toString(),
                          icon: Icons.shopping_cart,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Sản phẩm',
                          value: productCount.toString(),
                          icon: Icons.inventory,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quản lý',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Quản lý sản phẩm',
                    subtitle: 'Thêm, sửa, xóa sản phẩm của bạn',
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageSellerProductsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Thêm sản phẩm mới',
                    subtitle: 'Đăng bán sản phẩm mới',
                    icon: Icons.add_box,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddSellerProductScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Cấu hình Flash Sale',
                    subtitle: 'Tạo khuyến mãi khung giờ vàng',
                    icon: Icons.flash_on,
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfigureFlashSaleScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Quản lý đơn hàng',
                    subtitle: 'Xem và xử lý đơn hàng',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerOrdersScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Báo cáo doanh thu',
                    subtitle: 'Xem thống kê và doanh thu',
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerRevenueReportScreen(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

String _formatCurrency(double value) {
  final text = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  return '${text}đ';
}
