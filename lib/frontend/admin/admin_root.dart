import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../backend/models/product.dart';
import 'add_product_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_configure_flash_sale_screen.dart';
import 'admin_dashboard.dart';
import 'admin_navigation.dart';
import 'admin_shell.dart';
import 'admin_shop_settings_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'seed_data_screen.dart';

/// Một màn admin duy nhất — đổi tab bằng setState, không push route mới.
class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key, this.initialRoute = AppRoutes.admin});

  final String initialRoute;

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  late String _route;
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _route = _normalizeRoute(widget.initialRoute);
  }

  void _openAddProduct() {
    setState(() {
      _editingProduct = null;
      _route = AppRoutes.adminAddProduct;
    });
  }

  void _openEditProduct(Product product) {
    setState(() {
      _editingProduct = product;
      _route = AppRoutes.adminAddProduct;
    });
  }

  String _normalizeRoute(String route) {
    const allowed = {
      AppRoutes.admin,
      AppRoutes.adminProducts,
      AppRoutes.adminAddProduct,
      AppRoutes.adminOrders,
      AppRoutes.adminUsers,
      AppRoutes.adminFlashSale,
      AppRoutes.adminAnalytics,
      AppRoutes.adminSettings,
      AppRoutes.seedData,
    };
    return allowed.contains(route) ? route : AppRoutes.admin;
  }

  void _go(String route, {bool replaceStack = false}) {
    if (replaceStack || route == AppRoutes.home) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }
    final next = _normalizeRoute(route);
    setState(() {
      if (next == AppRoutes.adminAddProduct &&
          _route != AppRoutes.adminAddProduct) {
        _editingProduct = null;
      }
      if (next == AppRoutes.adminProducts) {
        _editingProduct = null;
      }
      _route = next;
    });
  }

  String? get _breadcrumb {
    if (_route == AppRoutes.adminAddProduct) {
      return _editingProduct != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm';
    }
    return AdminShell.breadcrumbForRoute(_route);
  }

  Widget _buildBody() {
    switch (_route) {
      case AppRoutes.adminProducts:
        return ManageProductsBody(
          key: const ValueKey('admin-products'),
          onAddProduct: _openAddProduct,
          onEditProduct: _openEditProduct,
        );
      case AppRoutes.adminAddProduct:
        return AddProductBody(
          key: ValueKey('admin-product-form-${_editingProduct?.id ?? 'new'}'),
          product: _editingProduct,
          onSaved: () {
            setState(() {
              _editingProduct = null;
              _route = AppRoutes.adminProducts;
            });
          },
          onCancel: () {
            setState(() {
              _editingProduct = null;
              _route = AppRoutes.adminProducts;
            });
          },
        );
      case AppRoutes.adminOrders:
        return const ManageOrdersBody(key: ValueKey('admin-orders'));
      case AppRoutes.adminUsers:
        return const ManageUsersBody(key: ValueKey('admin-users'));
      case AppRoutes.adminFlashSale:
        return const AdminConfigureFlashSaleBody(
          key: ValueKey('admin-flash-sale'),
        );
      case AppRoutes.adminAnalytics:
        return const AdminAnalyticsBody(key: ValueKey('admin-analytics'));
      case AppRoutes.adminSettings:
        return const AdminShopSettingsBody(key: ValueKey('admin-settings'));
      case AppRoutes.seedData:
        return const SeedDataBody(key: ValueKey('admin-seed-data'));
      case AppRoutes.admin:
      default:
        return AdminDashboardBody(
          key: const ValueKey('admin-dashboard'),
          onAddProduct: _openAddProduct,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminNavigation(
      go: _go,
      child: AdminShell(
        currentRoute: _route,
        onNavigate: _go,
        breadcrumb: _breadcrumb,
        body: _buildBody(),
      ),
    );
  }
}
