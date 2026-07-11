import '../models/flash_sale.dart';
import '../models/product.dart';
import '../models/product_price_tier.dart';

class PricingUtils {
  static const int tierThreshold10 = 10;
  static const int tierThreshold50 = 50;

  /// Áp dụng giá theo bậc số lượng (ưu tiên cấu hình trên sản phẩm).
  static double applyTierDiscount(
    double unitPrice,
    int quantity, {
    List<ProductPriceTier>? tiers,
  }) {
    if (tiers != null && tiers.isNotEmpty) {
      final sorted = [...tiers]..sort((a, b) => a.minQty.compareTo(b.minQty));
      for (final tier in sorted) {
        if (tier.matchesQuantity(quantity)) {
          return tier.unitPrice;
        }
      }
      return unitPrice;
    }

    if (quantity >= tierThreshold50) return unitPrice * 0.90;
    if (quantity >= tierThreshold10) return unitPrice * 0.95;
    return unitPrice;
  }
  /// Giá sau Flash Sale (tính trên giá niêm yết, không stack salePrice).
  static double flashSalePrice(double listedPrice, double discountPercent) {
    return listedPrice * (1 - discountPercent / 100);
  }

  /// Giá bán hiển thị: salePrice nếu có, ngược lại giá niêm yết.
  static double regularUnitPrice({
    required double listedPrice,
    required double salePrice,
  }) {
    return salePrice > 0 && salePrice < listedPrice ? salePrice : listedPrice;
  }

  /// Giá cuối khi có Flash Sale: lấy mức thấp hơn giữa flash và giá thường.
  static double resolveUnitPrice({
    required double listedPrice,
    required double salePrice,
    double? flashDiscountPercent,
    FlashSale? flashSale,
    String? productId,
  }) {
    final regular = regularUnitPrice(
      listedPrice: listedPrice,
      salePrice: salePrice,
    );

    if (flashSale != null && flashSale.isActive) {
      final pid = productId;
      if (pid != null && !flashSale.hasFlashStockFor(pid)) {
        return regular;
      }
      final flash = pid != null
          ? flashSale.flashPriceForProduct(listedPrice, pid)
          : flashSalePrice(listedPrice, flashSale.discountPercent);
      return flash < regular ? flash : regular;
    }

    if (flashDiscountPercent == null || flashDiscountPercent <= 0) {
      return regular;
    }
    final flash = flashSalePrice(listedPrice, flashDiscountPercent);
    return flash < regular ? flash : regular;
  }

  /// Chọn flash sale rẻ nhất cho sản phẩm (đồng bộ Home / Cart / Flash Sale).
  static FlashSale? pickBestFlashSale(
    Product product,
    List<FlashSale> activeFlashSales,
  ) {
    final matches = activeFlashSales
        .where(
          (sale) =>
              sale.isActive && sale.appliesToProduct(product.id),
        )
        .toList();
    if (matches.isEmpty) return null;

    matches.sort(
      (a, b) => resolveUnitPrice(
        listedPrice: product.price,
        salePrice: product.salePrice,
        flashSale: a,
        productId: product.id,
      ).compareTo(
        resolveUnitPrice(
          listedPrice: product.price,
          salePrice: product.salePrice,
          flashSale: b,
          productId: product.id,
        ),
      ),
    );
    return matches.first;
  }

  static double productDisplayPrice(
    Product product,
    List<FlashSale> activeFlashSales,
  ) {
    final flashSale = pickBestFlashSale(product, activeFlashSales);
    return resolveUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
      flashSale: flashSale,
      productId: product.id,
    );
  }

  static bool hasPromoDisplayPrice(
    Product product,
    List<FlashSale> activeFlashSales,
  ) {
    return productDisplayPrice(product, activeFlashSales) < product.price;
  }

  /// Giá đơn vị khi checkout — flash sale (nếu đang chạy) + bậc giá, hoặc giá khóa mua nhóm.
  static double checkoutUnitPrice({
    required Product product,
    required int quantity,
    FlashSale? flashSale,
    double? lockedGroupBuyUnitPrice,
  }) {
    if (lockedGroupBuyUnitPrice != null) {
      return lockedGroupBuyUnitPrice;
    }
    final base = resolveUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
      flashSale: flashSale != null && flashSale.isActive ? flashSale : null,
      productId: product.id,
    );
    return applyTierDiscount(base, quantity, tiers: product.priceTiers);
  }
}
