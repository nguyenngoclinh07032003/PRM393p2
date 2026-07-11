import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/group_buy.dart';

class GroupBuyJoinResult {
  final double unitPrice;
  final int buyerCount;

  const GroupBuyJoinResult({
    required this.unitPrice,
    required this.buyerCount,
  });
}

class GroupBuyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GroupBuy>> getActiveGroupBuys() {
    return _firestore
        .collection(AppConstants.groupBuysCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupBuy.fromFirestore(doc))
            .where((gb) => gb.isActive)
            .toList());
  }

  Future<GroupBuy?> getGroupBuyForProduct(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.groupBuysCollection)
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'active')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final groupBuy = GroupBuy.fromFirestore(snapshot.docs.first);
        return groupBuy.isActive ? groupBuy : null;
      }
      return null;
    } catch (e) {
      debugPrint('Get group buy error: $e');
      return null;
    }
  }

  Future<bool> hasUserJoined(String groupBuyId, String userId) async {
    final doc = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .doc(groupBuyId)
        .get();
    if (!doc.exists) return false;
    final participants =
        List<String>.from(doc.data()?['participantIds'] ?? const []);
    return participants.contains(userId);
  }

  Future<GroupBuyJoinResult> joinGroupBuy({
    required String groupBuyId,
    required String userId,
    required String productId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final groupBuyRef =
          _firestore.collection(AppConstants.groupBuysCollection).doc(groupBuyId);
      final productRef =
          _firestore.collection(AppConstants.productsCollection).doc(productId);

      final groupBuySnap = await transaction.get(groupBuyRef);
      final productSnap = await transaction.get(productRef);

      if (!groupBuySnap.exists) {
        throw Exception('Chương trình mua nhóm không tồn tại');
      }
      if (!productSnap.exists) {
        throw Exception('Sản phẩm không còn tồn tại');
      }

      final groupBuy = GroupBuy.fromFirestore(groupBuySnap);
      if (!groupBuy.isActive) {
        throw Exception('Chương trình mua nhóm đã kết thúc');
      }

      final participants =
          List<String>.from(groupBuySnap.data()?['participantIds'] ?? const []);
      if (participants.contains(userId)) {
        throw Exception('Bạn đã tham gia chương trình này');
      }

      final stock = (productSnap.data()?['stock'] as num?)?.toInt() ?? 0;
      if (stock < 1) {
        throw Exception('Sản phẩm đã hết hàng');
      }

      final status = productSnap.data()?['status'] as String? ?? '';
      if (status != AppConstants.productActive) {
        throw Exception('Sản phẩm không còn bán');
      }

      final newBuyerCount = groupBuy.currentBuyerCount + 1;
      final unitPrice = _priceForBuyerCount(groupBuy, newBuyerCount);

      transaction.update(groupBuyRef, {
        'currentBuyerCount': FieldValue.increment(1),
        'participantIds': FieldValue.arrayUnion([userId]),
      });

      return GroupBuyJoinResult(
        unitPrice: unitPrice,
        buyerCount: newBuyerCount,
      );
    });
  }

  Future<void> leaveGroupBuy({
    required String groupBuyId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref =
          _firestore.collection(AppConstants.groupBuysCollection).doc(groupBuyId);
      final snap = await transaction.get(ref);
      if (!snap.exists) return;

      final participants =
          List<String>.from(snap.data()?['participantIds'] ?? const []);
      if (!participants.contains(userId)) return;

      transaction.update(ref, {
        'currentBuyerCount': FieldValue.increment(-1),
        'participantIds': FieldValue.arrayRemove([userId]),
      });
    });
  }

  Future<String?> createGroupBuy(GroupBuy groupBuy) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.groupBuysCollection)
          .add(groupBuy.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Create group buy error: $e');
      rethrow;
    }
  }

  double calculateGroupBuyPrice(GroupBuy groupBuy) {
    return groupBuy.currentPrice;
  }

  static double _priceForBuyerCount(GroupBuy groupBuy, int buyerCount) {
    if (buyerCount >= AppConstants.groupBuyThreshold100) {
      return groupBuy.priceFrom100;
    }
    if (buyerCount >= AppConstants.groupBuyThreshold50) {
      return groupBuy.priceFrom50;
    }
    return groupBuy.priceUnder50;
  }
}
