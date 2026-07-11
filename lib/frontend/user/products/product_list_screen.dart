import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../backend/config/app_constants.dart';
import '../../../backend/models/flash_sale.dart';
import '../../../backend/models/product.dart';
import '../../../backend/services/product_service.dart';
import '../../../backend/utils/pricing_utils.dart';
import '../../widgets/product_image.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;

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
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _productService.searchProducts(query);
    setState(() {
      _searchResults = results;
    });
  }

  List<FlashSale> _parseActiveFlashSales(QuerySnapshot? snapshot) {
    return (snapshot?.docs ?? [])
        .map((doc) => FlashSale.fromFirestore(doc))
        .where((sale) => sale.isActive)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchProducts,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _flashSalesStream,
              builder: (context, flashSnapshot) {
                final activeFlashSales =
                    _parseActiveFlashSales(flashSnapshot.data);

                if (_isSearching && _searchController.text.isNotEmpty) {
                  return _buildSearchResults(activeFlashSales);
                }
                return _buildProductStream(activeFlashSales);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<FlashSale> activeFlashSales) {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy sản phẩm'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_searchResults[index], activeFlashSales);
      },
    );
  }

  Widget _buildProductStream(List<FlashSale> activeFlashSales) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có sản phẩm'));
        }

        final products = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index], activeFlashSales);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, List<FlashSale> activeFlashSales) {
    final displayPrice =
        PricingUtils.productDisplayPrice(product, activeFlashSales);
    final hasPromo =
        PricingUtils.hasPromoDisplayPrice(product, activeFlashSales);
    final flashSale = PricingUtils.pickBestFlashSale(product, activeFlashSales);
    final regularPrice = PricingUtils.regularUnitPrice(
      listedPrice: product.price,
      salePrice: product.salePrice,
    );
    final hasFlashDiscount =
        flashSale != null && displayPrice < regularPrice;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: ProductImage(product: product, iconSize: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (hasPromo) ...[
                    Text(
                      '${product.price.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${displayPrice.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (hasFlashDiscount) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${flashSale.discountPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ] else if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${product.discountPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else
                    Text(
                      '${displayPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Kho: ${product.stock}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
