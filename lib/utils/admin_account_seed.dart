import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../backend/config/app_constants.dart';

class AdminSeedResult {
  final String uid;
  final bool created;
  final bool profileUpdated;

  const AdminSeedResult({
    required this.uid,
    required this.created,
    required this.profileUpdated,
  });
}

/// Tài khoản admin mẫu cho dự án demo.
class AdminAccountSeed {
  static const String adminEmail = 'admin@smartdealshop.com';
  static const String adminPassword = 'Admin@123456';
  static const String adminName = 'SmartDeal Admin';
  static const String adminPhone = '0900000000';
  static const String adminAddress = '123 Commerce St, Tech City';

  static Future<AdminSeedResult> ensureAdminAccount() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    User? user;
    var created = false;

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      user = credential.user;
      created = true;
      debugPrint('Đã tạo tài khoản admin mới trên Firebase Auth.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final credential = await auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          user = credential.user;
          debugPrint('Tài khoản admin đã tồn tại — cập nhật quyền admin.');
        } on FirebaseAuthException catch (signInError) {
          if (signInError.code == 'invalid-credential' ||
              signInError.code == 'wrong-password' ||
              signInError.code == 'invalid-login-credentials') {
            throw Exception(
              'Email admin đã được đăng ký với mật khẩu khác. '
              'Bấm "Quên mật khẩu?" để đặt lại, hoặc dùng email khác.',
            );
          }
          rethrow;
        }
      } else if (e.code == 'operation-not-allowed') {
        throw Exception(
          'Firebase chưa bật đăng nhập Email/Password. '
          'Vào Firebase Console → Authentication → Sign-in method.',
        );
      } else {
        rethrow;
      }
    }

    if (user == null) {
      throw Exception('Không tạo được tài khoản admin');
    }

    await firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'email': adminEmail,
      'fullName': adminName,
      'phone': adminPhone,
      'address': adminAddress,
      'role': AppConstants.roleAdmin,
      'status': AppConstants.statusActive,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return AdminSeedResult(
      uid: user.uid,
      created: created,
      profileUpdated: true,
    );
  }
}
