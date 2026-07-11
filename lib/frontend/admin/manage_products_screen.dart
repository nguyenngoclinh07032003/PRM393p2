import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/models/product.dart';
import '../widgets/product_image.dart';
import 'admin_navigation.dart';
import 'admin_theme.dart';

typedef EditProductCallback = void Function(Product product);

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ManageProductsBody();
}

class ManageProductsBody extends StatefulWidget {
  const ManageProductsBody({
    super.key,
    this.onAddProduct,
    this.onEditProduct,
  });

  final VoidCallback? onAddProduct;
  final EditProductCallback? onEditProduct;

  @override
  State<ManageProductsBody> createState() => _ManageProductsBodyState();
}

class _ManageProductsBodyState extends State<ManageProductsBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    if (widget.onAddProduct != null) {
      widget.onAddProduct!();
      return;
    }
    AdminNavigation.navigate(context, AppRoutes.adminAddProduct);
  }

  void _openEditProduct(Product product) {
    if (widget.onEditProduct != null) {
      widget.onEditProduct!(product);
      return;
    }
    AdminNavigation.navigate(context, AppRoutes.adminAddProduct);
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update({'status': AppConstants.productInactive});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa sản phẩm'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _restoreProduct(Product product) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update({'status': AppConstants.productActive});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã khôi phục sản phẩm'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();
    return products.where((product) {
      if (!_showInactive && product.status != AppConstants.productActive) {
        return false;
      }
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String _formatPrice(double value) {
    return '${AdminTheme.formatCurrency(value)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return AdminPage(
            title: 'Quản Lý Sản Phẩm',
            child: AdminEmptyState(
              message: 'Lỗi: ${snapshot.error}',
              icon: Icons.error_outline,
            ),
          );
        }

        final allProducts = (snapshot.data?.docs ?? [])
            .map((doc) => Product.fromFirestore(doc))
            .toList();
        final products = _filterProducts(allProducts);

        return AdminPage(
          title: 'Quản Lý Sản Phẩm',
          subtitle: 'Danh mục và giá bán sản phẩm',
          actions: [
            AdminPrimaryButton(
              label: 'Thêm sản phẩm',
              onPressed: _openAddProduct,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdminSearchField(
                      controller: _searchController,
                      hint: 'Tìm tên hoặc danh mục...',
                      onChanged: (value) => setState(() => _searchQuery = value),
                      onClear: _searchQuery.isEmpty
                          ? null
                          : () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Hiện SP đã xóa'),
                    selected: _showInactive,
                    selectedColor: AdminTheme.accent.withValues(alpha: 0.12),
                    onSelected: (value) =>
                        setState(() => _showInactive = value),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (products.isEmpty)
                AdminEmptyState(
                  message: allProducts.isEmpty
                      ? 'Chưa có sản phẩm'
                      : 'Không tìm thấy sản phẩm phù hợp',
                  icon: Icons.inventory_2_outlined,
                  action: AdminPrimaryButton(
                    label: 'Thêm sản phẩm',
                    onPressed: _openAddProduct,
                  ),
                )
              else
                AdminDataTableWrap(
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Sản phẩm')),
                      DataColumn(label: Text('Danh mục')),
                      DataColumn(label: Text('Số lượng')),
                      DataColumn(label: Text('Giá gốc')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('')),
                    ],
                    rows: products.map((product) {
                            final isActive = product.status ==
                                AppConstants.productActive;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: ProductImage(
                                            product: product,
                                            fit: BoxFit.cover,
                                            iconSize: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(product.category)),
                                DataCell(Text('${product.stock}')),
                                DataCell(
                                  Text(
                                    _formatPrice(product.finalPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AdminTheme.accent,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  AdminStatusBadge(
                                    label: isActive
                                        ? (product.stock > 0
                                            ? 'Đang bán'
                                            : 'Hết hàng')
                                        : 'Đã xóa',
                                    color: isActive
                                        ? (product.stock > 0
                                            ? const Color(0xFF12B76A)
                                            : const Color(0xFFF04438))
                                        : const Color(0xFF98A2B3),
                                  ),
                                ),
                                DataCell(
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _openEditProduct(product);
                                        case 'delete':
                                          if (isActive) _confirmDelete(product);
                                        case 'restore':
                                          if (!isActive) {
                                            _restoreProduct(product);
                                          }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Chỉnh sửa'),
                                      ),
                                      if (isActive)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Xóa'),
                                        ),
                                      if (!isActive)
                                        const PopupMenuItem(
                                          value: 'restore',
                                          child: Text('Khôi phục'),
                                        ),
                                    ],
                                    child: const Icon(Icons.more_horiz),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
            ],
          ),
        );
      },
    );
  }
}
