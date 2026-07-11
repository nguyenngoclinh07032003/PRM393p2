import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/flash_sale.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/product_service.dart';
import '../../../backend/utils/pricing_utils.dart';
import '../../admin/quick_seed_button.dart';
import '../../widgets/flash_sale_countdown.dart';
import '../../widgets/product_image.dart';
import '../products/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const accent = Color(0xFF24C7E8);
  static const orange = Color(0xFFFF7A59);
  static const surface = Color(0xFFF7F8FB);
  static const categories = [
    'Tất cả',
    'Điện thoại',
    'Laptop',
    'Đồng hồ',
    'Máy ảnh',
    'Âm thanh',
  ];

  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'Tất cả';
  String _sortBy = 'Phổ biến';
  int _currentPage = 1;

  static const int _productsPerPage = 8;

  late final Stream<List<Product>> _productsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _flashSalesStream;

  @override
  void initState() {
    super.initState();
    _productsStream = _productService.getProducts();
    _flashSalesStream = FirebaseFirestore.instance
        .collection(AppConstants.flashSalesCollection)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _resetToFirstPage() {
    if (_currentPage != 1) {
      setState(() => _currentPage = 1);
    }
  }

  List<Product> _pageProducts(List<Product> products) {
    if (products.isEmpty) return products;
    final totalPages = _totalPages(products.length);
    final page = _currentPage.clamp(1, totalPages);
    final start = (page - 1) * _productsPerPage;
    final end = (start + _productsPerPage).clamp(0, products.length);
    return products.sublist(start, end);
  }

  int _totalPages(int productCount) {
    if (productCount <= 0) return 1;
    return (productCount / _productsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              searchController: _searchController,
              onSearchChanged: (_) {
                _resetToFirstPage();
                setState(() {});
              },
              onCartTap: () => Navigator.pushNamed(context, AppRoutes.cart),
              onHistoryTap: () =>
                  Navigator.pushNamed(context, AppRoutes.orders),
              roleFuture: authService.getUserRole(),
              onDashboardTap: (role) {
                Navigator.pushNamed(
                  context,
                  role == AppConstants.roleSeller
                      ? AppRoutes.seller
                      : AppRoutes.admin,
                );
              },
              onLogoutTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              userEmail: user?.email ?? '',
            ),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  final rawProducts = snapshot.data ?? [];
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _flashSalesStream,
                    builder: (context, flashSnapshot) {
                      final campaignFlashSales =
                          (flashSnapshot.data?.docs ?? [])
                              .map((doc) => FlashSale.fromFirestore(doc))
                              .where(
                                (sale) =>
                                    sale.status == 'active' &&
                                    !sale.isScheduleEnded,
                              )
                              .toList();
                      final activeFlashSales = campaignFlashSales
                          .where((sale) => sale.isActive)
                          .toList()
                        ..sort((a, b) => a.endTime.compareTo(b.endTime));
                      final products =
                          _filterProducts(rawProducts, activeFlashSales);
                      final totalPages = _totalPages(products.length);
                      final currentPage = _currentPage.clamp(1, totalPages);
                      final pagedProducts = _pageProducts(products);

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _HomeIntro(
                              productCount: products.length,
                              selectedCategory: _selectedCategory,
                              categories: categories,
                              sortBy: _sortBy,
                              userId: user?.uid ?? '',
                              onSearchChanged: () => setState(() {}),
                              onFlashSaleTap: () => Navigator.pushNamed(
                                  context, AppRoutes.flashSale),
                              onGroupBuyTap: () => Navigator.pushNamed(
                                  context, AppRoutes.groupBuy),
                              onRebuyTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.rebuy),
                              onSeedTap: () => Navigator.pushNamed(
                                  context, AppRoutes.seedData),
                              onCategorySelected: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _currentPage = 1;
                                });
                              },
                              onSortChanged: (value) {
                                setState(() {
                                  _sortBy = value;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ),
                          if (isLoading)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(color: accent),
                              ),
                            )
                          else if (snapshot.hasError || flashSnapshot.hasError)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _StateMessage(
                                icon: Icons.cloud_off_outlined,
                                title: 'Không tải được sản phẩm',
                                message:
                                    '${snapshot.error ?? flashSnapshot.error}',
                                actionLabel: 'Tải lại',
                                onAction: () => setState(() {}),
                                footer: user == null
                                    ? null
                                    : QuickSeedButton(userId: user.uid),
                              ),
                            )
                          else if (products.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _StateMessage(
                                icon: Icons.inventory_2_outlined,
                                title: 'Chưa có sản phẩm phù hợp',
                                message:
                                    'Bấm nút thêm sản phẩm mẫu hoặc đổi bộ lọc để xem dữ liệu.',
                                footer: user == null
                                    ? null
                                    : QuickSeedButton(userId: user.uid),
                              ),
                            )
                          else
                            _HomeProductGridSliver(
                              products: pagedProducts,
                              campaignFlashSales: campaignFlashSales,
                              gridColumns: _gridColumns(
                                MediaQuery.sizeOf(context).width,
                              ),
                              compactCard:
                                  MediaQuery.sizeOf(context).width < 640,
                            ),
                          if (products.isNotEmpty && totalPages > 1)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1180),
                                    child: _HomePagination(
                                      currentPage: currentPage,
                                      totalPages: totalPages,
                                      productsPerPage: _productsPerPage,
                                      totalProducts: products.length,
                                      onPageSelected: _goToPage,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: _HomeFooter()),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filterProducts(
    List<Product> products,
    List<FlashSale> activeFlashSales,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = products.where((product) {
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'Tất cả' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'Giá tăng':
        filtered.sort((a, b) => _displayPrice(a, activeFlashSales)
            .compareTo(_displayPrice(b, activeFlashSales)));
        break;
      case 'Giá giảm':
        filtered.sort((a, b) => _displayPrice(b, activeFlashSales)
            .compareTo(_displayPrice(a, activeFlashSales)));
        break;
      case 'Mới nhất':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  FlashSale? _flashSaleForProduct(
    Product product,
    List<FlashSale> activeFlashSales,
  ) {
    return PricingUtils.pickBestFlashSale(product, activeFlashSales);
  }

  double _displayPrice(Product product, List<FlashSale> activeFlashSales) {
    final flashSale = _flashSaleForProduct(product, activeFlashSales);
    return _displayPriceForSale(product, flashSale);
  }

  double _displayPriceForSale(Product product, FlashSale? flashSale) {
    return PricingUtils.resolveUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
      flashSale: flashSale?.isActive == true ? flashSale : null,
      productId: product.id,
    );
  }

  int _gridColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 820) return 3;
    if (width >= 560) return 2;
    return 1;
  }
}

class SliverConstrainedCrossAxis extends StatelessWidget {
  const SliverConstrainedCrossAxis({
    super.key,
    required this.maxExtent,
    required this.sliver,
  });

  final double maxExtent;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxExtent),
          child: CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [sliver],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchController,
    required this.onSearchChanged,
    required this.onCartTap,
    required this.onHistoryTap,
    required this.roleFuture,
    required this.onDashboardTap,
    required this.onLogoutTap,
    required this.userEmail,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCartTap;
  final VoidCallback onHistoryTap;
  final Future<String?> roleFuture;
  final ValueChanged<String> onDashboardTap;
  final VoidCallback onLogoutTap;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      height: compact ? 58 : 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              const _BrandMark(),
              if (!compact) ...[
                const SizedBox(width: 28),
                _NavButton(label: 'Home', selected: true, onTap: () {}),
                _NavButton(label: 'My Orders', onTap: onHistoryTap),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 38,
                  child: _SearchField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(width: 8),
              _IconAction(icon: Icons.shopping_cart_outlined, onTap: onCartTap),
              FutureBuilder<String?>(
                future: roleFuture,
                builder: (context, snapshot) {
                  final role = snapshot.data;
                  final canOpenDashboard = role == AppConstants.roleAdmin ||
                      role == AppConstants.roleSeller;
                  if (!canOpenDashboard) return const SizedBox.shrink();

                  return _IconAction(
                    icon: role == AppConstants.roleSeller
                        ? Icons.storefront_outlined
                        : Icons.admin_panel_settings_outlined,
                    onTap: () => onDashboardTap(role!),
                  );
                },
              ),
              PopupMenuButton<String>(
                tooltip: userEmail,
                onSelected: (value) {
                  if (value == 'logout') onLogoutTap();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
                ],
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF111827),
                  child: Icon(Icons.person, color: Colors.white, size: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9AA1AA)),
        prefixIcon: const Icon(Icons.search, size: 17),
        contentPadding: EdgeInsets.zero,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _HomeScreenState.accent),
        ),
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
                color: _HomeScreenState.accent, size: 22),
            SizedBox(width: 6),
            Text(
              'SmartDeal Shop',
              style: TextStyle(
                color: _HomeScreenState.accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF101828),
          backgroundColor:
              selected ? const Color(0xFFF1F3F6) : Colors.transparent,
          minimumSize: const Size(58, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: const Color(0xFF344054),
      splashRadius: 20,
    );
  }
}

class _HomeIntro extends StatelessWidget {
  const _HomeIntro({
    required this.productCount,
    required this.selectedCategory,
    required this.categories,
    required this.sortBy,
    required this.userId,
    required this.onSearchChanged,
    required this.onFlashSaleTap,
    required this.onGroupBuyTap,
    required this.onRebuyTap,
    required this.onSeedTap,
    required this.onCategorySelected,
    required this.onSortChanged,
  });

  final int productCount;
  final String selectedCategory;
  final List<String> categories;
  final String sortBy;
  final String userId;
  final VoidCallback onSearchChanged;
  final VoidCallback onFlashSaleTap;
  final VoidCallback onGroupBuyTap;
  final VoidCallback onRebuyTap;
  final VoidCallback onSeedTap;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(compact ? 14 : 24, 24, compact ? 14 : 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(onTap: onFlashSaleTap),
              const SizedBox(height: 18),
              _BenefitStrip(
                onGroupBuyTap: onGroupBuyTap,
                onRebuyTap: onRebuyTap,
                onSeedTap: onSeedTap,
                userId: userId,
              ),
              const SizedBox(height: 24),
              _SectionHeading(
                productCount: productCount,
                sortBy: sortBy,
                onSortChanged: onSortChanged,
              ),
              const SizedBox(height: 14),
              _CategoryTabs(
                categories: categories,
                selectedCategory: selectedCategory,
                onSelected: onCategorySelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

FlashSale? pickFeaturedFlashSale(List<FlashSale> sales, DateTime now) {
  FlashSale? active;
  FlashSale? upcoming;

  for (final sale in sales) {
    if (sale.isActive) {
      active = sale;
      break;
    }
    if (sale.isVisibleToUsers &&
        sale.countdownStartAt(now) != null &&
        upcoming == null) {
      upcoming = sale;
    }
  }

  if (active != null) return active;
  if (upcoming != null) return upcoming;

  for (final sale in sales) {
    if (sale.countdownStartAt(now) != null && sale.countdownEndAt(now) != null) {
      return sale;
    }
  }
  return null;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  static const _defaultDescription =
      'Săn deal công nghệ và phụ kiện với mức giá tốt. Số lượng có hạn, mua ngay để không bỏ lỡ.';

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.flashSalesCollection)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final sales = (snapshot.data?.docs ?? [])
            .map((doc) => FlashSale.fromFirestore(doc))
            .where((sale) => sale.isVisibleToUsers)
            .toList();
        final sale = pickFeaturedFlashSale(sales, now);
        final description = sale != null && sale.note.trim().isNotEmpty
            ? sale.note.trim()
            : _defaultDescription;
        final discountLabel = sale != null
            ? 'GIẢM TỚI ${sale.discountPercent.toStringAsFixed(0)}%'
            : 'GIẢM TỚI 50%';
        final badgePercent = sale != null
            ? '-${sale.discountPercent.toStringAsFixed(0)}%'
            : '-50%';

        final text = Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'FLASH SALE  •  CHỈ HÔM NAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              text: 'Flash Sale Giờ Vàng: ',
              children: [
                TextSpan(
                  text: discountLabel,
                  style: const TextStyle(color: _HomeScreenState.orange),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.55,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          _HeroFlashSaleClock(sale: sale),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Mua ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _HomeScreenState.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );

    final image = Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1607082349566-187342175e2f?auto=format&fit=crop&w=900&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFFE5E7EB)),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 18,
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: _HomeScreenState.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              badgePercent,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );

        return Container(
          height: compact ? null : 315,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EC),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: compact
              ? Column(children: [text, SizedBox(height: 210, child: image)])
              : Row(
                  children: [
                    Expanded(flex: 6, child: text),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: image,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeroFlashSaleClock extends StatelessWidget {
  const _HeroFlashSaleClock({this.sale});

  final FlashSale? sale;

  Widget _buildClock(BuildContext context, FlashSale? featured) {
    final now = DateTime.now();
    final saleStart = featured?.countdownStartAt(now);
    final saleEnd = featured?.countdownEndAt(now);
    final phase = featured?.countdownPhase(now);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD5C7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: _HomeScreenState.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: featured == null
                ? const Text(
                    'Chưa có Flash Sale đang chạy',
                    style: TextStyle(
                      color: _HomeScreenState.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  )
                : saleStart == null && saleEnd == null
                    ? const Text(
                        'Hết khung giờ hôm nay — quay lại sau',
                        style: TextStyle(
                          color: _HomeScreenState.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      )
                    : FlashSaleCountdown(
                        startTime: saleStart,
                        endTime: saleEnd,
                        phase: phase,
                        showSlotRange: false,
                        style: const TextStyle(
                          color: _HomeScreenState.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sale != null) {
      return _buildClock(context, sale);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.flashSalesCollection)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD5C7)),
            ),
            child: const Text(
              'Đang tải giờ Flash Sale...',
              style: TextStyle(
                color: _HomeScreenState.orange,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        }

        final now = DateTime.now();
        final sales = (snapshot.data?.docs ?? [])
            .map((doc) => FlashSale.fromFirestore(doc))
            .where((s) => s.isVisibleToUsers)
            .toList();
        return _buildClock(context, pickFeaturedFlashSale(sales, now));
      },
    );
  }
}

class _BenefitStrip extends StatelessWidget {
  const _BenefitStrip({
    required this.onGroupBuyTap,
    required this.onRebuyTap,
    required this.onSeedTap,
    required this.userId,
  });

  final VoidCallback onGroupBuyTap;
  final VoidCallback onRebuyTap;
  final VoidCallback onSeedTap;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _BenefitCard(
        icon: Icons.groups_2_outlined,
        title: 'Mua nhóm nhận deal',
        text: 'Mua càng đông, giá càng tốt hơn.',
        color: _HomeScreenState.accent,
        onTap: onGroupBuyTap,
      ),
      _BenefitCard(
        icon: Icons.flash_on_outlined,
        title: 'Flash sale mỗi ngày',
        text: 'Ưu đãi công nghệ theo khung giờ.',
        color: _HomeScreenState.orange,
        onTap: onRebuyTap,
      ),
      _BenefitCard(
        icon: Icons.local_shipping_outlined,
        title: 'Cam kết chất lượng',
        text: 'Giao nhanh, hỗ trợ đổi trả rõ ràng.',
        color: const Color(0xFF101828),
        onTap: onSeedTap,
        trailing: userId.isEmpty ? null : QuickSeedButton(userId: userId),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: List.generate(cards.length, (index) {
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == cards.length - 1 ? 0 : 14),
                child: cards[index],
              ),
            );
          }),
        );
      },
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 86),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style:
                        const TextStyle(color: Color(0xFF667085), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Flexible(child: trailing!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeProductGridSliver extends StatefulWidget {
  const _HomeProductGridSliver({
    required this.products,
    required this.campaignFlashSales,
    required this.gridColumns,
    required this.compactCard,
  });

  final List<Product> products;
  final List<FlashSale> campaignFlashSales;
  final int gridColumns;
  final bool compactCard;

  @override
  State<_HomeProductGridSliver> createState() => _HomeProductGridSliverState();
}

class _HomeProductGridSliverState extends State<_HomeProductGridSliver> {
  Timer? _priceTickTimer;

  bool get _needsPriceTick => widget.campaignFlashSales
      .any((sale) => sale.isVisibleToUsers && !sale.isScheduleEnded);

  @override
  void initState() {
    super.initState();
    _syncPriceTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeProductGridSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPriceTimer();
  }

  void _syncPriceTimer() {
    if (_needsPriceTick) {
      _priceTickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _priceTickTimer?.cancel();
      _priceTickTimer = null;
    }
  }

  @override
  void dispose() {
    _priceTickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFlashSales =
        widget.campaignFlashSales.where((sale) => sale.isActive).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      sliver: SliverConstrainedCrossAxis(
        maxExtent: 1180,
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridColumns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: widget.compactCard ? 0.72 : 0.76,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = widget.products[index];
              final flashSale =
                  PricingUtils.pickBestFlashSale(product, activeFlashSales);
              return _ProductCard(
                product: product,
                flashSale: flashSale,
                index: index,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            },
            childCount: widget.products.length,
          ),
        ),
      ),
    );
  }
}

class _HomePagination extends StatelessWidget {
  const _HomePagination({
    required this.currentPage,
    required this.totalPages,
    required this.productsPerPage,
    required this.totalProducts,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final int productsPerPage;
  final int totalProducts;
  final ValueChanged<int> onPageSelected;

  static const _inactiveBg = Color(0xFFF2F4F7);

  @override
  Widget build(BuildContext context) {
    final startItem = (currentPage - 1) * productsPerPage + 1;
    final endItem = (currentPage * productsPerPage).clamp(0, totalProducts);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hiển thị $startItem–$endItem / $totalProducts sản phẩm',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageNavButton(
                  icon: Icons.chevron_left,
                  label: 'Trước',
                  enabled: currentPage > 1,
                  onTap: () => onPageSelected(currentPage - 1),
                ),
                for (final page in _visiblePages(currentPage, totalPages)) ...[
                  const SizedBox(width: 6),
                  if (page == -1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '...',
                        style: TextStyle(
                          color: Color(0xFF98A2B3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    _PageNumberButton(
                      page: page,
                      isActive: page == currentPage,
                      onTap: () => onPageSelected(page),
                    ),
                ],
                const SizedBox(width: 6),
                _PageNavButton(
                  icon: Icons.chevron_right,
                  label: 'Sau',
                  enabled: currentPage < totalPages,
                  onTap: () => onPageSelected(currentPage + 1),
                  iconAfterLabel: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _visiblePages(int current, int total) {
    if (total <= 7) {
      return List<int>.generate(total, (index) => index + 1);
    }

    final pages = <int>{1, total, current};
    if (current > 1) pages.add(current - 1);
    if (current < total) pages.add(current + 1);
    if (current <= 3) pages.addAll([2, 3]);
    if (current >= total - 2) pages.addAll([total - 1, total - 2]);

    final sorted = pages.where((p) => p >= 1 && p <= total).toList()..sort();
    final result = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) {
        result.add(-1);
      }
      result.add(sorted[i]);
    }
    return result;
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? _HomeScreenState.accent
          : _HomePagination._inactiveBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF344054),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.label,
    this.iconAfterLabel = false,
  });

  final IconData icon;
  final String? label;
  final bool enabled;
  final bool iconAfterLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? const Color(0xFF344054) : const Color(0xFFCBD5E1);

    return Material(
      color: _HomePagination._inactiveBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!iconAfterLabel) ...[
                  Icon(icon, size: 18, color: color),
                  if (label != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ] else ...[
                  if (label != null) ...[
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(icon, size: 18, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.productCount,
    required this.sortBy,
    required this.onSortChanged,
  });

  final int productCount;
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Danh mục sản phẩm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 10),
        Text(
          '($productCount sản phẩm)',
          style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
        ),
        const Spacer(),
        const Icon(Icons.tune, size: 17, color: Color(0xFF667085)),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: sortBy,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            items: const [
              DropdownMenuItem(value: 'Phổ biến', child: Text('Phổ biến')),
              DropdownMenuItem(value: 'Mới nhất', child: Text('Mới nhất')),
              DropdownMenuItem(value: 'Giá tăng', child: Text('Giá tăng')),
              DropdownMenuItem(value: 'Giá giảm', child: Text('Giá giảm')),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final selected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (_) => onSelected(category),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF344054),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: _HomeScreenState.accent,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? _HomeScreenState.accent
                    : const Color(0xFFE4E7EC),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.flashSale,
    required this.index,
    required this.onTap,
  });

  final Product product;
  final FlashSale? flashSale;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayPrice = PricingUtils.resolveUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
      flashSale: flashSale?.isActive == true ? flashSale : null,
      productId: product.id,
    );
    final regularPrice = PricingUtils.regularUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
    );
    final flashPrice = flashSale == null
        ? null
        : flashSale!.flashPriceForProduct(product.price, product.id);
    final hasFlashDiscount = flashPrice != null && flashPrice < regularPrice;
    final hasRegularDiscount =
        product.hasDiscount && displayPrice < product.price;
    final badge =
        hasFlashDiscount ? 'FLASH SALE' : (index % 3 == 0 ? 'BÁN CHẠY' : null);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EAF0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF2F4F7),
                        child: ProductImage(
                          product: product,
                          fit: BoxFit.contain,
                          iconSize: 54,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (_) => const Icon(Icons.star,
                            size: 12, color: Color(0xFFFFB020)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasFlashDiscount || hasRegularDiscount)
                      Text(
                        '${_formatCurrency(product.price)}đ',
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatCurrency(displayPrice)}đ',
                            style: const TextStyle(
                              color: _HomeScreenState.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 15,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF98A2B3)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: const Center(
        child: Text(
          '© 2026 SmartDeal Shop. All rights reserved.',
          style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
        ),
      ),
    );
  }
}
