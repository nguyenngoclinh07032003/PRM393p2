import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';

import '../../backend/config/app_constants.dart';
import '../../backend/models/product.dart';
import '../../backend/models/product_price_tier.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/product_image_service.dart';
import 'admin_navigation.dart';

import 'admin_theme.dart';

class AdminProductFormBody extends StatefulWidget {
  const AdminProductFormBody({
    super.key,
    this.product,
    this.onCancel,
    this.onSaved,
    this.showCardShell = true,
  });

  final Product? product;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;
  final bool showCardShell;

  bool get isEditing => product != null;

  @override
  State<AdminProductFormBody> createState() => _AdminProductFormBodyState();
}

class _AdminProductFormBodyState extends State<AdminProductFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _salePriceController;

  List<String> _imageUrls = [];
  List<ProductPriceTier> _priceTiers = [];
  final List<_TierFieldControllers> _tierFields = [];
  Listenable? _pricingListenable;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  int _tierEditorGeneration = 0;
  final ProductImageService _productImageService = ProductImageService();

  void _initTierFields(List<ProductPriceTier> tiers) {
    for (final field in _tierFields) {
      field.dispose();
    }
    _tierFields
      ..clear()
      ..addAll(
        tiers.map((tier) => _TierFieldControllers.fromTier(tier)),
      );
    _rebuildPricingListenable();
  }

  void _rebuildPricingListenable() {
    _pricingListenable = Listenable.merge([
      _salePriceController,
      for (final field in _tierFields) ...[
        field.minQty,
        field.maxQty,
        field.unitPrice,
      ],
    ]);
  }

  double _listedPriceFromTiers(List<ProductPriceTier> tiers) {
    if (tiers.isEmpty) return 0;
    final sorted = [...tiers]..sort((a, b) => a.minQty.compareTo(b.minQty));
    return sorted.first.unitPrice;
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '100',
    );
    _salePriceController = TextEditingController(
      text: product != null && product.salePrice > 0
          ? _formatPriceInput(product.salePrice)
          : '',
    );
    _imageUrls = List<String>.from(product?.galleryImages ?? []);
    _priceTiers = product?.priceTiers.isNotEmpty == true
        ? List<ProductPriceTier>.from(product!.priceTiers)
        : _defaultTiers();
    _initTierFields(_priceTiers);
  }

  List<ProductPriceTier> _readTiersFromFields() {
    return List<ProductPriceTier>.generate(
      _tierFields.length,
      (index) => _tierFields[index].toTier(
        isLast: index == _tierFields.length - 1,
      ),
    );
  }

  List<ProductPriceTier> _defaultTiers() {
    return const [
      ProductPriceTier(minQty: 1, maxQty: 49, unitPrice: 0),
      ProductPriceTier(minQty: 50, maxQty: 99, unitPrice: 0),
      ProductPriceTier(minQty: 100, unitPrice: 0),
    ];
  }

  double? get _salePrice {
    return _parsePriceInput(_salePriceController.text);
  }

  String _formatPriceInput(double value) {
    if (value <= 0) return '';
    final digits = value.toStringAsFixed(0);
    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  double? _parsePriceInput(String raw) {
    final digits = raw.replaceAll('.', '').trim();
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}đ';
  }

  void _resetFormForNewProduct() {
    _nameController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _stockController.text = '100';
    _salePriceController.clear();
    setState(() {
      _imageUrls = [];
      _priceTiers = _defaultTiers();
      _initTierFields(_priceTiers);
      _tierEditorGeneration++;
    });
  }

  @override
  void dispose() {
    for (final field in _tierFields) {
      field.dispose();
    }
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _addTier() {
    final last = _priceTiers.isEmpty ? null : _priceTiers.last;
    final nextMin = last == null
        ? 1
        : (last.maxQty == null ? last.minQty + 1 : last.maxQty! + 1);

    setState(() {
      if (last != null && last.maxQty == null) {
        _priceTiers = [
          ..._priceTiers.sublist(0, _priceTiers.length - 1),
          last.copyWith(maxQty: nextMin - 1),
          ProductPriceTier(minQty: nextMin, unitPrice: last.unitPrice),
        ];
      } else {
        _priceTiers = [
          ..._priceTiers,
          ProductPriceTier(minQty: nextMin, unitPrice: last?.unitPrice ?? 0),
        ];
      }
      _initTierFields(_priceTiers);
      _tierEditorGeneration++;
    });
  }

  void _removeTier(int index) {
    if (_priceTiers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 bậc giá')),
      );
      return;
    }
    setState(() {
      _priceTiers.removeAt(index);
      _initTierFields(_priceTiers);
      _tierEditorGeneration++;
    });
  }

  Future<void> _pickImage({int? replaceIndex}) async {
    if (_isUploadingImage) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện máy'),
              subtitle: const Text('Lấy ảnh từ máy tính hoặc điện thoại'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Dán link ảnh'),
              subtitle: const Text('Nhập URL hình ảnh từ internet'),
              onTap: () => Navigator.pop(context, 'url'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || source == null) return;

    if (source == 'gallery') {
      await _pickFromGallery(replaceIndex: replaceIndex);
    } else {
      await _pickImageUrl(replaceIndex: replaceIndex);
    }
  }

  Future<void> _pickFromGallery({int? replaceIndex}) async {
    try {
      final file = await _productImageService.pickFromGallery();
      if (file == null || !mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        _showError('Vui lòng đăng nhập để tải ảnh');
        return;
      }

      setState(() => _isUploadingImage = true);

      final downloadUrl = await _productImageService.uploadImage(
        file: file,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        if (replaceIndex != null) {
          _imageUrls[replaceIndex] = downloadUrl;
        } else if (_imageUrls.length < 4) {
          _imageUrls.add(downloadUrl);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải ảnh lên thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) _showError('Không tải được ảnh: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickImageUrl({int? replaceIndex}) async {
    final controller = TextEditingController(
      text: replaceIndex != null ? _imageUrls[replaceIndex] : '',
    );

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(replaceIndex == null ? 'Thêm ảnh sản phẩm' : 'Sửa ảnh'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL hình ảnh',
            border: OutlineInputBorder(),
            hintText: 'https://...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty || !mounted) return;

    setState(() {
      if (replaceIndex != null) {
        _imageUrls[replaceIndex] = url;
      } else if (_imageUrls.length < 4) {
        _imageUrls.add(url);
      }
    });
  }

  bool _validateTiers() {
    final sorted = [..._priceTiers]..sort((a, b) => a.minQty.compareTo(b.minQty));
    for (var i = 0; i < sorted.length; i++) {
      final tier = sorted[i];
      if (tier.minQty < 1) {
        _showError('Số lượng từ phải >= 1');
        return false;
      }
      if (tier.unitPrice <= 0) {
        _showError('Đơn giá bậc ${i + 1} phải lớn hơn 0');
        return false;
      }
      if (tier.maxQty != null && tier.maxQty! < tier.minQty) {
        _showError('Bậc ${i + 1}: "Đến" phải >= "Số lượng từ"');
        return false;
      }
      if (i > 0) {
        final prev = sorted[i - 1];
        final prevEnd = prev.maxQty ?? prev.minQty;
        if (tier.minQty <= prevEnd) {
          _showError('Các bậc giá không được chồng lấn');
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Map<String, dynamic> _buildPayload() {
    final sortedTiers = [..._priceTiers]
      ..sort((a, b) => a.minQty.compareTo(b.minQty));
    final listedPrice = sortedTiers.first.unitPrice;

    return {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _categoryController.text.trim(),
      'price': listedPrice,
      'salePrice': _parsePriceInput(_salePriceController.text) ?? 0.0,
      'stock': int.parse(_stockController.text.trim()),
      'imageUrls': _imageUrls,
      'imageUrl': _imageUrls.isNotEmpty ? _imageUrls.first : '',
      'priceTiers': sortedTiers.map((tier) => tier.toMap()).toList(),
    };
  }

  Future<void> _saveProduct() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _priceTiers = _readTiersFromFields();

    if (!_formKey.currentState!.validate()) return;
    if (!_validateTiers()) return;

    setState(() => _isSaving = true);

    try {
      final collection = FirebaseFirestore.instance
          .collection(AppConstants.productsCollection);

      if (widget.isEditing) {
        await collection.doc(widget.product!.id).update(_buildPayload());
      } else {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.uid;
        if (userId == null) return;

        await collection.add({
          ..._buildPayload(),
          'sellerId': userId,
          'status': AppConstants.productActive,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Đã cập nhật sản phẩm'
                : 'Đã lưu sản phẩm thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        AdminNavigation.navigate(context, AppRoutes.adminProducts);
      }

      if (!widget.isEditing) {
        _resetFormForNewProduct();
      }
    } catch (e) {
      if (mounted) _showError('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    AdminNavigation.navigate(context, AppRoutes.adminProducts);
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AdminTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.isEditing
                    ? 'Chỉnh Sửa Sản Phẩm'
                    : 'Thêm & Chỉnh Sửa Sản Phẩm',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isEditing
                ? 'Cập nhật thông tin, hình ảnh và bảng giá theo số lượng.'
                : 'Nhập thông tin chi tiết cho sản phẩm mới của bạn.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Tên Sản Phẩm *',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: Áo Thun Cao Cấp SmartDeal',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên sản phẩm' : null,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _labeledField(
                  label: 'Danh Mục *',
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: _inputDecoration(hint: 'Ví dụ: Âm thanh'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập danh mục' : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _labeledField(
            label: 'Mô Tả Sản Phẩm *',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(
                hint: 'Mô tả các điểm nổi bật, chất liệu, kích thước...',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập mô tả sản phẩm' : null,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Số lượng kho *',
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(hint: '100'),
                    validator: (v) {
                      if (v == null || int.tryParse(v.trim()) == null) {
                        return 'Nhập số lượng hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _labeledField(
                  label: 'Giá khuyến mãi (VNĐ)',
                  child: TextFormField(
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_VndThousandsInputFormatter()],
                    decoration: _inputDecoration(hint: 'Tùy chọn'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Hình Ảnh Sản Phẩm',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _buildImageSlot(i)),
              ],
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cấu Hình Giá Theo Số Lượng (Tier Pricing)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addTier,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Thêm bậc giá'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TierPricingEditor(
            key: ValueKey('tier-editor-$_tierEditorGeneration'),
            tierFields: _tierFields,
            onRemove: _removeTier,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pricingListenable ?? _salePriceController,
            builder: (context, _) {
              final tiers = _readTiersFromFields();
              return _PricePreviewCard(
                listedPrice: _listedPriceFromTiers(tiers),
                salePrice: _salePrice,
                tiers: tiers,
                formatMoney: _formatMoney,
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : _handleCancel,
                child: const Text('Hủy bỏ'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.isEditing ? 'Lưu thay đổi' : 'Lưu Sản Phẩm'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!widget.showCardShell) return content;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: content,
    );
  }

  Widget _buildImageSlot(int index) {
    if (index < _imageUrls.length) {
      final url = _imageUrls[index];
      return AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            InkWell(
              onTap: _isUploadingImage
                  ? null
                  : () => _pickImage(replaceIndex: index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 256,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _uploadBox(onTap: () {}),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => setState(() => _imageUrls.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (index == _imageUrls.length && _imageUrls.length < 4) {
      return _uploadBox(
        onTap: _isUploadingImage ? () {} : () => _pickImage(),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2DA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          [Icons.weekend_outlined, Icons.mouse_outlined, Icons.speaker_outlined]
              [index % 3],
          size: 34,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _uploadBox({required VoidCallback onTap}) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0D5DD)),
            color: const Color(0xFFFAFBFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isUploadingImage
                    ? Icons.hourglass_top
                    : Icons.add_photo_alternate_outlined,
                color: const Color(0xFF667085),
              ),
              const SizedBox(height: 8),
              Text(
                _isUploadingImage ? 'Đang tải...' : 'Tải ảnh lên',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AdminTheme.accent),
      ),
    );
  }
}

class _PricePreviewCard extends StatelessWidget {
  const _PricePreviewCard({
    required this.listedPrice,
    required this.salePrice,
    required this.tiers,
    required this.formatMoney,
  });

  final double listedPrice;
  final double? salePrice;
  final List<ProductPriceTier> tiers;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final sorted = [...tiers]..sort((a, b) => a.minQty.compareTo(b.minQty));
    final hasValidListed = listedPrice > 0;
    final hasSale = salePrice != null && salePrice! > 0 && salePrice! < listedPrice;
    final displayPrice = hasSale ? salePrice! : (hasValidListed ? listedPrice : 0.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF0E7490)),
              SizedBox(width: 8),
              Text(
                'Xem trước giá (sau khi lưu)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E7490),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasValidListed)
            const Text(
              'Nhập đơn giá bậc đầu tiên để xem giá niêm yết.',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            )
          else ...[
            Row(
              children: [
                if (hasSale) ...[
                  Text(
                    formatMoney(listedPrice),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A2B3),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  formatMoney(displayPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                if (hasSale)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Giá sale',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFE11D48)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Giá niêm yết lưu DB: ${formatMoney(listedPrice)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
            ),
          ],
          if (sorted.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Bậc giá theo số lượng:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 6),
            for (final tier in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  tier.maxQty == null
                      ? 'Từ ${tier.minQty} sp: ${tier.unitPrice > 0 ? formatMoney(tier.unitPrice) : '—'}'
                      : '${tier.minQty}–${tier.maxQty} sp: ${tier.unitPrice > 0 ? formatMoney(tier.unitPrice) : '—'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF344054)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TierFieldControllers {
  _TierFieldControllers._({
    required this.minQty,
    required this.maxQty,
    required this.unitPrice,
    VoidCallback? onChanged,
  }) {
    if (onChanged != null) {
      minQty.addListener(onChanged);
      maxQty.addListener(onChanged);
      unitPrice.addListener(onChanged);
    }
  }

  factory _TierFieldControllers.fromTier(
    ProductPriceTier tier, {
    VoidCallback? onChanged,
  }) {
    return _TierFieldControllers._(
      minQty: TextEditingController(text: tier.minQty.toString()),
      maxQty: TextEditingController(text: tier.maxQty?.toString() ?? ''),
      unitPrice: TextEditingController(
        text: tier.unitPrice > 0 ? _formatTierPriceInput(tier.unitPrice) : '',
      ),
      onChanged: onChanged,
    );
  }

  final TextEditingController minQty;
  final TextEditingController maxQty;
  final TextEditingController unitPrice;

  void dispose() {
    minQty.dispose();
    maxQty.dispose();
    unitPrice.dispose();
  }

  ProductPriceTier toTier({required bool isLast}) {
    final parsedMin = int.tryParse(minQty.text.trim());
    final maxText = maxQty.text.trim();
    int? parsedMax;
    if (!isLast || maxText.isNotEmpty) {
      parsedMax = int.tryParse(maxText);
    }

    return ProductPriceTier(
      minQty: parsedMin ?? 1,
      maxQty: isLast && maxText.isEmpty ? null : parsedMax,
      unitPrice: _parseUnitPrice(unitPrice.text),
    );
  }
}

String _formatTierPriceInput(double value) {
  if (value <= 0) return '';
  return value.toStringAsFixed(0);
}

double _parseUnitPrice(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0;

  final direct = double.tryParse(trimmed);
  if (direct != null) return direct;

  final normalized = trimmed.replaceAll('.', '').replaceAll(',', '');
  return double.tryParse(normalized) ?? 0;
}

class _TierPricingEditor extends StatelessWidget {
  const _TierPricingEditor({
    super.key,
    required this.tierFields,
    required this.onRemove,
  });

  final List<_TierFieldControllers> tierFields;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: Text('Số lượng từ', style: _smallLabel)),
              SizedBox(width: 14),
              Expanded(child: Text('Đến', style: _smallLabel)),
              SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Text('Đơn giá (VNĐ)', style: _smallLabel),
              ),
              SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < tierFields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TierRow(
              fields: tierFields[i],
              isLast: i == tierFields.length - 1,
              onRemove: () => onRemove(i),
            ),
          ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.fields,
    required this.isLast,
    required this.onRemove,
  });

  final _TierFieldControllers fields;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _miniInput(controller: fields.minQty)),
        const SizedBox(width: 14),
        Expanded(
          child: isLast && fields.maxQty.text.trim().isEmpty
              ? _miniStatic('∞')
              : _miniInput(
                  controller: fields.maxQty,
                  hint: isLast ? '∞' : '',
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: _miniInput(controller: fields.unitPrice),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _miniInput({
    required TextEditingController controller,
    String hint = '',
  }) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: AdminTheme.accent),
          ),
        ),
      ),
    );
  }

  Widget _miniStatic(String value) {
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(value, style: const TextStyle(fontSize: 12)),
    );
  }
}

const _smallLabel = TextStyle(
  fontSize: 11,
  color: Color(0xFF667085),
  fontWeight: FontWeight.w800,
);

/// Định dạng giá VNĐ: 1000 → 1.000, 1000000 → 1.000.000
class _VndThousandsInputFormatter extends TextInputFormatter {
  const _VndThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
