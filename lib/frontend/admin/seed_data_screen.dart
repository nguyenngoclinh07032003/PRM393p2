import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import '../../backend/services/auth_service.dart';
import '../../utils/seed_data.dart';
import 'admin_navigation.dart';
import 'admin_theme.dart';

class SeedDataScreen extends StatelessWidget {
  const SeedDataScreen({super.key});

  @override
  Widget build(BuildContext context) => const SeedDataBody();
}

class SeedDataBody extends StatefulWidget {
  const SeedDataBody({super.key});

  @override
  State<SeedDataBody> createState() => _SeedDataBodyState();
}

class _SeedDataBodyState extends State<SeedDataBody> {
  bool _isLoading = false;

  Future<void> _seedData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SeedData.seedAll(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo dữ liệu mẫu thành công'),
            backgroundColor: Colors.green,
          ),
        );
        AdminNavigation.navigate(context, AppRoutes.admin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Tạo Dữ Liệu Mẫu',
      subtitle: 'Khởi tạo sản phẩm, Flash Sale và Group Buy demo',
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: AdminTheme.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 72,
              color: AdminTheme.accent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nội dung sẽ được tạo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• 24 sản phẩm mẫu\n'
              '• 1 Flash Sale\n'
              '• 1 Group Buy',
              style: TextStyle(
                fontSize: 14,
                color: AdminTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 280,
              child: AdminPrimaryButton(
                label: 'Tạo dữ liệu mẫu',
                icon: Icons.play_arrow_rounded,
                onPressed: _isLoading ? () {} : _seedData,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Chỉ chạy một lần để tránh trùng lặp dữ liệu',
              style: TextStyle(
                color: Color(0xFFF79009),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
