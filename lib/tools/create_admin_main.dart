import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../utils/admin_account_seed.dart';

/// Chạy: flutter run -t lib/tools/create_admin_main.dart -d chrome
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    final result = await AdminAccountSeed.ensureAdminAccount();
    debugPrint('✅ Admin OK — uid: ${result.uid}');
    debugPrint('Email: ${AdminAccountSeed.adminEmail}');
    debugPrint('Password: ${AdminAccountSeed.adminPassword}');
  } catch (e, stack) {
    debugPrint('❌ Lỗi tạo admin: $e');
    debugPrint('$stack');
  }

  runApp(const _DoneApp());
}

class _DoneApp extends StatelessWidget {
  const _DoneApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tạo Admin')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Tài khoản Admin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Email: admin@smartdealshop.com'),
              Text('Mật khẩu: Admin@123456'),
              SizedBox(height: 16),
              Text(
                'Đăng nhập bằng thông tin trên để vào Admin Dashboard.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
