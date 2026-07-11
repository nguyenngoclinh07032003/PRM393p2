import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/group_buy.dart';
import '../models/group_buy_member.dart';
import '../models/product.dart';
import '../utils/group_buy_utils.dart';

class GroupBuyJoinResult {
  final double unitPrice;
  final int buyerCount;
  final String lifecycleStatus;

  const GroupBuyJoinResult({
    required this.unitPrice,
    required this.buyerCount,
    required this.lifecycleStatus,
  });
}

class GroupBuyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<GroupBuy>> getActiveGroupBuys() {
    return _firestore
        .collection(AppConstants.groupBuysCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupBuy.fromFirestore(doc))
            .where((deal) => _isVisibleDeal(deal))
            .toList());
  }

  Stream<List<GroupBuy>> watchDealsForProduct(String productId) {
    return _firestore
        .collection(AppConstants.groupBuysCollection)
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupBuy.fromFirestore(doc))
            .where((deal) => _isVisibleDeal(deal))
            .toList());
  }

  Future<List<GroupBuy>> getDealsForProduct(String productId) async {
    final snapshot = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .where('productId', isEqualTo: productId)
        .get();
    return snapshot.docs
        .map((doc) => GroupBuy.fromFirestore(doc))
        .where((deal) => _isVisibleDeal(deal))
        .toList();
  }

  Future<GroupBuy?> getDealById(String dealId) async {
    final doc = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .doc(dealId)
        .get();
    if (!doc.exists) return null;
    return GroupBuy.fromFirestore(doc);
  }

  Future<GroupBuy?> getDealByShareToken(String shareToken) async {
    final snapshot = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .where('shareToken', isEqualTo: shareToken)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return GroupBuy.fromFirestore(snapshot.docs.first);
  }

  Future<GroupBuy?> getUserDealForProduct(
    String productId,
    String userId,
  ) async {
    final deals = await getDealsForProduct(productId);
    for (final deal in deals) {
      if (deal.isOwnedBy(userId) || deal.includesUser(userId)) {
        return deal;
      }
    }
    return null;
  }

  Future<GroupBuy?> getGroupBuyForProduct(String productId) async {
    final deals = await getDealsForProduct(productId);
    if (deals.isEmpty) return null;
    deals.sort((a, b) =>
        b.currentBuyerCount.compareTo(a.currentBuyerCount));
    return deals.first;
  }

  Future<bool> hasUserJoined(String groupBuyId, String userId) async {
    final memberRef = _memberRef(groupBuyId, userId);
    final memberSnap = await memberRef.get();
    if (memberSnap.exists) return true;

    final doc = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .doc(groupBuyId)
        .get();
    if (!doc.exists) return false;
    final participants =
        List<String>.from(doc.data()?['participantIds'] ?? const []);
    return participants.contains(userId);
  }

  Future<bool> hasUserJoinedProduct(String productId, String userId) async {
    final deals = await getDealsForProduct(productId);
    for (final deal in deals) {
      if (await hasUserJoined(deal.id, userId)) {
        return true;
      }
    }
    return false;
  }

  Future<GroupBuyJoinResult> joinGroupBuy({
    required String groupBuyId,
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    if (quantity < 1 || quantity > AppConstants.groupBuyMaxQuantityPerMember) {
      throw Exception(
        'Mỗi khách chỉ được mua tối đa '
        '${AppConstants.groupBuyMaxQuantityPerMember} sản phẩm trong một nhóm',
      );
    }

    final alreadyInProduct = await hasUserJoinedProduct(productId, userId);
    if (alreadyInProduct) {
      final joinedThis = await hasUserJoined(groupBuyId, userId);
      if (!joinedThis) {
        throw Exception(
          'Bạn đã tham gia một nhóm khác cho sản phẩm này',
        );
      }
    }

    return _firestore.runTransaction((transaction) async {
      final groupBuyRef =
          _firestore.collection(AppConstants.groupBuysCollection).doc(groupBuyId);
      final productRef =
          _firestore.collection(AppConstants.productsCollection).doc(productId);
      final memberRef = _memberRef(groupBuyId, userId);

      final groupBuySnap = await transaction.get(groupBuyRef);
      final productSnap = await transaction.get(productRef);
      final memberSnap = await transaction.get(memberRef);

      if (!groupBuySnap.exists) {
        throw Exception('Nhóm mua không tồn tại');
      }
      if (!productSnap.exists) {
        throw Exception('Sản phẩm không còn tồn tại');
      }

      final groupBuy = GroupBuy.fromFirestore(groupBuySnap);
      if (!groupBuy.isJoinable) {
        throw Exception('Nhóm này không còn nhận thành viên');
      }

      final participants =
          List<String>.from(groupBuySnap.data()?['participantIds'] ?? const []);
      if (participants.contains(userId) || memberSnap.exists) {
        throw Exception('Bạn đã tham gia nhóm này');
      }

      final stock = (productSnap.data()?['stock'] as num?)?.toInt() ?? 0;
      if (stock < quantity) {
        throw Exception('Sản phẩm không đủ hàng');
      }

      final productStatus = productSnap.data()?['status'] as String? ?? '';
      if (productStatus != AppConstants.productActive) {
        throw Exception('Sản phẩm không còn bán');
      }

      final newBuyerCount = groupBuy.currentBuyerCount + 1;
      if (newBuyerCount > groupBuy.maximumMember) {
        throw Exception('Nhóm đã đủ số người tối đa');
      }

      final unitPrice = _priceForBuyerCount(groupBuy, newBuyerCount);
      final nextStatus = _statusAfterJoin(groupBuy, newBuyerCount);

      transaction.update(groupBuyRef, {
        'currentBuyerCount': FieldValue.increment(1),
        'currentMember': FieldValue.increment(1),
        'participantIds': FieldValue.arrayUnion([userId]),
        'status': nextStatus,
      });

      transaction.set(memberRef, GroupBuyMember(
        id: userId,
        groupDealId: groupBuyId,
        userId: userId,
        quantity: quantity,
        joinedAt: DateTime.now(),
      ).toFirestore());

      return GroupBuyJoinResult(
        unitPrice: unitPrice,
        buyerCount: newBuyerCount,
        lifecycleStatus: nextStatus,
      );
    }).then((result) {
      notifyListeners();
      return result;
    });
  }

  Future<GroupBuy> createNewGroup({
    required String productId,
    required String creatorId,
    required Product product,
    String? groupName,
    String? creatorDisplayName,
    int? minimumMember,
    int? maximumMember,
    Duration? duration,
    int quantity = 1,
  }) async {
    final alreadyJoined = await hasUserJoinedProduct(productId, creatorId);
    if (alreadyJoined) {
      throw Exception('Bạn đã tham gia một nhóm cho sản phẩm này');
    }

    final minMembers = minimumMember ?? AppConstants.groupBuyDefaultMinMembers;
    final maxMembers = maximumMember ?? AppConstants.groupBuyDefaultMaxMembers;
    if (minMembers > maxMembers) {
      throw Exception('Số người tối thiểu không thể lớn hơn số người tối đa');
    }

    final original = product.price;
    final groupPrice = (original * 0.8).roundToDouble();
    final now = DateTime.now();
    final end = now.add(
      duration ?? const Duration(hours: AppConstants.groupBuyDurationHours),
    );
    final shareToken = GroupBuyUtils.generateShareToken();
    final groupCode = GroupBuyUtils.generateGroupCode(shareToken);
    final displayName = creatorDisplayName?.trim().isNotEmpty == true
        ? creatorDisplayName!.trim()
        : 'Bạn';

    final deal = GroupBuy(
      id: '',
      productId: productId,
      groupName: groupName?.trim().isNotEmpty == true
          ? groupName!.trim()
          : 'Nhóm $displayName - ${product.name}',
      creatorId: creatorId,
      minimumMember: minMembers,
      maximumMember: maxMembers,
      originalPrice: original,
      groupPrice: groupPrice,
      priceUnder50: original,
      priceFrom50: (original * 0.9).roundToDouble(),
      priceFrom100: groupPrice,
      startTime: now,
      endTime: end,
      status: AppConstants.groupDealRecruiting,
      participantIds: [creatorId],
      currentBuyerCount: 1,
      groupCode: groupCode,
      shareToken: shareToken,
    );

    final docRef = await _firestore
        .collection(AppConstants.groupBuysCollection)
        .add(deal.toFirestore());

    await _memberRef(docRef.id, creatorId).set(GroupBuyMember(
      id: creatorId,
      groupDealId: docRef.id,
      userId: creatorId,
      quantity: quantity,
      joinedAt: DateTime.now(),
    ).toFirestore());

    final created = await getDealById(docRef.id);
    if (created == null) {
      throw Exception('Không thể tải nhóm vừa tạo');
    }
    notifyListeners();
    return created;
  }

  Future<void> leaveGroupBuy({
    required String groupBuyId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref =
          _firestore.collection(AppConstants.groupBuysCollection).doc(groupBuyId);
      final memberRef = _memberRef(groupBuyId, userId);
      final snap = await transaction.get(ref);
      if (!snap.exists) return;

      final participants =
          List<String>.from(snap.data()?['participantIds'] ?? const []);
      if (!participants.contains(userId)) return;

      final groupBuy = GroupBuy.fromFirestore(snap);
      final newCount = (groupBuy.currentBuyerCount - 1).clamp(0, 999999);

      transaction.update(ref, {
        'currentBuyerCount': newCount,
        'currentMember': newCount,
        'participantIds': FieldValue.arrayRemove([userId]),
        'status': _statusAfterLeave(groupBuy, newCount),
      });
      transaction.delete(memberRef);
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

  DocumentReference<Map<String, dynamic>> _memberRef(
    String groupBuyId,
    String userId,
  ) {
    return _firestore
        .collection(AppConstants.groupBuysCollection)
        .doc(groupBuyId)
        .collection(AppConstants.groupBuyMembersSubcollection)
        .doc(userId);
  }

  bool _isVisibleDeal(GroupBuy deal) {
    const hidden = {
      AppConstants.groupDealCancelled,
      AppConstants.groupDealPaid,
      AppConstants.groupDealFailed,
    };
    if (hidden.contains(deal.status)) return false;
    if (deal.isExpired) {
      return deal.lifecycleStatus == AppConstants.groupDealSuccess;
    }
    return deal.isWithinSchedule || deal.isJoinable;
  }

  static String _statusAfterJoin(GroupBuy deal, int newCount) {
    if (newCount >= deal.maximumMember) {
      return AppConstants.groupDealFull;
    }
    if (newCount >= deal.minimumMember) {
      return AppConstants.groupDealSuccess;
    }
    if (newCount >= (deal.minimumMember * 0.8).ceil()) {
      return AppConstants.groupDealAlmostFull;
    }
    return AppConstants.groupDealRecruiting;
  }

  static String _statusAfterLeave(GroupBuy deal, int newCount) {
    if (newCount <= 0) {
      return AppConstants.groupDealCancelled;
    }
    if (newCount >= deal.minimumMember) {
      return AppConstants.groupDealSuccess;
    }
    if (newCount >= (deal.minimumMember * 0.8).ceil()) {
      return AppConstants.groupDealAlmostFull;
    }
    return AppConstants.groupDealRecruiting;
  }

  static double _priceForBuyerCount(GroupBuy groupBuy, int buyerCount) {
    if (groupBuy.usesGroupPriceModel) {
      return groupBuy.resolvedGroupPrice;
    }
    if (buyerCount >= AppConstants.groupBuyThreshold100) {
      return groupBuy.priceFrom100;
    }
    if (buyerCount >= AppConstants.groupBuyThreshold50) {
      return groupBuy.priceFrom50;
    }
    return groupBuy.priceUnder50;
  }
}
