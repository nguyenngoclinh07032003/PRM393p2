import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import 'admin_navigation.dart';
import 'admin_theme.dart';

class AdminShopSettingsScreen extends StatelessWidget {
  const AdminShopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminShopSettingsBody();
}

class AdminShopSettingsBody extends StatefulWidget {
  const AdminShopSettingsBody({super.key});

  @override
  State<AdminShopSettingsBody> createState() => _AdminShopSettingsBodyState();
}

class _AdminShopSettingsBodyState extends State<AdminShopSettingsBody> {
  int _tab = 0;

  final _shopNameController = TextEditingController(text: 'SmartDeal Shop');
  final _seoController = TextEditingController(
    text: 'Mua sắm điện tử giá tốt - SmartDeal Shop',
  );
  final _facebookController = TextEditingController();
  final _zaloController = TextEditingController();

  @override
  void dispose() {
    _shopNameController.dispose();
    _seoController.dispose();
    _facebookController.dispose();
    _zaloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Logo',
      'Banners',
      'Danh mục',
      'SEO',
      'Nút bấm',
    ];

    return AdminPage(
      title: 'Cài Đặt Shop',
      subtitle: 'Logo, banner, SEO và liên kết mạng xã hội',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tabs.length; i++)
                ChoiceChip(
                  label: Text(tabs[i]),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                  selectedColor: AdminTheme.accent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _tab == i
                        ? AdminTheme.accentDark
                        : AdminTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AdminTheme.cardDecoration,
            child: _buildTabContent(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () =>
                  AdminNavigation.navigate(context, AppRoutes.seedData),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Tạo dữ liệu mẫu (Seed Data)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 1:
        return _uploadSection(
          title: 'Banner cửa hàng',
          hint: 'Tải banner hiển thị trên trang chủ (khuyến nghị 1200×400)',
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gradient danh mục',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF24C7E8), Color(0xFF7A5AF8)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Màu gradient áp dụng cho chip danh mục trên trang chủ.',
              style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            TextField(
              controller: _seoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả SEO',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zaloController,
              decoration: const InputDecoration(
                labelText: 'Zalo / Liên hệ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Màu nút chính', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AdminPrimaryButton(label: 'Xem trước nút', onPressed: () {}),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Tên shop',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _uploadSection(
              title: 'Logo shop',
              hint: 'Tải logo vuông (khuyến nghị 256×256)',
            ),
          ],
        );
    }
  }

  Widget _uploadSection({required String title, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.border),
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: AdminTheme.textSecondary,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
        ),
      ],
    );
  }
}
