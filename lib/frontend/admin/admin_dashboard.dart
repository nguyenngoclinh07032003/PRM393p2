import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/models/order.dart' as models;
import '../../backend/models/product.dart';
import '../widgets/product_image.dart';
import 'admin_navigation.dart';
import 'admin_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) => const AdminDashboardBody();
}

class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({super.key, this.onAddProduct});

  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection(AppConstants.productsCollection).snapshots(),
      builder: (context, productsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection(AppConstants.ordersCollection).snapshots(),
          builder: (context, ordersSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  firestore.collection(AppConstants.usersCollection).snapshots(),
              builder: (context, usersSnapshot) {
                if (productsSnapshot.hasError ||
                    ordersSnapshot.hasError ||
                    usersSnapshot.hasError) {
                  return AdminPage(
                    title: 'Dashboard Tổng Quan',
                    child: AdminEmptyState(
                      message:
                          'Không tải được dữ liệu.\n'
                          '${productsSnapshot.error ?? ordersSnapshot.error ?? usersSnapshot.error}',
                      icon: Icons.error_outline,
                    ),
                  );
                }

                final products = (productsSnapshot.data?.docs ?? [])
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();
                final orderDocs = ordersSnapshot.data?.docs ?? [];
                final users = usersSnapshot.data?.docs ?? [];

                final orders = orderDocs
                    .map((doc) => models.Order.fromFirestore(doc))
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final newOrders = orders
                    .where((o) => o.status == AppConstants.orderPending)
                    .length;
                final totalRevenue = orders.fold<double>(
                  0,
                  (sum, o) => sum + o.totalPrice,
                );
                final customers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['role'] == AppConstants.roleCustomer;
                }).length;

                final isLoading = productsSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    ordersSnapshot.connectionState == ConnectionState.waiting;

                return AdminPage(
                  title: 'Dashboard Tổng Quan',
                  subtitle:
                      'Chào mừng trở lại. Đây là tình hình cửa hàng hôm nay.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLoading && !productsSnapshot.hasData)
                        const LinearProgressIndicator(minHeight: 2),
                      if (isLoading && !productsSnapshot.hasData)
                        const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            AdminStatCard(
                              label: 'Tổng doanh thu',
                              value:
                                  '${AdminTheme.formatCurrency(totalRevenue)}đ',
                              icon: Icons.payments_outlined,
                              trend: '+12.5%',
                            ),
                            AdminStatCard(
                              label: 'Đơn hàng mới',
                              value: '$newOrders',
                              icon: Icons.receipt_long_outlined,
                              trend: '+5.2%',
                            ),
                            AdminStatCard(
                              label: 'Khách hàng',
                              value: '$customers',
                              icon: Icons.people_alt_outlined,
                              trend: '+8.1%',
                            ),
                            AdminStatCard(
                              label: 'Lượt truy cập',
                              value: '${45231 + products.length * 17}',
                              icon: Icons.trending_up,
                              trend: '-2.4%',
                              trendUp: false,
                            ),
                          ];

                          if (constraints.maxWidth < 900) {
                            return Column(
                              children: cards
                                  .map((c) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: c,
                                      ))
                                  .toList(),
                            );
                          }

                          return Row(
                            children: cards
                                .map((c) => Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 14),
                                        child: c,
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final topProducts =
                              _TopProductsPanel(products: products);
                          final recentOrders = _RecentOrdersPanel(
                            orders: orders.take(6).toList(),
                          );

                          if (constraints.maxWidth < 900) {
                            return Column(
                              children: [
                                topProducts,
                                const SizedBox(height: 16),
                                recentOrders,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: topProducts),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: recentOrders),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          AdminPrimaryButton(
                            label: 'Thêm sản phẩm',
                            onPressed: () {
                              if (onAddProduct != null) {
                                onAddProduct!();
                                return;
                              }
                              AdminNavigation.navigate(
                                context,
                                AppRoutes.adminAddProduct,
                              );
                            },
                          ),
                          AdminSecondaryButton(
                            label: 'Xem đơn hàng',
                            icon: Icons.receipt_long_outlined,
                            onPressed: () => AdminNavigation.navigate(
                              context,
                              AppRoutes.adminOrders,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  const _TopProductsPanel({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final active = products
        .where((p) => p.status == AppConstants.productActive)
        .take(6)
        .toList();

    return AdminPanel(
      title: 'Sản phẩm bán chạy',
      trailing: TextButton(
        onPressed: () =>
            AdminNavigation.navigate(context, AppRoutes.adminProducts),
        child: const Text('Xem tất cả'),
      ),
      child: active.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có sản phẩm',
                style: TextStyle(color: AdminTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < active.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AdminTheme.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: ProductImage(
                              product: active[i],
                              fit: BoxFit.cover,
                              iconSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                active[i].category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${AdminTheme.formatCurrency(active[i].finalPrice)}đ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AdminTheme.accent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders});

  final List<models.Order> orders;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Đơn hàng gần đây',
      trailing: TextButton(
        onPressed: () =>
            AdminNavigation.navigate(context, AppRoutes.adminOrders),
        child: const Text('Xem tất cả'),
      ),
      child: orders.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có đơn hàng',
                style: TextStyle(color: AdminTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AdminTheme.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AdminTheme.accent.withValues(alpha: 0.15),
                          child: Text(
                            '#${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.accentDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đơn #${orders[i].id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${AdminTheme.formatCurrency(orders[i].totalPrice)}đ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AdminOrderStatusBadge(status: orders[i].status),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
