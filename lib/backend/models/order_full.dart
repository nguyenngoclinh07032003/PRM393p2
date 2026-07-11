import 'order.dart';
import 'pharmacy.dart';

// Extended order model with full details including pharmacy info
class OrderFull {
  final Order order;
  final Pharmacy pharmacy;
  final String userName;
  final String? shipperName;

  OrderFull({
    required this.order,
    required this.pharmacy,
    required this.userName,
    this.shipperName,
  });
}
