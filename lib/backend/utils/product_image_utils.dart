import '../models/product.dart';

/// Ảnh sản phẩm — URL ổn định + fallback khi link hỏng/trống.
class ProductImageUtils {
  ProductImageUtils._();

  static String _unsplash(String photoId) =>
      'https://images.unsplash.com/photo-$photoId?auto=format&fit=crop&w=600&h=600&q=80';

  static const _seedImages = <String, String>{
    'phone-iphone-15-pro': '1511707171634-5f897ff02aa9',
    'phone-samsung-s24-ultra': '1610945267461-47f660fccedc',
    'phone-xiaomi-14': '1598329356669-8d67bbf97826',
    'phone-oppo-reno11': '1565849907041-02ddccff51b4',
    'phone-vivo-v30': '1585066545893-06d4a1c9e3b0',
    'phone-pixel-8-pro': '1598329356669-8d67bbf97826',
    'laptop-macbook-air-m3': '1496181133206-80ce9b88a853',
    'laptop-dell-xps-13': '1496181133206-80ce9b88a853',
    'laptop-asus-zenbook-14': '1496181133206-80ce9b88a853',
    'laptop-lenovo-legion-5': '1603302576837-37561b2e2302',
    'laptop-hp-pavilion-15': '1496181133206-80ce9b88a853',
    'watch-apple-series-9': '1523275335684-37898b6baf30',
    'watch-samsung-watch6': '1523275335684-37898b6baf30',
    'watch-garmin-venu-3': '1523275335684-37898b6baf30',
    'watch-huawei-gt4': '1523275335684-37898b6baf30',
    'camera-canon-r50': '1516035069371-29a1b244cc32',
    'camera-sony-zve10': '1516035069371-29a1b244cc32',
    'camera-fujifilm-xs20': '15101270314-0401aa4dd2b0',
    'camera-gopro-hero12': '1526178613889-786ce947f82e',
    'audio-airpods-pro-2': '1572569511254-4968d67e4424',
    'audio-sony-wh1000xm5': '1505740420928-5e560c06d30e',
    'audio-jbl-charge-5': '1608043150319-1c65a4d46205',
    'audio-soundcore-liberty-4': '1590658268037-94b21a888751',
    'audio-marshall-emberton-ii': '1608043150319-1c65a4d46205',
  };

  static const _nameKeywords = <String, String>{
    'iphone': '1511707171634-5f897ff02aa9',
    'samsung': '1610945267461-47f660fccedc',
    'galaxy': '1610945267461-47f660fccedc',
    'xiaomi': '1598329356669-8d67bbf97826',
    'oppo': '1565849907041-02ddccff51b4',
    'vivo': '1585066545893-06d4a1c9e3b0',
    'pixel': '1598329356669-8d67bbf97826',
    'macbook': '1496181133206-80ce9b88a853',
    'laptop': '1496181133206-80ce9b88a853',
    'dell': '1496181133206-80ce9b88a853',
    'asus': '1496181133206-80ce9b88a853',
    'lenovo': '1603302576837-37561b2e2302',
    'legion': '1603302576837-37561b2e2302',
    'hp pavilion': '1496181133206-80ce9b88a853',
    'apple watch': '1523275335684-37898b6baf30',
    'galaxy watch': '1523275335684-37898b6baf30',
    'garmin': '1523275335684-37898b6baf30',
    'huawei watch': '1523275335684-37898b6baf30',
    'canon': '1516035069371-29a1b244cc32',
    'sony zv': '1516035069371-29a1b244cc32',
    'fujifilm': '15101270314-0401aa4dd2b0',
    'gopro': '1526178613889-786ce947f82e',
    'airpods': '1572569511254-4968d67e4424',
    'wh-1000xm5': '1505740420928-5e560c06d30e',
    'jbl charge': '1608043150319-1c65a4d46205',
    'soundcore': '1590658268037-94b21a888751',
    'marshall': '1608043150319-1c65a4d46205',
    'ipad': '1544244015-0df4b3ffc6b0',
  };

  static String imageForSeedProduct(String productId) {
    final photoId = _seedImages[productId];
    if (photoId != null) return _unsplash(photoId);
    return categoryFallback('Khác');
  }

  static bool needsFallback(String url) {
    final trimmed = url.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (trimmed.contains('placehold.co')) return true;
    if (trimmed.contains('cdn.tgdd.vn')) return true;
    if (trimmed.contains('via.placeholder')) return true;
    return false;
  }

  static String categoryFallback(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('laptop') || normalized.contains('máy tính')) {
      return _unsplash('1496181133206-80ce9b88a853');
    }
    if (normalized.contains('điện thoại') || normalized.contains('phone')) {
      return _unsplash('1511707171634-5f897ff02aa9');
    }
    if (normalized.contains('đồng hồ') || normalized.contains('watch')) {
      return _unsplash('1523275335684-37898b6baf30');
    }
    if (normalized.contains('máy ảnh') || normalized.contains('camera')) {
      return _unsplash('1516035069371-29a1b244cc32');
    }
    if (normalized.contains('âm thanh') ||
        normalized.contains('tai nghe') ||
        normalized.contains('audio')) {
      return _unsplash('1505740420928-5e560c06d30e');
    }
    if (normalized.contains('tablet') || normalized.contains('máy tính bảng')) {
      return _unsplash('1544244015-0df4b3ffc6b0');
    }
    return _unsplash('1511707171634-5f897ff02aa9');
  }

  static String fallbackFor({
    String? productId,
    required String name,
    required String category,
  }) {
    if (productId != null && productId.isNotEmpty) {
      final seed = _seedImages[productId];
      if (seed != null) return _unsplash(seed);
    }

    final normalizedName = name.toLowerCase();
    for (final entry in _nameKeywords.entries) {
      if (normalizedName.contains(entry.key)) {
        return _unsplash(entry.value);
      }
    }

    return categoryFallback(category);
  }

  static String resolve({
    String? productId,
    required String url,
    required String name,
    required String category,
  }) {
    if (needsFallback(url)) {
      return fallbackFor(productId: productId, name: name, category: category);
    }
    return url.trim();
  }

  static String resolveProduct(Product product) {
    return resolve(
      productId: product.id,
      url: product.primaryImage,
      name: product.name,
      category: product.category,
    );
  }
}
