import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String userId;
  final String sellerId;
  final String medicineId;
  final String medicineName;
  final double price;
  final String imageUrl;
  final int quantity;
  final DateTime addedAt;
  final String? groupBuyId;

  CartItem({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.medicineId,
    required this.medicineName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.addedAt,
    this.groupBuyId,
  });

  bool get isGroupBuyItem => groupBuyId != null && groupBuyId!.isNotEmpty;

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      medicineId: data['medicineId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      quantity: data['quantity'] ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      groupBuyId: data['groupBuyId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sellerId': sellerId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
      if (groupBuyId != null) 'groupBuyId': groupBuyId,
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? sellerId,
    String? medicineId,
    String? medicineName,
    double? price,
    String? imageUrl,
    int? quantity,
    DateTime? addedAt,
    String? groupBuyId,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      groupBuyId: groupBuyId ?? this.groupBuyId,
    );
  }

  double get totalPrice => price * quantity;
}
