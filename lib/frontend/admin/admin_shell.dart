import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import 'package:provider/provider.dart';
import '../../backend/services/auth_service.dart';
import 'admin_navigation.dart';
import 'admin_theme.dart';

/// Khung layout admin: sidebar trái + header + nội dung (theo mockup SmartDeal Shop).
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.currentRoute,
    required this.body,
    required this.onNavigate,
    this.breadcrumb,
    this.floatingActionButton,
  });

  final String currentRoute;
  final Widget body;
  final void Function(String route, {bool replaceStack}) onNavigate;
  final String? breadcrumb;
  final Widget? floatingActionButton;

  static String breadcrumbForRoute(String route) {
    switch (route) {
      case AppRoutes.adminProducts:
        return 'Sản phẩm';
      case AppRoutes.adminAddProduct:
        return 'Sản phẩm';
      case AppRoutes.adminOrders:
        return 'Quản lý đơn hàng';
      case AppRoutes.adminUsers:
        return 'Quản lý người dùng';
      case AppRoutes.adminFlashSale:
        return 'Flash Sale';
      case AppRoutes.adminAnalytics:
        return 'Báo cáo & Phân tích';
      case AppRoutes.adminSettings:
        return 'Cài đặt shop';
      case AppRoutes.seedData:
        return 'Dữ liệu mẫu';
      default:
        return 'Tổng quan';
    }
  }

  static const _items = <_AdminNavItem>[
    _AdminNavItem(
      route: AppRoutes.admin,
      icon: Icons.dashboard_outlined,
      label: 'Tổng quan',
    ),
    _AdminNavItem(
      route: AppRoutes.adminProducts,
      icon: Icons.inventory_2_outlined,
      label: 'Sản phẩm',
    ),
    _AdminNavItem(
      route: AppRoutes.adminOrders,
      icon: Icons.receipt_long_outlined,
      label: 'Quản lý đơn hàng',
    ),
    _AdminNavItem(
      route: AppRoutes.adminUsers,
      icon: Icons.people_alt_outlined,
      label: 'Quản lý người dùng',
    ),
    _AdminNavItem(
      route: AppRoutes.adminFlashSale,
      icon: Icons.flash_on_outlined,
      label: 'Flash Sale',
    ),
    _AdminNavItem(
      route: AppRoutes.adminAnalytics,
      icon: Icons.insights_outlined,
      label: 'Báo cáo & Phân tích',
    ),
    _AdminNavItem(
      route: AppRoutes.adminSettings,
      icon: Icons.settings_outlined,
      label: 'Cài đặt shop',
    ),
  ];

  bool _isSelected(String route) {
    if (route == AppRoutes.adminProducts &&
        currentRoute == AppRoutes.adminAddProduct) {
      return true;
    }
    return route == currentRoute;
  }

  void _handleNav(BuildContext context, _AdminNavItem item) {
    onNavigate(item.route, replaceStack: item.replaceStack);
  }

  Future<void> _signOut(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userEmail = authService.currentUser?.email ?? '';
    final displayName = userEmail.isNotEmpty
        ? userEmail.split('@').first
        : 'Admin';
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    const sidebarWidth = 248.0;
    final pageTitle = breadcrumb ?? breadcrumbForRoute(currentRoute);

    return Scaffold(
      backgroundColor: AdminTheme.surface,
      floatingActionButton: floatingActionButton,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AdminTheme.sidebarBg,
              child: SafeArea(
                child: _AdminSideNav(
                  isSelected: _isSelected,
                  onItemTap: (item) {
                    Navigator.pop(context);
                    _handleNav(context, item);
                  },
                  onSignOut: () => _signOut(context),
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              SizedBox(
                width: sidebarWidth,
                child: ColoredBox(
                  color: AdminTheme.sidebarBg,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AdminTheme.border),
                      ),
                    ),
                    child: _AdminSideNav(
                      isSelected: _isSelected,
                      onItemTap: (item) => _handleNav(context, item),
                      onSignOut: () => _signOut(context),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AdminTopBar(
                    pageTitle: pageTitle,
                    userName: displayName,
                    userEmail: userEmail,
                    showMenu: !isWide,
                    onShop: () =>
                        onNavigate(AppRoutes.home, replaceStack: true),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.route,
    required this.icon,
    required this.label,
    this.replaceStack = false,
  });

  final String route;
  final IconData icon;
  final String label;
  final bool replaceStack;
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav({
    required this.isSelected,
    required this.onItemTap,
    required this.onSignOut,
  });

  final bool Function(String route) isSelected;
  final ValueChanged<_AdminNavItem> onItemTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: _BrandMark(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final item in AdminShell._items)
                _SideItem(
                  icon: item.icon,
                  label: item.label,
                  selected: isSelected(item.route),
                  onTap: () => onItemTap(item),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF04438),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AdminTheme.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AdminTheme.accentDark : AdminTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AdminTheme.accentDark
                          : AdminTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.pageTitle,
    required this.userName,
    required this.userEmail,
    required this.onShop,
    this.showMenu = false,
  });

  final String pageTitle;
  final String userName;
  final String userEmail;
  final VoidCallback onShop;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 24, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: Row(
          children: [
            if (showMenu)
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
            TextButton(
              onPressed: onShop,
              style: TextButton.styleFrom(
                foregroundColor: AdminTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Shop',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AdminTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: const TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AdminTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F7),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminTheme.accent.withValues(alpha: 0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AdminTheme.accentDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$userName - Admin',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: AdminTheme.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => AdminNavigation.navigate(
        context,
        AppRoutes.home,
        replaceStack: true,
      ),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: AdminTheme.accent,
            size: 26,
          ),
          SizedBox(width: 10),
          Text(
            'SmartDeal Shop',
            style: TextStyle(
              color: AdminTheme.accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
