import 'package:flutter/material.dart';

import '../../backend/models/product.dart';
import 'admin_product_form.dart';
import 'admin_theme.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key, this.product});

  final Product? product;

  @override
  Widget build(BuildContext context) => AddProductBody(product: product);
}

class AddProductBody extends StatelessWidget {
  const AddProductBody({
    super.key,
    this.product,
    this.onSaved,
    this.onCancel,
  });

  final Product? product;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AdminTheme.pagePadding,
      child: AdminProductFormBody(
        key: ValueKey(product?.id ?? 'new-product'),
        product: product,
        showCardShell: true,
        onSaved: onSaved,
        onCancel: onCancel,
      ),
    );
  }
}
