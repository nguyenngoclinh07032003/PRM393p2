class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String cartsCollection = 'carts';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'order_items';
  static const String rebuyStatsCollection = 'rebuy_stats';
  static const String groupBuysCollection = 'group_buys';
  static const String flashSalesCollection = 'flash_sales';
  static const String discountsCollection = 'discounts';
  static const String notificationsCollection = 'notifications';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleSeller = 'seller';
  static const String roleAdmin = 'admin';

  /// Email được gán quyền admin tự động khi đăng nhập/đăng ký.
  static const List<String> designatedAdminEmails = [
    'linhnnhe171195@fpt.edu.vn',
  ];
  
  // User Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  
  // Order Status
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderShipping = 'shipping';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';
  
  // Payment Status
  static const String paymentUnpaid = 'unpaid';
  static const String paymentPaid = 'paid';
  
  // Discount Type
  static const String discountPercent = 'percent';
  static const String discountFixed = 'fixed';
  
  // Product Status
  static const String productActive = 'active';
  static const String productInactive = 'inactive';

  // Firebase Storage
  static const String productImagesStoragePath = 'product_images';
  
  // Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // Group Buy
  static const String groupBuyMembersSubcollection = 'members';
  static const int groupBuyThreshold50 = 50;
  static const int groupBuyThreshold100 = 100;
  static const int groupBuyDefaultMinMembers = 20;
  static const int groupBuyDefaultMaxMembers = 20;
  static const int groupBuyMaxQuantityPerMember = 3;
  static const int groupBuyDurationHours = 48;

  // Group deal lifecycle statuses
  static const String groupDealRecruiting = 'recruiting';
  static const String groupDealAlmostFull = 'almost_full';
  static const String groupDealFull = 'full';
  static const String groupDealSuccess = 'success';
  static const String groupDealExpired = 'expired';
  static const String groupDealFailed = 'failed';
  static const String groupDealPaid = 'paid';
  static const String groupDealCancelled = 'cancelled';
  static const String groupDealActive = 'active'; // legacy

  static const String groupBuySharePath = '/invite/group';
}
