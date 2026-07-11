import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/order.dart' as models;
import '../../../backend/utils/rebuy_flow.dart';
import '../../../backend/services/auth_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const Color accent = Color(0xFF24C7E8);
  static const Color surface = Color(0xFFF7F8FB);
  String _filter = 'all';
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Row(
          children: [
            _SideBar(
              selectedSettings: _showSettings,
              onShowOrders: () => setState(() => _showSettings = false),
              onShowSettings: () => setState(() => _showSettings = true),
              onSignOut: () async => authService.signOut(),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    onBackToShop: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.home, (route) => false),
                    onShowOrders: () => setState(() => _showSettings = false),
                    onShowSettings: () => setState(() => _showSettings = true),
                    onSignOut: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.login, (route) => false);
                      }
                    },
                    userEmail: authService.currentUser?.email ?? '',
                  ),
                  Expanded(
                    child: _showSettings
                        ? const _DeliverySettingsView()
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection(AppConstants.ordersCollection)
                                .where('userId', isEqualTo: userId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: accent));
                              }

                              if (snapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Lỗi tải lịch sử đơn hàng: ${snapshot.error}'));
                              }

                              final orders = (snapshot.data?.docs ?? [])
                                  .map((doc) => models.Order.fromFirestore(doc))
                                  .toList();
                              orders.sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt));
                              final filteredOrders = _filterOrders(orders);

                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Center(
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 980),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              32, 34, 32, 72),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _PageHeader(
                                                filter: _filter,
                                                onFilterChanged: (value) =>
                                                    setState(
                                                        () => _filter = value),
                                              ),
                                              const SizedBox(height: 28),
                                              _StatsRow(orders: orders),
                                              const SizedBox(height: 28),
                                              if (filteredOrders.isEmpty)
                                                const _EmptyOrders()
                                              else
                                                ...filteredOrders.map(
                                                  (order) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 18),
                                                    child: _OrderCard(
                                                      order: order,
                                                      userId: userId,
                                                      onViewDetail: () =>
                                                          Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) =>
                                                                OrderDetailScreen(
                                                                    orderId: order
                                                                        .id)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 22),
                                              Center(
                                                child: OutlinedButton(
                                                  onPressed: () {},
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFF667085),
                                                    side: const BorderSide(
                                                        color:
                                                            Color(0xFFE4E7EC)),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 22,
                                                        vertical: 14),
                                                  ),
                                                  child: const Text(
                                                      'Xem thêm lịch sử đơn hàng'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const _HistoryFooter(),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<models.Order> _filterOrders(List<models.Order> orders) {
    if (_filter == 'completed') {
      return orders
          .where((order) => order.status == AppConstants.orderDelivered)
          .toList();
    }
    if (_filter == 'shipping') {
      return orders
          .where((order) =>
              order.status == AppConstants.orderShipping ||
              order.status == AppConstants.orderConfirmed)
          .toList();
    }
    return orders;
  }
}

class _DeliverySettingsView extends StatefulWidget {
  const _DeliverySettingsView();

  @override
  State<_DeliverySettingsView> createState() => _DeliverySettingsViewState();
}

class _DeliverySettingsViewState extends State<_DeliverySettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getUserProfile();

    if (!mounted) return;

    _nameController.text = (profile?['fullName'] as String?)?.trim() ?? '';
    _phoneController.text = (profile?['phone'] as String?)?.trim() ?? '';
    _addressController.text = (profile?['address'] as String?)?.trim() ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await Provider.of<AuthService>(context, listen: false)
          .updateDeliveryProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da luu cau hinh giao hang'),
          backgroundColor: _OrderHistoryScreenState.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi luu cau hinh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _OrderHistoryScreenState.accent,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 34, 32, 72),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7EAF0)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cau hinh ho ten, so dien thoai va dia chi mac dinh cho don hang.',
                          style:
                              TextStyle(color: Color(0xFF667085), fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ho va ten',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Vui long nhap ho va ten'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'So dien thoai',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Vui long nhap so dien thoai'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Dia chi giao hang',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Vui long nhap dia chi'
                                  : null,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined, size: 18),
                            label: Text(
                                _isSaving ? 'Dang luu...' : 'Luu cau hinh'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _HistoryFooter(),
        ],
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.selectedSettings,
    required this.onShowOrders,
    required this.onShowSettings,
    required this.onSignOut,
  });
  final bool selectedSettings;
  final VoidCallback onShowOrders;
  final VoidCallback onShowSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.of(context).size.width < 900)
          return const SizedBox.shrink();
        return Container(
          width: 220,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFEDEFF3))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 22, 26, 28),
                child: _BrandMark(),
              ),
              _SideItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {}),
              _SideItem(
                  icon: Icons.storefront_outlined,
                  label: 'Shop View',
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.home, (route) => false)),
              _SideItem(
                  icon: Icons.history,
                  label: 'Purchase History',
                  selected: !selectedSettings,
                  onTap: onShowOrders),
              _SideItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Insights',
                  onTap: () {}),
              _SideItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: selectedSettings,
                  onTap: onShowSettings),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
                child: TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Sign Out'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              color: selected ? const Color(0xFFF2F4F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF101828)),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.onBackToShop,
      required this.onShowOrders,
      required this.onShowSettings,
      required this.onSignOut,
      required this.userEmail});
  final VoidCallback onBackToShop;
  final VoidCallback onShowOrders;
  final VoidCallback onShowSettings;
  final VoidCallback onSignOut;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3)))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final veryCompact = constraints.maxWidth < 520;
          return Row(
            children: [
              if (MediaQuery.of(context).size.width < 900) ...[
                const _BrandMark(),
                const SizedBox(width: 16),
              ],
              if (!veryCompact) ...[
                TextButton(onPressed: onBackToShop, child: const Text('Shop')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onShowOrders,
                  style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F3F6),
                      foregroundColor: const Color(0xFF101828)),
                  child: const Text('My Orders'),
                ),
              ],
              const Spacer(),
              if (!compact)
                SizedBox(
                  width: 250,
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: Color(0xFF9AA1AA)),
                      prefixIcon: const Icon(Icons.search, size: 17),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFC),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide:
                              const BorderSide(color: Color(0xFFE4E7EC))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(
                              color: _OrderHistoryScreenState.accent)),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              if (veryCompact)
                IconButton(
                    onPressed: onBackToShop,
                    icon: const Icon(Icons.storefront_outlined, size: 21),
                    color: const Color(0xFF344054)),
              const Icon(Icons.notifications_none,
                  size: 21, color: Color(0xFF344054)),
              const SizedBox(width: 14),
              IconButton(
                tooltip: 'Settings',
                onPressed: onShowSettings,
                icon: const Icon(Icons.settings_outlined, size: 21),
                color: const Color(0xFF344054),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: userEmail,
                onSelected: (value) {
                  if (value == 'settings') onShowSettings();
                  if (value == 'logout') onSignOut();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'settings', child: Text('Settings')),
                  PopupMenuItem(value: 'logout', child: Text('Đăng xuất'))
                ],
                child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF111827),
                    child: Icon(Icons.person, color: Colors.white, size: 17)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      ),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.shopping_bag_outlined,
                color: _OrderHistoryScreenState.accent, size: 24),
            SizedBox(width: 8),
            Text('SmartDeal Shop',
                style: TextStyle(
                    color: _OrderHistoryScreenState.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.filter, required this.onFilterChanged});
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final title = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lịch sử đơn hàng',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF101828))),
        SizedBox(height: 8),
        Text('Theo dõi các đơn hàng gần đây và quản lý chi tiêu của bạn.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 14)),
      ],
    );
    final filters = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipButton(
            label: 'Tất cả',
            selected: filter == 'all',
            onTap: () => onFilterChanged('all')),
        _FilterChipButton(
            label: 'Đã hoàn thành',
            selected: filter == 'completed',
            onTap: () => onFilterChanged('completed')),
        _FilterChipButton(
            label: 'Đang giao',
            selected: filter == 'shipping',
            onTap: () => onFilterChanged('shipping')),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 18), filters]);
        }
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: title), filters]);
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _OrderHistoryScreenState.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? _OrderHistoryScreenState.accent
                  : const Color(0xFFE4E7EC)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF101828),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.orders});
  final List<models.Order> orders;

  @override
  Widget build(BuildContext context) {
    final completed = orders
        .where((order) => order.status == AppConstants.orderDelivered)
        .length;
    final rebuyRate =
        orders.isEmpty ? 0 : (completed / orders.length * 100).round();
    final cards = [
      _StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'TỔNG ĐƠN HÀNG',
          value: '${orders.length}'),
      _StatCard(
          icon: Icons.check_circle_outline,
          label: 'ĐÃ HOÀN THÀNH',
          value: '$completed'),
      _StatCard(icon: Icons.sync, label: 'TỈ LỆ MUA LẠI', value: '$rebuyRate%'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
              children: cards
                  .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12), child: card))
                  .toList());
        }
        return Row(
            children: cards
                .map((card) => Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: card)))
                .toList());
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0))),
      child: Row(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor:
                  _OrderHistoryScreenState.accent.withValues(alpha: 0.12),
              child:
                  Icon(icon, color: _OrderHistoryScreenState.accent, size: 18)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101828))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.userId,
    required this.onViewDetail,
  });

  final models.Order order;
  final String userId;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection(AppConstants.orderItemsCollection)
            .where('orderId', isEqualTo: order.id)
            .get(),
        builder: (context, snapshot) {
          final items = (snapshot.data?.docs ?? [])
              .map((doc) => models.OrderItem.fromFirestore(doc))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Row(
                  children: [
                    _OrderMeta(
                      label: 'MÃ ĐƠN HÀNG',
                      value: _shortOrderCode(order.id),
                    ),
                    const SizedBox(width: 34),
                    _OrderMeta(
                      label: 'NGÀY ĐẶT',
                      value: _formatDate(order.createdAt),
                    ),
                    const Spacer(),
                    _StatusPill(status: order.status),
                    const SizedBox(width: 16),
                    const Icon(Icons.chevron_right, color: Color(0xFF98A2B3)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDEFF3)),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: LinearProgressIndicator(
                    color: _OrderHistoryScreenState.accent,
                  ),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Đơn hàng chưa có sản phẩm hiển thị',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  ),
                )
              else
                ...items.map((item) => _OrderItemRow(item: item)),
              const Divider(height: 1, color: Color(0xFFEDEFF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                child: Row(
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_formatCurrency(order.totalPrice)}đ',
                      style: const TextStyle(
                        color: _OrderHistoryScreenState.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: onViewDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _OrderHistoryScreenState.accent,
                        side: const BorderSide(color: Color(0xFFD7F4FA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () => _rebuy(context, userId, items),
                      icon: const Icon(Icons.sync, size: 15),
                      label: const Text('Mua lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _OrderHistoryScreenState.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB6CBD1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rebuy(
    BuildContext context,
    String userId,
    List<models.OrderItem> items,
  ) async {
    await RebuyFlow.addToCartAndCheckout(
      context: context,
      userId: userId,
      items: items
          .map((item) => (productId: item.productId, quantity: item.quantity))
          .toList(),
    );
  }

  String _shortOrderCode(String id) {
    final safe =
        id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
    return 'SD-$safe';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 10,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final models.OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFF98A2B3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828))),
                const SizedBox(height: 6),
                Text('Số lượng: ${item.quantity}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF667085))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_formatCurrency(item.totalPrice)}đ',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101828))),
              const SizedBox(height: 6),
              Text('${_formatCurrency(item.price)}đ / sản phẩm',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF667085))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.20))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(_statusText(status),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.orderDelivered:
        return Colors.green;
      case AppConstants.orderShipping:
      case AppConstants.orderConfirmed:
        return Colors.orange;
      case AppConstants.orderCancelled:
        return Colors.redAccent;
      default:
        return const Color(0xFF667085);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case AppConstants.orderDelivered:
        return Icons.check_circle_outline;
      case AppConstants.orderShipping:
      case AppConstants.orderConfirmed:
        return Icons.local_shipping_outlined;
      case AppConstants.orderCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case AppConstants.orderDelivered:
        return 'Hoàn thành';
      case AppConstants.orderConfirmed:
      case AppConstants.orderShipping:
        return 'Đang giao';
      case AppConstants.orderCancelled:
        return 'Đã hủy';
      case AppConstants.orderPending:
        return 'Chờ xử lý';
      default:
        return status;
    }
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0))),
      child: Column(
        children: const [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF98A2B3)),
          SizedBox(height: 16),
          Text('Chưa có đơn hàng nào',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF101828))),
          SizedBox(height: 8),
          Text('Các đơn hàng sau khi mua sẽ xuất hiện tại đây.',
              style: TextStyle(color: Color(0xFF667085))),
        ],
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 34, 32, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = const [
                    _FooterBrand(),
                    _FooterColumn(title: 'QUICK LINKS', items: [
                      'Browse Products',
                      'My History',
                      'Purchase Stats'
                    ]),
                    _FooterColumn(title: 'SUPPORT', items: [
                      'Help Center',
                      'Returns Policy',
                      'Flash Sale Terms',
                      'Admin Access'
                    ]),
                    _FooterColumn(title: 'CONTACT', items: [
                      '123 Commerce St, Tech City',
                      'support@smartdealshop.com'
                    ]),
                  ];
                  if (constraints.maxWidth < 760) {
                    return Wrap(
                        spacing: 30,
                        runSpacing: 26,
                        children: columns
                            .map(
                                (column) => SizedBox(width: 240, child: column))
                            .toList());
                  }
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: columns
                          .map((column) => Expanded(child: column))
                          .toList());
                },
              ),
              const SizedBox(height: 30),
              const Divider(color: Color(0xFFEDEFF3)),
              const SizedBox(height: 18),
              const Text('© 2026 SmartDeal Shop. All rights reserved.',
                  style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandMark(),
        SizedBox(height: 14),
        Text(
          'Your premier destination for bulk savings and flash deals. Smart shopping starts here.',
          style: TextStyle(color: Color(0xFF667085), fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF1D2939),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(item,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
          ),
      ],
    );
  }
}
