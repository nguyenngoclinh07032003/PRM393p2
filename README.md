# Smart Shop App

Ứng dụng thương mại điện tử thông minh với Firebase Backend

## 🎯 Giới thiệu

**Smart Shop App** là ứng dụng bán hàng trực tuyến được xây dựng trên nền tảng **Firebase**, cho phép khách hàng mua sắm, săn khuyến mãi và tham gia các chương trình mua hàng thông minh.

## ✨ Tính năng chính

### Cho Khách hàng (Customer):
- 🛒 **Mua hàng trực tuyến** - Duyệt và mua sản phẩm
- 🔄 **Mua lại thông minh** - Gợi ý sản phẩm đã mua để mua lại
- 👥 **Mua theo nhóm** - Giá giảm theo số người tham gia
- ⚡ **Flash Sale** - Khuyến mãi theo khung giờ vàng
- 📊 **Phân tích tần suất mua** - Dự đoán nhu cầu mua lại
- 📜 **Lịch sử đơn hàng** - Theo dõi đơn hàng realtime

### Cho Người bán (Seller):
- 📦 **Quản lý sản phẩm** - Thêm, sửa, xóa sản phẩm
- 💰 **Cấu hình giảm giá** - Thiết lập khuyến mãi
- ⏰ **Cấu hình Flash Sale** - Khung giờ vàng
- 📈 **Quản lý đơn hàng** - Theo dõi và xử lý đơn
- 💵 **Báo cáo doanh thu** - Thống kê bán hàng

### Cho Admin:
- 👥 **Quản lý người dùng** - Quản lý tài khoản
- 🔥 **Quản lý khuyến mãi** - Giám sát các chương trình
- 📊 **Dashboard realtime** - Theo dõi hệ thống
- 📉 **Báo cáo thống kê** - Phân tích dữ liệu

## 🏗️ Kiến trúc

```
lib/
├── backend/
│   ├── config/
│   │   └── app_constants.dart
│   ├── models/
│   │   ├── cart_item.dart
│   │   ├── medicine.dart
│   │   ├── order.dart
│   │   ├── order_full.dart
│   │   ├── pharmacy.dart
│   │   ├── prescription.dart
│   │   └── symptom.dart
│   └── services/
│       ├── auth_service.dart
│       ├── cart_service.dart
│       ├── error_handler.dart
│       ├── firestore_service.dart
│       └── local_storage_service.dart
├── frontend/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── user/
│       └── home/
│           └── home_screen.dart
├── firebase_options.dart
└── main.dart
```

## Cài đặt Firebase

### Bước 1: Cài đặt Flutter dependencies

```bash
flutter pub get
```

### Bước 2: Cài đặt Firebase CLI

```bash
npm install -g firebase-tools
```

### Bước 3: Đăng nhập Firebase

```bash
firebase login
```

### Bước 4: Cấu hình Firebase cho Flutter

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Cấu hình Firebase
flutterfire configure --project=prm393-9f30f
```

Lệnh này sẽ tự động:
- Tạo file `firebase_options.dart` với cấu hình đúng
- Thêm `google-services.json` cho Android
- Cấu hình iOS (nếu cần)

### Bước 5: Tải file google-services.json

1. Vào Firebase Console: https://console.firebase.google.com/u/0/project/prm393-9f30f
2. Chọn Project Settings > General
3. Scroll xuống "Your apps"
4. Nếu chưa có Android app, click "Add app" và chọn Android
5. Nhập package name: `com.example.prm393_pharmacy`
6. Tải file `google-services.json`
7. Copy file vào: `android/app/google-services.json`

### Bước 6: Cấu hình Firestore Rules

Vào Firebase Console > Firestore Database > Rules và thêm:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    match /medicines/{medicineId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'pharmacy';
    }
    
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'shipper']);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'shipper', 'pharmacy'];
    }
    
    match /cart/{cartId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Chạy ứng dụng

```bash
flutter run
```

## Tính năng

✅ Authentication (Đăng nhập/Đăng ký)
✅ Firestore Database
✅ Models: Medicine, Order, Prescription, Pharmacy, Cart
✅ Services: Auth, Cart, Firestore, Local Storage
✅ Error Handling

## Next Steps

- Thêm UI cho các màn hình còn lại
- Implement CRUD operations cho medicines
- Thêm tính năng đặt hàng
- Thêm role-based access (Admin, Pharmacy, Shipper, User)
