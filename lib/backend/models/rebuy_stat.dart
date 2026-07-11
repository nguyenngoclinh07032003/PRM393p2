import 'package:cloud_firestore/cloud_firestore.dart';

class RebuyStat {
  final String id;
  final String userId;
  final String productId;
  final int buyCount;
  final DateTime lastBuyAt;
  final int averageDays;

  RebuyStat({
    required this.id,
    required this.userId,
    required this.productId,
    required this.buyCount,
    required this.lastBuyAt,
    this.averageDays = 0,
  });

  factory RebuyStat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RebuyStat(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      buyCount: data['buyCount'] ?? 0,
      lastBuyAt: (data['lastBuyAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      averageDays: data['averageDays'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'buyCount': buyCount,
      'lastBuyAt': Timestamp.fromDate(lastBuyAt),
      'averageDays': averageDays,
    };
  }

  // Check if user should rebuy based on average days
  bool get shouldRebuy {
    if (buyCount < 2 || averageDays <= 0) return false;
    final daysSinceLastBuy = DateTime.now().difference(lastBuyAt).inDays;
    return daysSinceLastBuy >= averageDays;
  }
}
