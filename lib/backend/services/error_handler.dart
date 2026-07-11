import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Email hoặc mật khẩu không đúng. '
              'Hãy kiểm tra lại hoặc đăng ký tài khoản mới.';
        case 'wrong-password':
          return 'Mật khẩu không chính xác.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng. Hãy đăng nhập hoặc dùng email khác.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu từ 6 ký tự trở lên.';
        case 'operation-not-allowed':
          return 'Đăng nhập Email/Password chưa được bật trên Firebase. '
              'Vào Firebase Console → Authentication → Sign-in method.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau vài phút.';
        case 'network-request-failed':
          return 'Không có kết nối mạng. Vui lòng kiểm tra internet.';
        default:
          return 'Đã xảy ra lỗi (${error.code}): ${error.message ?? 'Không xác định'}';
      }
    }
    return 'Đã xảy ra lỗi không xác định: $error';
  }
}
