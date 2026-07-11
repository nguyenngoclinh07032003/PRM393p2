import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/services/auth_service.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của shop'),
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
          if (orders.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? AppConstants.orderPending;
              final total = ((data['totalPrice'] ?? 0) as num).toDouble();

              return Card(
                child: ListTile(
                  title: Text('Đơn #${_shortId(doc.id)}'),
                  subtitle: Text('Trạng thái: $status'),
                  trailing: Text(_formatCurrency(total)),
                  onTap: () =>
                      _showStatusDialog(context, doc.id, status.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    String orderId,
    String currentStatus,
  ) async {
    final statuses = [
      AppConstants.orderPending,
      AppConstants.orderConfirmed,
      AppConstants.orderShipping,
      AppConstants.orderDelivered,
      AppConstants.orderCancelled,
    ];
    var selected = currentStatus;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cập nhật đơn hàng'),
          content: DropdownButtonFormField<String>(
            initialValue: statuses.contains(selected)
                ? selected
                : AppConstants.orderPending,
            items: statuses
                .map((status) =>
                    DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (value) => setState(() => selected = value ?? selected),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave == true) {
      await FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({'status': selected});
    }
  }

  String _shortId(String id) => id.substring(0, id.length < 8 ? id.length : 8);
}

String _formatCurrency(double value) {
  final text = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  return '${text}đ';
}
