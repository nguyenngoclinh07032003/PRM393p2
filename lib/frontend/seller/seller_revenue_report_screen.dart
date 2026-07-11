import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/services/auth_service.dart';

class SellerRevenueReportScreen extends StatelessWidget {
  const SellerRevenueReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.ordersCollection)
            .where('sellerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final orders = snapshot.data?.docs ?? [];
          var deliveredRevenue = 0.0;
          var pendingRevenue = 0.0;

          for (final doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final total = _readDouble(data['totalPrice']);
            if (data['status'] == AppConstants.orderDelivered) {
              deliveredRevenue += total;
            } else {
              pendingRevenue += total;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReportCard(
                title: 'Doanh thu đã hoàn thành',
                value: _formatCurrency(deliveredRevenue),
                icon: Icons.payments,
                color: Colors.green,
              ),
              _ReportCard(
                title: 'Doanh thu đang xử lý',
                value: _formatCurrency(pendingRevenue),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _ReportCard(
                title: 'Tổng số đơn hàng',
                value: orders.length.toString(),
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
