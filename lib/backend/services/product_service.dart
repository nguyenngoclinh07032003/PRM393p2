import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('status', isEqualTo: AppConstants.productActive)
        .snapshots()
        .map((snapshot) => _dedupeProducts(
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList()));
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: AppConstants.productActive)
        .snapshots()
        .map((snapshot) => _dedupeProducts(
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList()));
  }

  // Get products by seller
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    if (sellerId.trim().isEmpty) {
      return Stream.value(const <Product>[]);
    }
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => _dedupeProducts(
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList()));
  }

  /// Gợi ý sản phẩm khác cùng shop, cùng danh mục, hoặc sản phẩm khác.
  Stream<List<Product>> getShopSuggestions({
    required Product currentProduct,
    int limit = 8,
  }) {
    return Stream.fromFuture(
      fetchShopSuggestions(currentProduct: currentProduct, limit: limit),
    );
  }

  Future<List<Product>> fetchShopSuggestions({
    required Product currentProduct,
    int limit = 8,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('status', isEqualTo: AppConstants.productActive)
          .get();

      final all = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.stock > 0)
          .toList();

      final sellerId = currentProduct.sellerId.trim();
      final category = currentProduct.category.trim().toLowerCase();

      if (sellerId.isNotEmpty) {
        final sameSeller = _filterSuggestions(
          products: all.where((p) => p.sellerId.trim() == sellerId),
          currentProduct: currentProduct,
          limit: limit,
        );
        if (sameSeller.isNotEmpty) return sameSeller;
      }

      if (category.isNotEmpty) {
        final sameCategory = _filterSuggestions(
          products: all.where(
            (p) => p.category.trim().toLowerCase() == category,
          ),
          currentProduct: currentProduct,
          limit: limit,
        );
        if (sameCategory.isNotEmpty) return sameCategory;
      }

      return _filterSuggestions(
        products: all,
        currentProduct: currentProduct,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Fetch shop suggestions error: $e');
      return [];
    }
  }

  List<Product> _filterSuggestions({
    required Iterable<Product> products,
    required Product currentProduct,
    required int limit,
  }) {
    final seenIds = <String>{};
    final filtered = <Product>[];

    for (final product in products) {
      if (product.id == currentProduct.id) continue;
      if (product.status != AppConstants.productActive) continue;
      if (product.stock <= 0) continue;
      if (!seenIds.add(product.id)) continue;
      filtered.add(product);
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList();
  }

  // Get single product
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get product error: $e');
      return null;
    }
  }

  // Add product (Seller only)
  Future<String?> addProduct(Product product) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Add product error: $e');
      rethrow;
    }
  }

  // Update product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update(data);
    } catch (e) {
      debugPrint('Update product error: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({'status': AppConstants.productInactive});
    } catch (e) {
      debugPrint('Delete product error: $e');
      rethrow;
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('status', isEqualTo: AppConstants.productActive)
          .get();

      return _dedupeProducts(snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()))
          .toList());
    } catch (e) {
      debugPrint('Search products error: $e');
      return [];
    }
  }

  List<Product> _dedupeProducts(List<Product> products) {
    final byId = <String, Product>{};
    for (final product in products) {
      if (product.id.isEmpty) continue;
      byId[product.id] = product;
    }
    return byId.values.toList();
  }
}
