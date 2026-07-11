# 🚀 Hướng dẫn Setup Smart Shop App

## ✅ Đã hoàn thành

- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore Database
- ✅ Models: Product, Order, Flash Sale, Group Buy, Rebuy Stats
- ✅ Services: Auth, Product, Cart, Flash Sale, Group Buy, Rebuy
- ✅ UI: Login, Signup, Home, Product List, Product Detail
- ✅ Seed Data Script (tạo dữ liệu mẫu)

---

## 📱 Chạy ứng dụng

### Bước 1: Đảm bảo Firebase đã được cấu hình

1. **Enable Email/Password Authentication**:
   - Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/authentication/providers
   - Click "Email/Password"
   - Bật "Enable"
   - Click "Save"

2. **Tạo Firestore Database**:
   - Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/firestore
   - Click "Create database"
   - Chọn "Start in test mode"
   - Click "Next" → "Enable"

### Bước 2: Chạy app

```bash
cd "C:\Users\nguyengoclinh\Downloads\Project PRM393"
flutter run -d chrome --web-port=8080
```

Hoặc double-click file `run_app.bat`

### Bước 3: Đăng ký tài khoản

1. Mở http://localhost:8080
2. Click "Đăng ký ngay"
3. Nhập thông tin
4. Click "Đăng ký"

### Bước 4: Tạo dữ liệu mẫu

1. Sau khi đăng nhập, ở màn hình Home
2. Click nút **"Tạo dữ liệu mẫu"** (màu trắng trên banner xanh)
3. Click **"Tạo dữ liệu mẫu"**
4. Đợi vài giây
5. ✅ Xong! App sẽ có 8 sản phẩm mẫu

### Bước 5: Xem sản phẩm

1. Click vào card **"Sản phẩm"** ở Home
2. Browse sản phẩm
3. Click vào sản phẩm để xem chi tiết

---

## 🔥 Chức năng đã có

### Customer (Khách hàng)

✅ Đăng ký/Đăng nhập  
✅ Xem danh sách sản phẩm  
✅ Tìm kiếm sản phẩm  
✅ Xem chi tiết sản phẩm  
🔄 Thêm vào giỏ hàng (đang phát triển)  
🔄 Đặt hàng (đang phát triển)  
🔄 Mua lại sản phẩm (đang phát triển)  
🔄 Mua nhóm (đang phát triển)  
🔄 Flash Sale (đang phát triển)  

### Seller (Người bán)

🔄 Quản lý sản phẩm (đang phát triển)  
🔄 Quản lý đơn hàng (đang phát triển)  
🔄 Cấu hình giảm giá (đang phát triển)  

### Admin

✅ Tạo dữ liệu mẫu  
🔄 Quản lý người dùng (đang phát triển)  
🔄 Quản lý hệ thống (đang phát triển)  

---

## 📊 Collections trong Firestore

Sau khi tạo dữ liệu mẫu, bạn sẽ có:

- **users**: Thông tin người dùng
- **products**: 8 sản phẩm công nghệ
- **flash_sales**: 1 Flash Sale mẫu
- **group_buys**: 1 Group Buy mẫu
- **carts**: Giỏ hàng
- **orders**: Đơn hàng
- **order_items**: Chi tiết đơn hàng
- **rebuy_stats**: Thống kê mua lại

---

## 🛠️ Troubleshooting

### Lỗi: "configuration-not-found"

**Giải pháp**: Enable Email/Password trong Firebase Authentication

1. Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/authentication/providers
2. Click "Email/Password"
3. Bật "Enable"

### App không hiển thị

**Giải pháp**: Mở Chrome developer console (F12) để xem lỗi

### Không có sản phẩm

**Giải pháp**: Click nút "Tạo dữ liệu mẫu" ở màn hình Home

---

## 📞 Firebase Console Links

- **Project Overview**: https://console.firebase.google.com/u/0/project/prm393-9f30f
- **Authentication**: https://console.firebase.google.com/u/0/project/prm393-9f30f/authentication/users
- **Firestore**: https://console.firebase.google.com/u/0/project/prm393-9f30f/firestore/data
- **Settings**: https://console.firebase.google.com/u/0/project/prm393-9f30f/settings/general

---

## 🎯 Next Steps

1. ✅ Enable Email/Password Auth → **ĐÃ XỨ LÝ**
2. ✅ Tạo Firestore Database → **CẦN LÀM**
3. ✅ Chạy app
4. ✅ Đăng ký tài khoản
5. ✅ Tạo dữ liệu mẫu
6. ✅ Test các chức năng

---

**🔥 Quan trọng**: Chỉ chạy "Tạo dữ liệu mẫu" **1 lần** để tránh trùng lặp!
