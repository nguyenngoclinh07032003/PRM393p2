import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  final List<String> orderIds;

  const OrderSuccessScreen({
    super.key,
    required this.orderIds,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultipleOrders = orderIds.length > 1;
    final hasOrder = orderIds.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hasMultipleOrders
                    ? 'Đã tạo ${orderIds.length} đơn hàng!'
                    : 'Đặt hàng thành công!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (hasMultipleOrders)
                ...orderIds.map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Mã đơn: #${_shortOrderId(id)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else if (hasOrder)
                Text(
                  'Mã đơn hàng: #${_shortOrderId(orderIds.first)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                )
              else
                Text(
                  'Không có mã đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng của bạn đang được xử lý',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.orders),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Xem đơn hàng',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortOrderId(String id) {
    return id.substring(0, id.length < 8 ? id.length : 8);
  }
}
