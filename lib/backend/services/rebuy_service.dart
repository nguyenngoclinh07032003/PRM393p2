import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/rebuy_stat.dart';

class RebuyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get rebuy stats for user
  Future<List<RebuyStat>> getUserRebuyStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.rebuyStatsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final stats = snapshot.docs
          .map((doc) => RebuyStat.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.buyCount.compareTo(a.buyCount));

      return stats;
    } catch (e) {
      debugPrint('Get rebuy stats error: $e');
      return [];
    }
  }

  // Get products user should rebuy
  Future<List<RebuyStat>> getSuggestedRebuys(String userId) async {
    try {
      final stats = await getUserRebuyStats(userId);
      return stats.where((stat) => stat.shouldRebuy).toList();
    } catch (e) {
      debugPrint('Get suggested rebuys error: $e');
      return [];
    }
  }

  // Update rebuy stat after purchase
  Future<void> updateRebuyStat(
    String userId,
    String productId, {
    int quantity = 1,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.rebuyStatsCollection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create new stat
        await _firestore.collection(AppConstants.rebuyStatsCollection).add({
          'userId': userId,
          'productId': productId,
          'buyCount': 1,
          'lastBuyAt': Timestamp.now(),
          'averageDays': 0,
          'totalQuantity': quantity,
        });
      } else {
        // Update existing stat
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final buyCount = (data['buyCount'] ?? 0) + 1;
        final lastBuyAt = (data['lastBuyAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final daysSinceLastBuy = DateTime.now().difference(lastBuyAt).inDays;
        
        // Calculate new average days
        final oldAverage = data['averageDays'] ?? 0;
        final newAverage = oldAverage == 0
            ? daysSinceLastBuy
            : ((oldAverage * (buyCount - 1) + daysSinceLastBuy) / buyCount).round();

        await doc.reference.update({
          'buyCount': buyCount,
          'lastBuyAt': Timestamp.now(),
          'averageDays': newAverage,
          'totalQuantity': FieldValue.increment(quantity),
        });
      }
    } catch (e) {
      debugPrint('Update rebuy stat error: $e');
      rethrow;
    }
  }

  // Calculate purchase frequency
  double calculatePurchaseFrequency(int buyCount, DateTime firstBuyDate) {
    final daysSinceFirst = DateTime.now().difference(firstBuyDate).inDays;
    if (daysSinceFirst == 0) return 0;
    return buyCount / (daysSinceFirst / 30); // Times per month
  }
}
