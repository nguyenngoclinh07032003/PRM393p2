import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/models/order.dart' as models;
import 'admin_theme.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const ManageOrdersBody();
}

class ManageOrdersBody extends StatelessWidget {
  const ManageOrdersBody({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return AdminPage(
            title: 'Bảng Quản Lý Đơn Hàng',
            child: AdminEmptyState(
              message: 'Lỗi: ${snapshot.error}',
              icon: Icons.error_outline,
            ),
          );
        }

        final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        final orders = docs.map(models.Order.fromFirestore).toList();

        return AdminPage(
          title: 'Bảng Quản Lý Đơn Hàng',
          subtitle: 'Theo dõi và cập nhật trạng thái đơn hàng',
          actions: [
            AdminSecondaryButton(
              label: 'Xuất dữ liệu',
              icon: Icons.download_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng xuất dữ liệu đang phát triển'),
                  ),
                );
              },
            ),
          ],
          child: orders.isEmpty
              ? const AdminEmptyState(
                  message: 'Chưa có đơn hàng nào',
                  icon: Icons.receipt_long_outlined,
                )
              : AdminDataTableWrap(
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Mã đơn')),
                      DataColumn(label: Text('Khách hàng')),
                      DataColumn(label: Text('Ngày đặt')),
                      DataColumn(label: Text('Tổng tiền')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: orders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                color: AdminTheme.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              order.userId.length > 10
                                  ? '${order.userId.substring(0, 10)}...'
                                  : order.userId,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(Text(_formatDate(order.createdAt))),
                          DataCell(
                            Text(
                              '${AdminTheme.formatCurrency(order.totalPrice)}đ',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataCell(AdminOrderStatusBadge(status: order.status)),
                          DataCell(
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _updateOrderStatus(order.id, value),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: AppConstants.orderConfirmed,
                                  child: Text('Xác nhận'),
                                ),
                                PopupMenuItem(
                                  value: AppConstants.orderShipping,
                                  child: Text('Đang giao'),
                                ),
                                PopupMenuItem(
                                  value: AppConstants.orderDelivered,
                                  child: Text('Đã giao'),
                                ),
                                PopupMenuItem(
                                  value: AppConstants.orderCancelled,
                                  child: Text('Hủy đơn'),
                                ),
                              ],
                              child: const Icon(Icons.more_horiz),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({'status': newStatus});
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
