import 'package:flutter/material.dart';

import '../../backend/models/product.dart';
import '../../backend/utils/product_image_utils.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.product,
    this.url,
    this.name = '',
    this.category = '',
    this.productId,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
    this.backgroundColor = const Color(0xFFF2F4F7),
    this.iconColor = const Color(0xFF98A2B3),
  });

  final Product? product;
  final String? url;
  final String name;
  final String category;
  final String? productId;
  final BoxFit fit;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  String get _name => product?.name ?? name;
  String get _category => product?.category ?? category;
  String? get _productId => product?.id ?? productId;

  String get _resolvedUrl {
    if (product != null) {
      return ProductImageUtils.resolveProduct(product!);
    }
    return ProductImageUtils.resolve(
      productId: _productId,
      url: url ?? '',
      name: _name,
      category: _category,
    );
  }

  String get _fallbackUrl => ProductImageUtils.fallbackFor(
        productId: _productId,
        name: _name,
        category: _category,
      );

  @override
  Widget build(BuildContext context) {
    return _NetworkProductImage(
      url: _resolvedUrl,
      fallbackUrl: _fallbackUrl,
      fit: fit,
      iconSize: iconSize,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
    );
  }
}

class _NetworkProductImage extends StatelessWidget {
  const _NetworkProductImage({
    required this.url,
    required this.fallbackUrl,
    required this.fit,
    required this.iconSize,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String url;
  final String fallbackUrl;
  final BoxFit fit;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: backgroundColor,
          child: Center(
            child: SizedBox(
              width: iconSize * 0.45,
              height: iconSize * 0.45,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (url == fallbackUrl) {
          return ColoredBox(
            color: backgroundColor,
            child: Icon(Icons.image_outlined, size: iconSize, color: iconColor),
          );
        }

        return _NetworkProductImage(
          url: fallbackUrl,
          fallbackUrl: fallbackUrl,
          fit: fit,
          iconSize: iconSize,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
        );
      },
    );
  }
}
