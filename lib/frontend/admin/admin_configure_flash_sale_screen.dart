import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/config/app_constants.dart';
import '../../backend/models/flash_sale.dart';
import '../../backend/models/product.dart';
import '../../backend/services/flash_sale_service.dart';
import '../../backend/services/product_service.dart';
import '../../backend/utils/flash_sale_validator.dart';
import '../../backend/utils/pricing_utils.dart';
import 'admin_theme.dart';
class AdminConfigureFlashSaleScreen extends StatelessWidget {
  const AdminConfigureFlashSaleScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminConfigureFlashSaleBody();
}

class AdminConfigureFlashSaleBody extends StatefulWidget {
  const AdminConfigureFlashSaleBody({super.key});

  @override
  State<AdminConfigureFlashSaleBody> createState() =>
      _AdminConfigureFlashSaleBodyState();
}

class _AdminConfigureFlashSaleBodyState
    extends State<AdminConfigureFlashSaleBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Flash Sale');
  final _discountController = TextEditingController(text: '15');
  final _noteController = TextEditingController();
  final FlashSaleService _flashSaleService = FlashSaleService();
  final ProductService _productService = ProductService();

  DateTime _campaignStartDate = DateTime.now();
  DateTime _campaignEndDate = DateTime.now().add(const Duration(days: 7));
  Set<int> _repeatWeekdays = {1, 2, 3, 4, 5, 6, 7};
  List<FlashSaleTimeSlot> _timeSlots = const [
    FlashSaleTimeSlot(
      label: 'Khung sáng',
      startHour: 9,
      startMinute: 0,
      endHour: 12,
      endMinute: 0,
    ),
  ];
  String? _editingSaleId;
  bool _applyAllProducts = false;
  final Set<String> _selectedProductIds = {};
  final Map<String, FlashSaleProductItem> _productItems = {};
  final Map<String, ({String name, double price})> _productMeta = {};
  FlashSaleQuantityResetMode _quantityResetMode =
      FlashSaleQuantityResetMode.sharedDaily;
  bool _allowRegularPriceAfterStockOut = true;
  bool _isSaving = false;
  final ValueNotifier<int> _productSelectionRevision = ValueNotifier(0);

  static const _weekdayButtons = <({int value, String label})>[
    (value: 1, label: 'T2'),
    (value: 2, label: 'T3'),
    (value: 3, label: 'T4'),
    (value: 4, label: 'T5'),
    (value: 5, label: 'T6'),
    (value: 6, label: 'T7'),
    (value: 7, label: 'CN'),
  ];

  @override
  void dispose() {
    _productSelectionRevision.dispose();
    _nameController.dispose();
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static const _slotPresets = <({String label, int sh, int sm, int eh, int em})>[
    (label: 'Sáng 9h-12h', sh: 9, sm: 0, eh: 12, em: 0),
    (label: 'Trưa 12h-15h', sh: 12, sm: 0, eh: 15, em: 0),
    (label: 'Chiều 15h-18h', sh: 15, sm: 0, eh: 18, em: 0),
    (label: 'Tối 18h-21h', sh: 18, sm: 0, eh: 21, em: 0),
    (label: 'Đêm 21h-23h', sh: 21, sm: 0, eh: 23, em: 0),
  ];

  DateTime get _computedStartTime => DateTime(
        _campaignStartDate.year,
        _campaignStartDate.month,
        _campaignStartDate.day,
      );

  DateTime get _computedEndTime => DateTime(
        _campaignEndDate.year,
        _campaignEndDate.month,
        _campaignEndDate.day,
        23,
        59,
        59,
      );

  Future<TimeOfDay?> _showSlotTimePicker(TimeOfDay initial) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) => _SlotTimePickerDialog(initial: initial),
    );
  }

  Future<void> _pickCampaignDate({required bool isStart}) async {
    final initial = isStart ? _campaignStartDate : _campaignEndDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    setState(() {
      if (isStart) {
        _campaignStartDate = date;
        if (_campaignEndDate.isBefore(_campaignStartDate)) {
          _campaignEndDate = _campaignStartDate;
        }
      } else {
        _campaignEndDate = date;
      }
    });
  }

  Future<void> _pickSlotTime({
    required int slotIndex,
    required bool isStart,
  }) async {
    final slot = _timeSlots[slotIndex];
    final initial = isStart ? slot.start : slot.end;
    final picked = await _showSlotTimePicker(initial);
    if (picked == null || !mounted) return;

    setState(() {
      final current = _timeSlots[slotIndex];
      _timeSlots = List<FlashSaleTimeSlot>.from(_timeSlots)
        ..[slotIndex] = isStart
            ? current.copyWith(
                startHour: picked.hour,
                startMinute: picked.minute,
              )
            : current.copyWith(
                endHour: picked.hour,
                endMinute: picked.minute,
              );
    });
  }

  void _addPresetSlot(({String label, int sh, int sm, int eh, int em}) preset) {
    setState(() {
      _timeSlots = [
        ..._timeSlots,
        FlashSaleTimeSlot(
          label: preset.label,
          startHour: preset.sh,
          startMinute: preset.sm,
          endHour: preset.eh,
          endMinute: preset.em,
        ),
      ];
    });
  }

  void _addEmptySlot() {
    setState(() {
      _timeSlots = [
        ..._timeSlots,
        const FlashSaleTimeSlot(
          label: 'Khung mới',
          startHour: 9,
          startMinute: 0,
          endHour: 12,
          endMinute: 0,
        ),
      ];
    });
  }

  void _removeSlot(int index) {
    if (_timeSlots.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 khung giờ sale')),
      );
      return;
    }
    setState(() {
      _timeSlots = List<FlashSaleTimeSlot>.from(_timeSlots)..removeAt(index);
    });
  }

  void _applyRepeatPreset(Set<int> days) {
    setState(() => _repeatWeekdays = Set<int>.from(days));
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_repeatWeekdays.contains(weekday)) {
        if (_repeatWeekdays.length > 1) {
          _repeatWeekdays.remove(weekday);
        }
      } else {
        _repeatWeekdays.add(weekday);
      }
    });
  }

  double get _defaultDiscount =>
      double.tryParse(_discountController.text.trim()) ?? 15;

  void _syncProductSelection(Product product, bool selected) {
    if (selected) {
      _selectedProductIds.add(product.id);
      _productMeta[product.id] = (name: product.name, price: product.price);
      _productItems[product.id] = FlashSaleProductItem(
        productId: product.id,
        flashSalePrice:
            PricingUtils.flashSalePrice(product.price, _defaultDiscount),
        quantityPerDay: 100,
        limitPerCustomer: 2,
      );
    } else {
      _selectedProductIds.remove(product.id);
      _productItems.remove(product.id);
      _productMeta.remove(product.id);
    }
    _productSelectionRevision.value++;
  }

  void _updateProductItem(
    String productId,
    FlashSaleProductItem item,
  ) {
    _productItems[productId] = item;
  }

  void _notifyProductSelectionChanged() {
    _productSelectionRevision.value++;
  }

  List<FlashSaleProductItem> get _builtProductItems =>
      _productItems.values.toList();

  void _loadSaleForEdit(FlashSale sale) {
    setState(() {
      _editingSaleId = sale.id;
      _nameController.text = sale.name;
      _noteController.text = sale.note;
      _discountController.text = sale.discountPercent.toStringAsFixed(0);
      _campaignStartDate =
          DateTime(sale.startTime.year, sale.startTime.month, sale.startTime.day);
      _campaignEndDate =
          DateTime(sale.endTime.year, sale.endTime.month, sale.endTime.day);
      _repeatWeekdays = sale.repeatWeekdays.isEmpty
          ? {1, 2, 3, 4, 5, 6, 7}
          : Set<int>.from(sale.repeatWeekdays);
      _timeSlots = sale.timeSlots.isNotEmpty
          ? List<FlashSaleTimeSlot>.from(sale.timeSlots)
          : [
              FlashSaleTimeSlot(
                label: 'Khung giờ',
                startHour: sale.startTime.hour,
                startMinute: sale.startTime.minute,
                endHour: sale.endTime.hour,
                endMinute: sale.endTime.minute,
              ),
            ];
      _applyAllProducts = sale.isAllProduct;
      _selectedProductIds
        ..clear()
        ..addAll(sale.effectiveProductIds);
      _productItems
        ..clear()
        ..addEntries(
          sale.productItems.map((item) => MapEntry(item.productId, item)),
        );
      _productMeta.clear();
      _quantityResetMode = sale.quantityResetMode;
      _allowRegularPriceAfterStockOut = sale.allowRegularPriceAfterStockOut;
    });
    _notifyProductSelectionChanged();
    _hydrateProductMeta();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang chỉnh sửa: ${sale.name}')),
    );
  }

  Future<void> _hydrateProductMeta() async {
    for (final id in _selectedProductIds) {
      if (_productMeta.containsKey(id)) continue;
      final product = await _productService.getProduct(id);
      if (product != null && mounted) {
        _productMeta[id] = (name: product.name, price: product.price);
        _notifyProductSelectionChanged();
      }
    }
  }

  void _resetForm() {
    setState(() {
      _editingSaleId = null;
      _nameController.text = 'Flash Sale';
      _noteController.clear();
      _discountController.text = '15';
      _campaignStartDate = DateTime.now();
      _campaignEndDate = DateTime.now().add(const Duration(days: 7));
      _repeatWeekdays = {1, 2, 3, 4, 5, 6, 7};
      _timeSlots = const [
        FlashSaleTimeSlot(
          label: 'Khung sáng',
          startHour: 9,
          startMinute: 0,
          endHour: 12,
          endMinute: 0,
        ),
      ];
      _applyAllProducts = false;
      _selectedProductIds.clear();
      _productItems.clear();
      _productMeta.clear();
      _quantityResetMode = FlashSaleQuantityResetMode.sharedDaily;
      _allowRegularPriceAfterStockOut = true;
    });
    _notifyProductSelectionChanged();
  }

  bool _validateTimeSlots() {
    final error = FlashSaleValidator.validateInternalTimeSlots(_timeSlots);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveFlashSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateTimeSlots()) return;

    if (!_applyAllProducts && _selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm cụ thể'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final weekdaysError =
        FlashSaleValidator.validateRepeatWeekdays(_repeatWeekdays.toList());
    if (weekdaysError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(weekdaysError), backgroundColor: Colors.red),
      );
      return;
    }

    if (!FlashSaleValidator.isValidDateRange(
      _campaignStartDate,
      _campaignEndDate,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final flashSale = FlashSale(
        id: _editingSaleId ?? '',
        name: _nameController.text.trim(),
        productIds: _applyAllProducts ? [] : _selectedProductIds.toList(),
        isAllProduct: _applyAllProducts,
        discountPercent: _defaultDiscount,
        startTime: _computedStartTime,
        endTime: _computedEndTime,
        status: 'active',
        timeSlots: _timeSlots,
        repeatWeekdays: _repeatWeekdays.toList()..sort(),
        note: _noteController.text.trim(),
        productItems: _applyAllProducts ? const [] : _builtProductItems,
        quantityResetMode: _quantityResetMode,
        allowRegularPriceAfterStockOut: _allowRegularPriceAfterStockOut,
      );

      final conflict = await _flashSaleService.validateBeforeSave(
        flashSale,
        excludeSaleId: _editingSaleId,
      );
      if (conflict != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(conflict), backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (_editingSaleId != null) {
        await _flashSaleService.updateFlashSale(
          _editingSaleId!,
          flashSale.toFirestore(),
        );
      } else {
        await _flashSaleService.createFlashSale(flashSale);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingSaleId != null
                ? 'Đã cập nhật Flash Sale'
                : 'Đã tạo Flash Sale thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
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

  Future<void> _endFlashSale(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc Flash Sale'),
        content: Text('Kết thúc chương trình "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _flashSaleService.endFlashSale(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã kết thúc Flash Sale'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd/MM/yyyy').format(value);
  }

  String _formatTimeSlotSummary(FlashSale sale) {
    if (sale.timeSlots.isEmpty) {
      return '${_formatDateTime(sale.startTime)} → ${_formatDateTime(sale.endTime)}';
    }
    final slots = sale.timeSlots.map((s) => s.formatRange()).join(', ');
    return '${_formatDate(sale.startTime)} → ${_formatDate(sale.endTime)}\n$slots';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }

  Widget _buildRepeatDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('2. Chọn ngày lặp lại'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdayButtons.map((day) {
            final selected = _repeatWeekdays.contains(day.value);
            return FilterChip(
              label: Text(day.label),
              selected: selected,
              onSelected: (_) => _toggleWeekday(day.value),
              selectedColor: AdminTheme.accent.withValues(alpha: 0.2),
              checkmarkColor: AdminTheme.accent,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Lựa chọn nhanh:',
          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Mỗi ngày'),
              onPressed: () => _applyRepeatPreset({1, 2, 3, 4, 5, 6, 7}),
            ),
            ActionChip(
              label: const Text('Thứ 2 – Thứ 6'),
              onPressed: () => _applyRepeatPreset({1, 2, 3, 4, 5}),
            ),
            ActionChip(
              label: const Text('Cuối tuần'),
              onPressed: () => _applyRepeatPreset({6, 7}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('4. Chọn sản phẩm'),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Chọn sản phẩm cụ thể'),
          subtitle: const Text(
            'Mặc định — cấu hình giá và số lượng từng sản phẩm',
          ),
          value: false,
          groupValue: _applyAllProducts,
          activeColor: AdminTheme.accent,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _applyAllProducts = value);
          },
        ),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Áp dụng cho tất cả sản phẩm'),
          subtitle: const Text(
            'Dùng mức giảm mặc định cho toàn bộ cửa hàng',
          ),
          value: true,
          groupValue: _applyAllProducts,
          activeColor: AdminTheme.accent,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _applyAllProducts = value;
              if (value) {
                _selectedProductIds.clear();
                _productItems.clear();
                _productMeta.clear();
              }
            });
          },
        ),
        if (_applyAllProducts)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFEC84B)),
            ),
            child: const Text(
              'Chế độ toàn cửa hàng có thể gây giảm giá nhầm. Chỉ bật khi bạn chắc chắn.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB54708)),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Chọn sản phẩm ở panel bên phải, sau đó chỉnh giá và số lượng trong bảng bên dưới.',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedProductsTable() {
    if (_selectedProductIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE4E7EC)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Chưa chọn sản phẩm nào. Dùng danh sách bên phải để thêm.',
          style: TextStyle(color: AdminTheme.textSecondary),
        ),
      );
    }

    return _SelectedProductsTable(
      key: ValueKey(_selectedProductIds.join('|')),
      productIds: _selectedProductIds.toList(),
      items: Map<String, FlashSaleProductItem>.from(_productItems),
      meta: Map<String, ({String name, double price})>.from(_productMeta),
      onItemChanged: _updateProductItem,
    );
  }

  Widget _buildQuantityRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('5. Quy tắc số lượng'),
        const Text(
          'Số lượng Flash Sale được reset lúc 00:00 mỗi ngày.',
          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 12),
        RadioListTile<FlashSaleQuantityResetMode>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reset theo từng khung giờ'),
          subtitle: const Text('Mỗi khung giờ có pool số lượng riêng'),
          value: FlashSaleQuantityResetMode.perSlot,
          groupValue: _quantityResetMode,
          activeColor: AdminTheme.accent,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _quantityResetMode = value);
          },
        ),
        RadioListTile<FlashSaleQuantityResetMode>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dùng chung cả ngày'),
          subtitle: const Text(
            'Ví dụ: 100 sản phẩm/ngày, tối đa 2 sản phẩm/khách',
          ),
          value: FlashSaleQuantityResetMode.sharedDaily,
          groupValue: _quantityResetMode,
          activeColor: AdminTheme.accent,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _quantityResetMode = value);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cho phép bán giá gốc khi hết hàng Flash Sale'),
          subtitle: const Text(
            'Tắt nếu muốn ẩn giá sale khi đã hết số lượng trong ngày',
          ),
          value: _allowRegularPriceAfterStockOut,
          activeThumbColor: AdminTheme.accent,
          onChanged: (value) {
            setState(() => _allowRegularPriceAfterStockOut = value);
          },
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Khung giờ sale trong ngày',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _addEmptySlot,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm khung'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Chọn mẫu nhanh hoặc chỉnh giờ bắt đầu/kết thúc cho từng khung',
          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _slotPresets
              .map(
                (preset) => ActionChip(
                  label: Text(preset.label),
                  onPressed: () => _addPresetSlot(preset),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _timeSlots.length; i++) ...[
          _TimeSlotCard(
            index: i,
            slot: _timeSlots[i],
            onPickStart: () => _pickSlotTime(slotIndex: i, isStart: true),
            onPickEnd: () => _pickSlotTime(slotIndex: i, isStart: false),
            onLabelChanged: (value) {
              setState(() {
                _timeSlots = List<FlashSaleTimeSlot>.from(_timeSlots)
                  ..[i] = _timeSlots[i].copyWith(label: value);
              });
            },
            onRemove: () => _removeSlot(i),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        _buildSchedulePreview(),
      ],
    );
  }

  Widget _buildSameDayHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9E6FE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Color(0xFF026AA2)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nếu ngày bắt đầu và ngày kết thúc giống nhau, Flash Sale chỉ áp dụng trong ngày đó theo các khung giờ đã thiết lập.',
              style: TextStyle(fontSize: 13, color: Color(0xFF026AA2), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview() {
    final rows = FlashSaleValidator.buildScheduleRows(
      startDate: _campaignStartDate,
      endDate: _campaignEndDate,
      slots: _timeSlots,
    );
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem trước lịch áp dụng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hết khung giờ, giá sản phẩm tự động trở về giá gốc.',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.2),
            },
            border: TableBorder.all(color: const Color(0xFFE4E7EC)),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withValues(alpha: 0.08),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Ngày áp dụng',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Khung giờ',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        row.dateRange,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        row.timeRange,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AdminTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quản Lý Flash Sale',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cấu hình khung giờ và sản phẩm khuyến mãi',
            style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;

                if (compact) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildForm(),
                        const Divider(height: 32),
                        SizedBox(
                          height: 520,
                          child: _buildSidePanel(expandProductList: true),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(child: _buildForm()),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: _buildSidePanel(expandProductList: true),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  Text(
                    _editingSaleId != null
                        ? 'Chỉnh sửa chương trình'
                        : 'Tạo chương trình mới',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_editingSaleId != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tạo chương trình mới'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên chương trình *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flash_on),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú / Lý do Flash Sale',
                      hintText:
                          'Ví dụ: Kỷ niệm ngày thành lập, xả kho cuối tuần...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mức giảm mặc định (%)',
                      helperText:
                          'Dùng khi thêm sản phẩm hoặc áp dụng toàn bộ cửa hàng',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    validator: (v) {
                      final discount = double.tryParse(v ?? '');
                      if (discount == null || discount <= 0 || discount >= 100) {
                        return 'Mức giảm phải từ 1 đến 99';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('1. Thời gian áp dụng'),
                  const SizedBox(height: 10),
                  _DateTimeTile(
                    label: 'Từ ngày',
                    value: _formatDate(_campaignStartDate),
                    onTap: () => _pickCampaignDate(isStart: true),
                  ),
                  const SizedBox(height: 10),
                  _DateTimeTile(
                    label: 'Đến ngày',
                    value: _formatDate(_campaignEndDate),
                    onTap: () => _pickCampaignDate(isStart: false),
                  ),
                  const SizedBox(height: 12),
                  _buildSameDayHint(),
                  const SizedBox(height: 20),
                  _buildRepeatDaysSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Khung giờ trong ngày'),
                  _buildTimeSlotsSection(),
                  const SizedBox(height: 20),
                  _buildProductModeSection(),
                  if (!_applyAllProducts) ...[
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: _productSelectionRevision,
                      builder: (context, _, __) =>
                          _buildSelectedProductsTable(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildQuantityRulesSection(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveFlashSale,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving
                            ? 'Đang lưu...'
                            : (_editingSaleId != null
                                ? 'Cập nhật Flash Sale'
                                : 'Lưu Flash Sale'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildSidePanel({required bool expandProductList}) {
    final productSection = _buildProductSection(
      expandProductList: expandProductList,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expandProductList)
          Expanded(child: productSection)
        else
          productSection,
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flash Sale đang chạy / đã lên lịch',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: _buildActiveSalesList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection({required bool expandProductList}) {
    if (!_applyAllProducts) {
      return ValueListenableBuilder<int>(
        valueListenable: _productSelectionRevision,
        builder: (context, _, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn sản phẩm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedProductIds.length} đã chọn',
                      style: const TextStyle(color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildProductPickerList()),
            ],
          );
        },
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Flash Sale sẽ áp dụng cho toàn bộ sản phẩm đang bán.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPickerList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('Chưa có sản phẩm'));
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final selected = _selectedProductIds.contains(product.id);
            return CheckboxListTile(
              value: selected,
              title: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${product.finalPrice.toStringAsFixed(0)}đ • ${product.category}',
              ),
              onChanged: (checked) {
                _syncProductSelection(product, checked == true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActiveSalesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.flashSalesCollection)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Chưa có Flash Sale'));
        }

        final sales = docs.map((d) => FlashSale.fromFirestore(d)).toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

        return ListView.separated(
          itemCount: sales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sale = sales[index];
            final isRunning = sale.isActive;
            final isEnded = sale.isScheduleEnded;
            final productLabel = sale.isAllProduct
                ? 'Tất cả SP'
                : sale.productItems.isNotEmpty
                    ? '${sale.productItems.length} SP'
                    : '${sale.productIds.length} SP';

            return Card(
              color: _editingSaleId == sale.id
                  ? AdminTheme.accent.withValues(alpha: 0.08)
                  : null,
              child: ListTile(
                dense: true,
                onTap: () => _loadSaleForEdit(sale),
                title: Text(
                  sale.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${sale.discountPercent.toStringAsFixed(0)}% • $productLabel • ${sale.formatRepeatWeekdays()}\n'
                  '${_formatTimeSlotSummary(sale)}'
                  '${sale.note.isNotEmpty ? '\n📝 ${sale.note}' : ''}',
                ),
                trailing: isEnded
                    ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'Kết thúc',
                          style: TextStyle(
                            color: Color(0xFF98A2B3),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Kết thúc sớm',
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.red,
                        ),
                        onPressed: () => _endFlashSale(sale.id, sale.name),
                      ),
                leading: Icon(
                  isRunning ? Icons.flash_on : Icons.schedule,
                  color: isRunning ? AdminTheme.accent : Colors.grey,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeSlotCard extends StatefulWidget {
  const _TimeSlotCard({
    required this.index,
    required this.slot,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onLabelChanged,
    required this.onRemove,
  });

  final int index;
  final FlashSaleTimeSlot slot;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onRemove;

  @override
  State<_TimeSlotCard> createState() => _TimeSlotCardState();
}

class _TimeSlotCardState extends State<_TimeSlotCard> {
  late final TextEditingController _labelController;
  late final FocusNode _labelFocus;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.slot.label);
    _labelFocus = FocusNode();
    _labelFocus.addListener(_syncLabel);
  }

  void _syncLabel() {
    if (!_labelFocus.hasFocus) {
      widget.onLabelChanged(_labelController.text.trim());
    }
  }

  @override
  void didUpdateWidget(covariant _TimeSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.label != widget.slot.label &&
        _labelController.text != widget.slot.label) {
      _labelController.text = widget.slot.label;
    }
  }

  @override
  void dispose() {
    _labelFocus.removeListener(_syncLabel);
    _labelFocus.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFAFAFA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _labelController,
                  focusNode: _labelFocus,
                  decoration: const InputDecoration(
                    labelText: 'Tên khung',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onEditingComplete: () =>
                      widget.onLabelChanged(_labelController.text.trim()),
                  onFieldSubmitted: widget.onLabelChanged,
                ),
              ),
              IconButton(
                tooltip: 'Xóa khung',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTimeTile(
                  label: 'Bắt đầu',
                  value: widget.slot.formatStart(),
                  onTap: widget.onPickStart,
                  isTime: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeTile(
                  label: 'Kết thúc',
                  value: widget.slot.formatEnd(),
                  onTap: widget.onPickEnd,
                  isTime: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotTimePickerDialog extends StatefulWidget {
  const _SlotTimePickerDialog({required this.initial});

  final TimeOfDay initial;

  @override
  State<_SlotTimePickerDialog> createState() => _SlotTimePickerDialogState();
}

class _SlotTimePickerDialogState extends State<_SlotTimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn giờ (24h)'),
      content: SizedBox(
        width: 280,
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _hour,
                decoration: const InputDecoration(
                  labelText: 'Giờ',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  24,
                  (h) => DropdownMenuItem(value: h, child: Text(_two(h))),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _hour = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _minute,
                decoration: const InputDecoration(
                  labelText: 'Phút',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  60,
                  (m) => DropdownMenuItem(value: m, child: Text(_two(m))),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _minute = value);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TimeOfDay(hour: _hour, minute: _minute),
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.isTime = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isTime;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            isTime ? Icons.access_time : Icons.calendar_month,
          ),
        ),
        child: Text(value),
      ),
    );
  }
}

class _SelectedProductsTable extends StatefulWidget {
  const _SelectedProductsTable({
    super.key,
    required this.productIds,
    required this.items,
    required this.meta,
    required this.onItemChanged,
  });

  final List<String> productIds;
  final Map<String, FlashSaleProductItem> items;
  final Map<String, ({String name, double price})> meta;
  final void Function(String productId, FlashSaleProductItem item) onItemChanged;

  @override
  State<_SelectedProductsTable> createState() => _SelectedProductsTableState();
}

class _SelectedProductsTableState extends State<_SelectedProductsTable> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _limitControllers = {};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _SelectedProductsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final ids = widget.productIds.toSet();

    for (final id in ids) {
      final item = widget.items[id];
      _priceControllers.putIfAbsent(
        id,
        () => TextEditingController(
          text: item?.flashSalePrice.toStringAsFixed(0) ?? '',
        ),
      );
      _qtyControllers.putIfAbsent(
        id,
        () => TextEditingController(text: '${item?.quantityPerDay ?? 100}'),
      );
      _limitControllers.putIfAbsent(
        id,
        () => TextEditingController(text: '${item?.limitPerCustomer ?? 2}'),
      );
    }

    for (final id in _priceControllers.keys.toList()) {
      if (!ids.contains(id)) {
        _priceControllers.remove(id)?.dispose();
        _qtyControllers.remove(id)?.dispose();
        _limitControllers.remove(id)?.dispose();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emitItem(String productId) {
    final base = widget.items[productId];
    if (base == null) return;

    final price = double.tryParse(_priceControllers[productId]?.text ?? '');
    final qty = int.tryParse(_qtyControllers[productId]?.text ?? '');
    final limit = int.tryParse(_limitControllers[productId]?.text ?? '');

    widget.onItemChanged(
      productId,
      base.copyWith(
        flashSalePrice: price ?? base.flashSalePrice,
        quantityPerDay: qty ?? base.quantityPerDay,
        limitPerCustomer: limit ?? base.limitPerCustomer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AdminTheme.accent.withValues(alpha: 0.08),
        ),
        columns: const [
          DataColumn(label: Text('Sản phẩm')),
          DataColumn(label: Text('Giá gốc')),
          DataColumn(label: Text('Giá Flash Sale')),
          DataColumn(label: Text('SL/ngày')),
          DataColumn(label: Text('Giới hạn/KH')),
        ],
        rows: widget.productIds.map((productId) {
          final meta = widget.meta[productId];
          final name = meta?.name ?? productId;
          final original = meta?.price ?? 0;
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 140,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text('${currency.format(original)}đ')),
              DataCell(
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _priceControllers[productId],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 'đ',
                    ),
                    onChanged: (_) => _emitItem(productId),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _qtyControllers[productId],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (_) => _emitItem(productId),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _limitControllers[productId],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (_) => _emitItem(productId),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
