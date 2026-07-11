import 'package:cloud_firestore/cloud_firestore.dart';

class GroupBuy {
  final String id;
  final String productId;
  final int currentBuyerCount;
  final double priceUnder50;
  final double priceFrom50;
  final double priceFrom100;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<String> participantIds;

  GroupBuy({
    required this.id,
    required this.productId,
    this.currentBuyerCount = 0,
    required this.priceUnder50,
    required this.priceFrom50,
    required this.priceFrom100,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
    this.participantIds = const [],
  });

  factory GroupBuy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupBuy(
      id: doc.id,
      productId: data['productId'] ?? '',
      currentBuyerCount: data['currentBuyerCount'] ?? 0,
      priceUnder50: (data['priceUnder50'] ?? 0).toDouble(),
      priceFrom50: (data['priceFrom50'] ?? 0).toDouble(),
      priceFrom100: (data['priceFrom100'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      participantIds: List<String>.from(data['participantIds'] ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'currentBuyerCount': currentBuyerCount,
      'priceUnder50': priceUnder50,
      'priceFrom50': priceFrom50,
      'priceFrom100': priceFrom100,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'participantIds': participantIds,
    };
  }

  // Calculate current price based on buyer count
  double get currentPrice {
    if (currentBuyerCount >= 100) {
      return priceFrom100;
    } else if (currentBuyerCount >= 50) {
      return priceFrom50;
    } else {
      return priceUnder50;
    }
  }

  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && 
           now.isAfter(startTime) && 
           now.isBefore(endTime);
  }
}
