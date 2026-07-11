# Hướng dẫn kết nối Firebase cho PRM393 Pharmacy

## 📋 Yêu cầu trước khi bắt đầu

- Flutter SDK đã cài đặt
- Android Studio hoặc VS Code
- Node.js và npm đã cài đặt
- Tài khoản Firebase (đã có: prm393-9f30f)

## 🚀 Các bước cài đặt

### 1. Cài đặt Firebase CLI

Mở terminal và chạy:

```bash
npm install -g firebase-tools
```

Đăng nhập vào Firebase:

```bash
firebase login
```

### 2. Cài đặt FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Đảm bảo PATH đã được cấu hình để chạy được `flutterfire`:

```bash
# Windows
# Thêm vào PATH: %USERPROFILE%\AppData\Local\Pub\Cache\bin

# Mac/Linux
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### 3. Cấu hình Firebase cho dự án

Trong thư mục dự án, chạy:

```bash
flutterfire configure --project=prm393-9f30f
```

Lệnh này sẽ:
- Tạo file `lib/firebase_options.dart` tự động
- Cấu hình Android và iOS
- Tải và đặt `google-services.json` vào đúng vị trí

### 4. Cài đặt dependencies

```bash
flutter pub get
```

### 5. Kiểm tra file google-services.json

Đảm bảo file `android/app/google-services.json` tồn tại.

Nếu không có, tải thủ công:
1. Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/settings/general
2. Chọn Android app
3. Download `google-services.json`
4. Copy vào `android/app/`

### 6. Cấu hình Firestore Database

1. Vào Firebase Console: https://console.firebase.google.com/u/0/project/prm393-9f30f/firestore
2. Nếu chưa có database, click "Create database"
3. Chọn "Start in test mode" (có thể thay đổi rules sau)
4. Chọn location gần nhất (asia-southeast1)

### 7. Cấu hình Authentication

1. Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/authentication
2. Click "Get started"
3. Enable "Email/Password" sign-in method

### 8. Chạy ứng dụng

```bash
flutter run
```

## 🔐 Cấu hình Firestore Security Rules

Vào Firestore > Rules và thay thế bằng:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check user role
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      (request.auth.uid == userId || getUserRole() == 'admin');
    }
    
    // Medicines collection
    match /medicines/{medicineId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
                                       getUserRole() in ['pharmacy', 'admin'];
    }
    
    // Pharmacies collection
    match /pharmacies/{pharmacyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && getUserRole() in ['pharmacy', 'admin'];
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      getUserRole() in ['admin', 'shipper', 'pharmacy']);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       getUserRole() in ['admin', 'shipper', 'pharmacy'];
      allow delete: if request.auth != null && getUserRole() == 'admin';
    }
    
    // Cart collection
    match /cart/{cartId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    
    // Prescriptions collection
    match /prescriptions/{prescriptionId} {
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      getUserRole() in ['admin', 'pharmacy']);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       getUserRole() in ['admin', 'pharmacy'];
    }
    
    // Symptoms collection
    match /symptoms/{symptomId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && getUserRole() in ['admin', 'pharmacy'];
    }
  }
}
```

## 🧪 Test kết nối

### Tạo tài khoản test

1. Chạy app: `flutter run`
2. Click "Đăng ký ngay"
3. Nhập thông tin:
   - Họ tên: Test User
   - Email: test@example.com
   - Số điện thoại: 0123456789
   - Mật khẩu: 123456

### Kiểm tra Firestore

1. Vào Firebase Console > Firestore
2. Xem collection `users`
3. Nên thấy document mới được tạo với thông tin user

## 📊 Collections trong Firestore

Dự án sử dụng các collections:

- **users**: Thông tin người dùng (name, email, phone, role)
- **medicines**: Danh sách thuốc
- **pharmacies**: Danh sách nhà thuốc
- **orders**: Đơn hàng
- **cart**: Giỏ hàng
- **prescriptions**: Đơn thuốc
- **symptoms**: Triệu chứng bệnh

## ❗ Troubleshooting

### Lỗi: "google-services.json not found"
- Download lại từ Firebase Console
- Đặt vào `android/app/google-services.json`

### Lỗi: "flutterfire command not found"
- Kiểm tra PATH
- Chạy lại: `dart pub global activate flutterfire_cli`

### Lỗi build Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Lỗi: "Firebase not initialized"
- Kiểm tra `firebase_options.dart` có đúng config
- Đảm bảo `Firebase.initializeApp()` được gọi trong `main()`

## 📞 Liên hệ

Project Firebase: https://console.firebase.google.com/u/0/project/prm393-9f30f
