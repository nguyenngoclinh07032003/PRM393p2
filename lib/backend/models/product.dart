import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_price_tier.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final double salePrice;
  final int stock;
  final String imageUrl;
  final List<String> imageUrls;
  final String category;
  final String status;
  final DateTime createdAt;
  final List<ProductPriceTier> priceTiers;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice = 0,
    required this.stock,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.category,
    this.status = 'active',
    required this.createdAt,
    this.priceTiers = const [],
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawImages = List<String>.from(data['imageUrls'] ?? []);
    final primaryImage = data['imageUrl'] as String? ?? '';
    final images = rawImages.isNotEmpty
        ? rawImages
        : (primaryImage.isNotEmpty ? [primaryImage] : <String>[]);

    final rawTiers = data['priceTiers'] as List<dynamic>? ?? [];

    return Product(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      salePrice: (data['salePrice'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      imageUrl: images.isNotEmpty ? images.first : primaryImage,
      imageUrls: images,
      category: data['category'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priceTiers: rawTiers
          .whereType<Map>()
          .map((e) => ProductPriceTier.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final images = imageUrls.isNotEmpty
        ? imageUrls
        : (imageUrl.isNotEmpty ? [imageUrl] : <String>[]);

    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'imageUrl': images.isNotEmpty ? images.first : imageUrl,
      'imageUrls': images,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'priceTiers': priceTiers.map((tier) => tier.toMap()).toList(),
    };
  }

  double get finalPrice => salePrice > 0 ? salePrice : price;
  bool get hasDiscount => salePrice > 0 && salePrice < price;
  double get discountPercent =>
      hasDiscount ? ((price - salePrice) / price * 100) : 0;

  List<String> get galleryImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl.isNotEmpty) return [imageUrl];
    return const [];
  }

  String get primaryImage {
    if (galleryImages.isNotEmpty) return galleryImages.first;
    return imageUrl;
  }
}
