import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String sellerId;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final Map<String, dynamic> deliveryInfo;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'cod',
    this.deliveryInfo = const {},
    required this.createdAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentMethod: data['paymentMethod'] ?? 'cod',
      deliveryInfo: Map<String, dynamic>.from(data['deliveryInfo'] ?? const {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sellerId': sellerId,
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'deliveryInfo': deliveryInfo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderItem(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  double get totalPrice => price * quantity;
}
