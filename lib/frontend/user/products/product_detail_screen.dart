import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import 'package:provider/provider.dart';
import '../../../backend/config/app_constants.dart';
import '../../../backend/models/flash_sale.dart';
import '../../../backend/models/product.dart';
import '../../../backend/models/product_price_tier.dart';
import '../../../backend/services/auth_service.dart';
import '../../../backend/services/cart_service.dart';
import '../../../backend/services/flash_sale_service.dart';
import '../../../backend/services/product_service.dart';
import '../../../backend/utils/pricing_utils.dart';
import '../../../backend/utils/product_image_utils.dart';
import '../../widgets/flash_sale_countdown.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color accent = Color(0xFF24C7E8);
  static const Color orange = Color(0xFFFF7A59);
  static const Color surface = Color(0xFFF7F8FB);

  FlashSale? _flashSale;
  FlashSale? _countdownFlashSale;
  bool _isLoadingFlashSale = true;
  int _quantity = 1;
  int _selectedImage = 0;
  Timer? _flashSaleTimer;

  @override
  void initState() {
    super.initState();
    _checkFlashSale();
  }

  Future<void> _checkFlashSale() async {
    final flashSaleService = FlashSaleService();
    final campaign = await flashSaleService.getFlashSaleCampaignForProduct(
      widget.product.id,
    );
    if (!mounted) return;
    setState(() {
      _flashSale = campaign;
      _countdownFlashSale = campaign;
      _isLoadingFlashSale = false;
    });
    _flashSaleTimer?.cancel();
    if (campaign != null && campaign.isVisibleToUsers) {
      _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _flashSaleTimer?.cancel();
    super.dispose();
  }

  double get _unitPriceBeforeTier {
    return PricingUtils.resolveUnitPrice(
      listedPrice: widget.product.price,
      salePrice: widget.product.salePrice,
      flashSale: _flashSale != null && _flashSale!.isActive ? _flashSale : null,
      productId: widget.product.id,
    );
  }

  double get _displayPrice => PricingUtils.applyTierDiscount(
        _unitPriceBeforeTier,
        _quantity,
        tiers: widget.product.priceTiers,
      );

  bool get _hasCampaignPrice =>
      (_flashSale != null && _flashSale!.isActive) ||
      widget.product.hasDiscount;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              onBack: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (route) => false),
              onCartTap: () => Navigator.pushNamed(context, AppRoutes.cart),
              onOrdersTap: () => Navigator.pushNamed(context, AppRoutes.orders),
              onLogoutTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (route) => false);
                }
              },
              userEmail: authService.currentUser?.email ?? '',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Breadcrumb(),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 860;
                                  final gallery = _ProductGallery(
                                    product: widget.product,
                                    selectedImage: _selectedImage,
                                    onImageSelected: (value) =>
                                        setState(() => _selectedImage = value),
                                  );
                                  final info = _ProductInfoPanel(
                                    product: widget.product,
                                    flashSale: _flashSale,
                                    countdownFlashSale: _countdownFlashSale,
                                    isLoadingFlashSale: _isLoadingFlashSale,
                                    displayPrice: _displayPrice,
                                    unitPriceBeforeTier: _unitPriceBeforeTier,
                                    hasCampaignPrice: _hasCampaignPrice,
                                    quantity: _quantity,
                                    onDecrease: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    onIncrease: _quantity < widget.product.stock
                                        ? () => setState(() => _quantity++)
                                        : null,
                                    onAddToCart: () => _addToCart(
                                        authService, cartService,
                                        goToCart: false),
                                    onBuyNow: () => _addToCart(
                                        authService, cartService,
                                        goToCart: true),
                                    formatCurrency: _formatCurrency,
                                  );
                                  if (compact) {
                                    return Column(children: [
                                      gallery,
                                      const SizedBox(height: 22),
                                      info
                                    ]);
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 43, child: gallery),
                                      const SizedBox(width: 34),
                                      Expanded(flex: 57, child: info),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 34),
                              _ProductTabs(
                                  product: widget.product,
                                  formatCurrency: _formatCurrency),
                              const SizedBox(height: 34),
                              _ShopSuggestionsSection(
                                product: widget.product,
                                formatCurrency: _formatCurrency,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const _DetailFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(AuthService authService, CartService cartService,
      {required bool goToCart}) async {
    try {
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        _showMessage('Vui lòng đăng nhập');
        return;
      }
      await cartService.addToCart(
        userId,
        widget.product,
        quantity: _quantity,
        unitPrice: _displayPrice,
      );
      if (!mounted) return;
      if (goToCart) {
        _openCart();
      } else {
        _showMessage('Đã thêm vào giỏ hàng!', success: true);
      }
    } catch (e) {
      if (mounted) _showMessage('Lỗi: $e');
    }
  }

  void _openCart() {
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.onCartTap,
    required this.onOrdersTap,
    required this.onLogoutTap,
    required this.userEmail,
  });

  final VoidCallback onBack;
  final VoidCallback onCartTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogoutTap;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return Row(
                children: [
                  const _BrandMark(),
                  if (!compact) ...[
                    const SizedBox(width: 28),
                    _NavButton(label: 'Home', onTap: onBack),
                    _NavButton(label: 'My Orders', onTap: onOrdersTap),
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
                                const BorderSide(color: Color(0xFFE4E7EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(
                                color: _ProductDetailScreenState.accent),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (compact)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.home_outlined, size: 20),
                      color: const Color(0xFF344054),
                      splashRadius: 20,
                    ),
                  IconButton(
                    onPressed: onOrdersTap,
                    icon: const Icon(Icons.receipt_long_outlined, size: 20),
                    color: const Color(0xFF344054),
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: onCartTap,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    color: const Color(0xFF344054),
                    splashRadius: 20,
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
              );
            },
          ),
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
                color: _ProductDetailScreenState.accent, size: 22),
            SizedBox(width: 6),
            Text('SmartDeal Shop',
                style: TextStyle(
                    color: _ProductDetailScreenState.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF101828),
          backgroundColor:
              label == 'Home' ? const Color(0xFFF1F3F6) : Colors.transparent,
          minimumSize: const Size(58, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Home / Products / Chi tiết sản phẩm',
      style: TextStyle(
          color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery(
      {required this.product,
      required this.selectedImage,
      required this.onImageSelected});
  final Product product;
  final int selectedImage;
  final ValueChanged<int> onImageSelected;

  @override
  Widget build(BuildContext context) {
    final fallback = ProductImageUtils.resolveProduct(product);
    final seen = <String>{};
    final images = product.galleryImages
        .map(
          (url) => ProductImageUtils.resolve(
            productId: product.id,
            url: url,
            name: product.name,
            category: product.category,
          ),
        )
        .where((url) => url.trim().isNotEmpty)
        .where((url) => seen.add(url))
        .toList();
    if (images.isEmpty) {
      images.add(fallback);
    }

    final selectedIndex = selectedImage.clamp(0, images.length - 1);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.antiAlias,
            child: ProductImage(
              productId: product.id,
              url: images[selectedIndex],
              name: product.name,
              category: product.category,
              fit: BoxFit.cover,
              iconSize: 86,
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            children: List.generate(images.length, (index) {
              final selected = index == selectedIndex;
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: index == images.length - 1 ? 0 : 12),
                  child: InkWell(
                    onTap: () => onImageSelected(index),
                    borderRadius: BorderRadius.circular(7),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECEF),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: selected
                                  ? _ProductDetailScreenState.accent
                                  : Colors.transparent,
                              width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: ProductImage(
                            productId: product.id,
                            url: images[index],
                            name: product.name,
                            category: product.category,
                            fit: BoxFit.cover,
                            iconSize: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ProductInfoPanel extends StatelessWidget {
  const _ProductInfoPanel({
    required this.product,
    required this.flashSale,
    required this.countdownFlashSale,
    required this.isLoadingFlashSale,
    required this.displayPrice,
    required this.unitPriceBeforeTier,
    required this.hasCampaignPrice,
    required this.quantity,
    required this.onDecrease,
    this.onIncrease,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.formatCurrency,
  });

  final Product product;
  final FlashSale? flashSale;
  final FlashSale? countdownFlashSale;
  final bool isLoadingFlashSale;
  final double displayPrice;
  final double unitPriceBeforeTier;
  final bool hasCampaignPrice;
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final discount = flashSale?.discountPercent ?? product.discountPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _Tag(
                text: product.category.isEmpty
                    ? 'SẢN PHẨM'
                    : product.category.toUpperCase(),
                color: _ProductDetailScreenState.accent),
            if (hasCampaignPrice)
              _Tag(
                  text: 'SALE ${discount.toStringAsFixed(0)}%',
                  color: _ProductDetailScreenState.orange),
          ],
        ),
        const SizedBox(height: 10),
        Text(product.name,
            style: const TextStyle(
                fontSize: 27,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF101828))),
        const SizedBox(height: 10),
        Row(
          children: [
            ...List.generate(
                5,
                (_) =>
                    const Icon(Icons.star, size: 15, color: Color(0xFFFFB020))),
            const SizedBox(width: 8),
            const Text('(128 đánh giá)',
                style: TextStyle(color: Color(0xFF667085), fontSize: 12)),
            const SizedBox(width: 12),
            Text('Đang có ${product.stock} sản phẩm',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          product.description.isEmpty
              ? 'Thiết kế hiện đại, chất lượng ổn định và mức giá tốt cho nhu cầu mua sắm hằng ngày.'
              : product.description,
          style: const TextStyle(
              color: Color(0xFF667085), height: 1.55, fontSize: 14),
        ),
        const SizedBox(height: 18),
        if (isLoadingFlashSale || countdownFlashSale != null) ...[
          _FlashSalePanel(
            isLoading: isLoadingFlashSale,
            countdownFlashSale: countdownFlashSale,
            active: flashSale != null && flashSale!.isActive,
            originalPrice: unitPriceBeforeTier,
            salePrice: displayPrice,
            discountPercent: discount,
            formatCurrency: formatCurrency,
          ),
          const SizedBox(height: 18),
        ],
        _TierPriceTable(
          unitPrice: unitPriceBeforeTier,
          quantity: quantity,
          formatCurrency: formatCurrency,
          priceTiers: product.priceTiers,
        ),
        const SizedBox(height: 18),
        _PurchaseBox(
          quantity: quantity,
          price: displayPrice,
          onDecrease: onDecrease,
          onIncrease: onIncrease,
          onAddToCart: onAddToCart,
          onBuyNow: onBuyNow,
          formatCurrency: formatCurrency,
          disabled: product.stock <= 0,
        ),
        const SizedBox(height: 18),
        const _TrustCards(),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _FlashSalePanel extends StatelessWidget {
  const _FlashSalePanel(
      {required this.isLoading,
      required this.countdownFlashSale,
      required this.active,
      required this.originalPrice,
      required this.salePrice,
      required this.discountPercent,
      required this.formatCurrency});
  final bool isLoading;
  final FlashSale? countdownFlashSale;
  final bool active;
  final double originalPrice;
  final double salePrice;
  final double discountPercent;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0EC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD5C7))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 38,
            color: _ProductDetailScreenState.orange,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text('KHUNG GIỜ VÀNG',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
                const Spacer(),
                Flexible(
                  child: FlashSaleCountdown(
                    startTime: countdownFlashSale?.countdownStartAt(),
                    endTime: countdownFlashSale?.countdownEndAt(),
                    unknownText: isLoading
                        ? 'Đang tải khung giờ'
                        : 'Chưa có khung giờ sale',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const LinearProgressIndicator(
                    color: _ProductDetailScreenState.accent)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${formatCurrency(salePrice)}đ',
                          style: const TextStyle(
                              color: _ProductDetailScreenState.orange,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      if (active || salePrice < originalPrice)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${formatCurrency(originalPrice)}đ',
                              style: const TextStyle(
                                  color: Color(0xFF98A2B3),
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough)),
                        ),
                      const SizedBox(width: 8),
                      if (active || discountPercent > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _Tag(
                              text: '-${discountPercent.toStringAsFixed(0)}%',
                              color: Colors.redAccent),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TierPriceTable extends StatelessWidget {
  const _TierPriceTable({
    required this.unitPrice,
    required this.quantity,
    required this.formatCurrency,
    this.priceTiers = const [],
  });
  final double unitPrice;
  final int quantity;
  final String Function(double value) formatCurrency;
  final List<ProductPriceTier> priceTiers;

  @override
  Widget build(BuildContext context) {
    final configuredTiers = priceTiers.isNotEmpty
        ? (priceTiers.toList()
          ..sort((a, b) => a.minQty.compareTo(b.minQty)))
        : <ProductPriceTier>[];

    final tiers = configuredTiers.isNotEmpty
        ? configuredTiers
            .map(
              (tier) => (
                tier.rangeLabel,
                tier.unitPrice,
                '${((1 - tier.unitPrice / unitPrice) * 100).clamp(0, 100).toStringAsFixed(0)}%',
              ),
            )
            .toList()
        : [
            (
              'Mua 1-9 cái',
              PricingUtils.applyTierDiscount(unitPrice, 1),
              'Giảm 0%',
            ),
            (
              'Từ 10-49 cái',
              PricingUtils.applyTierDiscount(unitPrice, 10),
              'Giảm 5%',
            ),
            (
              'Trên 50 cái',
              PricingUtils.applyTierDiscount(unitPrice, 50),
              'Giảm 10%',
            ),
          ];

    final activeTierIndex = configuredTiers.isNotEmpty
        ? configuredTiers.indexWhere((tier) => tier.matchesQuantity(quantity))
        : (quantity >= PricingUtils.tierThreshold50
            ? 2
            : quantity >= PricingUtils.tierThreshold10
                ? 1
                : 0);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: const [
                Text('Bảng giá sỉ theo số lượng',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                Spacer(),
                Text('Có chiết khấu khi mua nhiều',
                    style: TextStyle(
                        color: _ProductDetailScreenState.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          for (var i = 0; i < tiers.length; i++)
            Container(
              color: i == activeTierIndex
                  ? _ProductDetailScreenState.accent.withValues(alpha: 0.12)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                      child: Text(tiers[i].$1,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Text('${formatCurrency(tiers[i].$2)}đ',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w900))),
                  Text(tiers[i].$3,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF667085))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PurchaseBox extends StatelessWidget {
  const _PurchaseBox({
    required this.quantity,
    required this.price,
    required this.onDecrease,
    this.onIncrease,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.formatCurrency,
    required this.disabled,
  });

  final int quantity;
  final double price;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final String Function(double value) formatCurrency;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final quantityControl = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Số lượng',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(icon: Icons.remove, onTap: onDecrease),
              SizedBox(
                  width: 42,
                  child: Center(
                      child: Text('$quantity',
                          style:
                              const TextStyle(fontWeight: FontWeight.w900)))),
              _QuantityButton(icon: Icons.add, onTap: onIncrease),
            ],
          ),
        ),
      ],
    );

    final total = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Tổng cộng tạm tính',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
        const SizedBox(height: 8),
        Text(
          '${formatCurrency(price * quantity)}đ',
          style: const TextStyle(
              color: _ProductDetailScreenState.accent,
              fontSize: 24,
              fontWeight: FontWeight.w900),
        ),
      ],
    );

    final buyButton = ElevatedButton.icon(
      onPressed: disabled ? null : onBuyNow,
      icon: const Icon(Icons.flash_on, size: 16),
      label: const Text('MUA NGAY'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _ProductDetailScreenState.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB6CBD1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );

    final cartButton = OutlinedButton.icon(
      onPressed: disabled ? null : onAddToCart,
      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
      label: const Text('THÊM GIỎ'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF101828),
        side: const BorderSide(color: Color(0xFFD0D5DD)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          return Column(
            children: [
              if (compact) ...[
                Row(children: [quantityControl, const Spacer()]),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: total),
              ] else
                Row(children: [quantityControl, const Spacer(), total]),
              const SizedBox(height: 18),
              if (compact) ...[
                SizedBox(width: double.infinity, child: buyButton),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: cartButton),
              ] else
                Row(
                  children: [
                    Expanded(flex: 3, child: buyButton),
                    const SizedBox(width: 12),
                    Expanded(child: cartButton),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
          width: 34,
          height: 38,
          child: Icon(icon,
              size: 16,
              color: onTap == null
                  ? const Color(0xFFB7BDC7)
                  : const Color(0xFF344054))),
    );
  }
}

class _TrustCards extends StatelessWidget {
  const _TrustCards();

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        Icons.local_shipping_outlined,
        'Miễn phí vận chuyển',
        'Cho đơn hàng từ 2 triệu'
      ),
      (
        Icons.verified_user_outlined,
        'Bảo hành chính hãng',
        'Cam kết sản phẩm mới'
      ),
      (Icons.support_agent_outlined, 'Hỗ trợ 24/7', 'Tư vấn nhanh chóng'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        if (compact) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TrustCard(
                        icon: card.$1, title: card.$2, text: card.$3),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: List.generate(cards.length, (index) {
            final card = cards[index];
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == cards.length - 1 ? 0 : 12),
                child: _TrustCard(icon: card.$1, title: card.$2, text: card.$3),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard(
      {required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _ProductDetailScreenState.accent, size: 20),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF667085))),
        ],
      ),
    );
  }
}

class _ProductTabs extends StatelessWidget {
  const _ProductTabs({required this.product, required this.formatCurrency});
  final Product product;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0)))),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabLabel(text: 'Thông số kỹ thuật', active: true),
                  _TabLabel(text: 'Đánh giá khách hàng'),
                  _TabLabel(text: 'Câu hỏi thường gặp'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final left = _WhyBuy(product: product);
                final right =
                    _SpecsBox(product: product, formatCurrency: formatCurrency);
                if (constraints.maxWidth < 720)
                  return Column(
                      children: [left, const SizedBox(height: 20), right]);
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 34),
                      Expanded(child: right)
                    ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.text, this.active = false});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: active
                        ? _ProductDetailScreenState.accent
                        : Colors.transparent,
                    width: 2))),
        child: Text(text,
            style: TextStyle(
                color: active
                    ? _ProductDetailScreenState.accent
                    : const Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _WhyBuy extends StatelessWidget {
  const _WhyBuy({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tại sao nên mua sản phẩm này?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _BulletText(
            'Sản phẩm thuộc danh mục ${product.category.isEmpty ? 'mua sắm' : product.category} với mức giá cạnh tranh.'),
        const _BulletText(
            'Thiết kế hiện đại, phù hợp sử dụng hằng ngày và làm quà tặng.'),
        const _BulletText(
            'Hỗ trợ mua số lượng lớn với chính sách giá linh hoạt.'),
        const _BulletText(
            'Cam kết chất lượng và hỗ trợ sau bán hàng nhanh chóng.'),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF101828), size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFF344054), height: 1.45, fontSize: 13))),
        ],
      ),
    );
  }
}

class _SpecsBox extends StatelessWidget {
  const _SpecsBox({required this.product, required this.formatCurrency});
  final Product product;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Danh mục',
        product.category.isEmpty ? 'Chưa phân loại' : product.category
      ),
      ('Giá niêm yết', '${formatCurrency(product.price)}đ'),
      ('Tồn kho', '${product.stock} sản phẩm'),
      ('Trạng thái', product.status),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông số kỹ thuật',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: Text(row.$1,
                          style: const TextStyle(
                              color: Color(0xFF667085), fontSize: 12))),
                  Text(row.$2,
                      style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopSuggestionsSection extends StatefulWidget {
  const _ShopSuggestionsSection({
    required this.product,
    required this.formatCurrency,
  });

  final Product product;
  final String Function(double value) formatCurrency;

  @override
  State<_ShopSuggestionsSection> createState() =>
      _ShopSuggestionsSectionState();
}

class _ShopSuggestionsSectionState extends State<_ShopSuggestionsSection> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(covariant _ShopSuggestionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _loadSuggestions();
    }
  }

  void _loadSuggestions() {
    _suggestionsFuture = _productService.fetchShopSuggestions(
      currentProduct: widget.product,
    );
  }

  String get _sectionTitle {
    if (widget.product.sellerId.trim().isNotEmpty) {
      return 'Sản phẩm khác từ shop này';
    }
    if (widget.product.category.trim().isNotEmpty) {
      return 'Sản phẩm liên quan (${widget.product.category})';
    }
    return 'Sản phẩm gợi ý cho bạn';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Text(
              'Không tải được gợi ý sản phẩm: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          );
        }

        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.flashSalesCollection)
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, flashSnapshot) {
            final activeFlashSales = (flashSnapshot.data?.docs ?? [])
                .map((doc) => FlashSale.fromFirestore(doc))
                .where((sale) => sale.isActive)
                .toList();

            return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    color: _ProductDetailScreenState.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sectionTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  Text(
                    '${suggestions.length} sản phẩm',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Khám phá thêm những mặt hàng đang bán tại cùng cửa hàng.',
                style: TextStyle(color: Color(0xFF667085), fontSize: 13),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  if (compact) {
                    return SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => SizedBox(
                          width: 170,
                          child: _SuggestionProductCard(
                            product: suggestions[index],
                            activeFlashSales: activeFlashSales,
                            formatCurrency: widget.formatCurrency,
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth < 980 ? 3 : 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) => _SuggestionProductCard(
                      product: suggestions[index],
                      activeFlashSales: activeFlashSales,
                      formatCurrency: widget.formatCurrency,
                    ),
                  );
                },
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}

class _SuggestionProductCard extends StatelessWidget {
  const _SuggestionProductCard({
    required this.product,
    required this.activeFlashSales,
    required this.formatCurrency,
  });

  final Product product;
  final List<FlashSale> activeFlashSales;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final displayPrice =
        PricingUtils.productDisplayPrice(product, activeFlashSales);
    final hasPromo =
        PricingUtils.hasPromoDisplayPrice(product, activeFlashSales);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(
                product: product,
                fit: BoxFit.cover,
                iconSize: 42,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasPromo)
                    Text(
                      '${formatCurrency(product.price)}đ',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xFF98A2B3),
                        fontSize: 11,
                      ),
                    ),
                  Text(
                    '${formatCurrency(displayPrice)}đ',
                    style: const TextStyle(
                      color: _ProductDetailScreenState.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
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
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
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
