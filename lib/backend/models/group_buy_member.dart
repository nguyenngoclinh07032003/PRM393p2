import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';

class GroupBuyMember {
  final String id;
  final String groupDealId;
  final String userId;
  final int quantity;
  final String paymentStatus;
  final DateTime joinedAt;
  final String status;

  GroupBuyMember({
    required this.id,
    required this.groupDealId,
    required this.userId,
    this.quantity = 1,
    this.paymentStatus = AppConstants.paymentUnpaid,
    required this.joinedAt,
    this.status = AppConstants.statusActive,
  });

  factory GroupBuyMember.fromFirestore(
    DocumentSnapshot doc, {
    required String groupDealId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupBuyMember(
      id: doc.id,
      groupDealId: groupDealId,
      userId: data['userId'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      paymentStatus: data['paymentStatus'] ?? AppConstants.paymentUnpaid,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? AppConstants.statusActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'quantity': quantity,
      'paymentStatus': paymentStatus,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
    };
  }
}
