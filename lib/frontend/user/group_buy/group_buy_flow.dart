import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/cart_service.dart';
import '../../../backend/services/group_buy_service.dart';
import 'group_buy_dialogs.dart';
import 'group_buy_product_picker_sheet.dart';
import 'group_buy_share_sheet.dart';

class GroupBuyFlow {
  static GroupBuy previewDeal(Product product) =>
      GroupBuyFlowPreview.dealFor(product);

  static Future<String?> loadUserDisplayName(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    return doc.data()?['fullName'] as String? ?? 'Bạn';
  }

  static Future<void> startCreateGroup(
    BuildContext context, {
    Product? initialProduct,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.uid == null) {
      _showMessage(context, 'Vui lòng đăng nhập');
      return;
    }

    final product = await showGroupBuyProductPickerSheet(
      context,
      initialProduct: initialProduct,
    );
    if (product == null || !context.mounted) return;

    await createGroup(context, product: product);
  }

  static Future<void> createGroup(
    BuildContext context, {
    required Product product,
    String? userDisplayName,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final groupBuyService = Provider.of<GroupBuyService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      _showMessage(context, 'Vui lòng đăng nhập');
      return;
    }

    final dialogResult = await showCreateGroupDialog(
      context: context,
      product: product,
      dealPreview: previewDeal(product),
    );
    if (dialogResult == null) return;

    try {
      final displayName =
          userDisplayName ?? await loadUserDisplayName(context) ?? 'Bạn';
      final createdDeal = await groupBuyService.createNewGroup(
        productId: product.id,
        creatorId: userId,
        product: product,
        creatorDisplayName: displayName,
        quantity: dialogResult.quantity,
        groupName: dialogResult.groupName,
        minimumMember: dialogResult.minMembers,
        maximumMember: dialogResult.maxMembers,
        duration: Duration(hours: dialogResult.durationHours),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tạo nhóm thành công! Hãy mời thêm '
            '${createdDeal.membersStillNeeded} người để nhận giá ưu đãi.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await showGroupBuyInviteSheet(
        context: context,
        deal: createdDeal,
        product: product,
        mode: GroupBuyInviteMode.created,
      );
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '$e', isError: true);
      }
    }
  }

  static Future<void> joinGroup(
    BuildContext context, {
    required Product product,
    required GroupBuy deal,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    final groupBuyService = Provider.of<GroupBuyService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      _showMessage(context, 'Vui lòng đăng nhập');
      return;
    }

    final dialogResult = await showJoinGroupDialog(
      context: context,
      deal: deal,
      product: product,
    );
    if (dialogResult == null) return;

    try {
      final joinResult = await groupBuyService.joinGroupBuy(
        groupBuyId: deal.id,
        userId: userId,
        productId: product.id,
        quantity: dialogResult.quantity,
      );

      try {
        await cartService.addToCart(
          userId,
          product,
          quantity: dialogResult.quantity,
          unitPrice: joinResult.unitPrice,
          groupBuyId: deal.id,
        );
      } catch (e) {
        await groupBuyService.leaveGroupBuy(
          groupBuyId: deal.id,
          userId: userId,
        );
        rethrow;
      }

      final updatedDeal = await groupBuyService.getDealById(deal.id);
      if (!context.mounted || updatedDeal == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã tham gia nhóm thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      await showGroupBuyInviteSheet(
        context: context,
        deal: updatedDeal,
        product: product,
        mode: GroupBuyInviteMode.joined,
      );
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '$e', isError: true);
      }
    }
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
