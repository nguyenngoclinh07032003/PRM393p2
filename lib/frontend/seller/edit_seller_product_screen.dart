import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../backend/config/app_constants.dart';
import '../../backend/models/product.dart';

class EditSellerProductScreen extends StatefulWidget {
  const EditSellerProductScreen({super.key, required this.product});

  final Product product;

  @override
  State<EditSellerProductScreen> createState() => _EditSellerProductScreenState();
}

class _EditSellerProductScreenState extends State<EditSellerProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _categoryController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _descriptionController = TextEditingController(text: product.description);
    _priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    _salePriceController = TextEditingController(
      text: product.salePrice > 0 ? product.salePrice.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(text: product.stock.toString());
    _imageUrlController = TextEditingController(text: product.primaryImage);
    _categoryController = TextEditingController(text: product.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final imageUrl = _imageUrlController.text.trim();
      final imageUrls = imageUrl.isEmpty
          ? widget.product.imageUrls
          : [
              imageUrl,
              ...widget.product.imageUrls.where((url) => url != imageUrl),
            ];

      await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(widget.product.id)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'salePrice': _salePriceController.text.trim().isEmpty
            ? 0.0
            : double.parse(_salePriceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'category': _categoryController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật sản phẩm'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa sản phẩm'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_nameController, 'Tên sản phẩm'),
            _field(_descriptionController, 'Mô tả', maxLines: 3),
            _field(_priceController, 'Giá gốc', number: true),
            _field(_salePriceController, 'Giá khuyến mãi', number: true, requiredField: false),
            _field(_stockController, 'Số lượng kho', number: true),
            _field(_categoryController, 'Danh mục'),
            _field(_imageUrlController, 'URL hình ảnh', requiredField: false),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool requiredField = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: requiredField
            ? (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập $label' : null
            : null,
      ),
    );
  }
}
