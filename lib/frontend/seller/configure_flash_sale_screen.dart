import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../backend/config/app_constants.dart';

class ConfigureFlashSaleScreen extends StatefulWidget {
  const ConfigureFlashSaleScreen({super.key});

  @override
  State<ConfigureFlashSaleScreen> createState() => _ConfigureFlashSaleScreenState();
}

class _ConfigureFlashSaleScreenState extends State<ConfigureFlashSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Flash Sale');
  final _discountController = TextEditingController(text: '20');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection(AppConstants.flashSalesCollection).add({
        'name': _nameController.text.trim(),
        'productIds': <String>[],
        'isAllProduct': true,
        'discountPercent': double.parse(_discountController.text.trim()),
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(now.add(const Duration(hours: 6))),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kích hoạt flash sale'), backgroundColor: Colors.green),
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
        title: const Text('Cấu hình Flash Sale'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên chương trình', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mức giảm (%)', border: OutlineInputBorder()),
              validator: (value) {
                final discount = double.tryParse(value ?? '');
                if (discount == null || discount <= 0 || discount >= 100) {
                  return 'Mức giảm phải nằm trong khoảng 1-99';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.flash_on),
              label: Text(_isSaving ? 'Đang lưu...' : 'Kích hoạt Flash Sale'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
