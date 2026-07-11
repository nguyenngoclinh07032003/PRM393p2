# 🛡️ Admin Dashboard - Hướng dẫn sử dụng

## ✅ Đã có Admin Dashboard!

Smart Shop App bây giờ đã có đầy đủ Admin panel với các chức năng quản trị.

---

## 🚀 Truy cập Admin Dashboard

### Cách 1: Từ Home Screen
1. Đăng nhập vào app
2. Ở màn hình Home, click card **"Admin"** (màu tím)
3. Vào Admin Dashboard

### Cách 2: URL trực tiếp (sau khi implement routing)
```
http://localhost:8080/admin
```

---

## 📊 Chức năng Admin Dashboard

### 1. **Thống kê tổng quan**
- 📊 Số người dùng
- 📦 Số sản phẩm  
- 🛒 Số đơn hàng
- Real-time updates từ Firebase

### 2. **Quản lý sản phẩm** ✅
- ✅ Xem danh sách tất cả sản phẩm
- ✅ Thêm sản phẩm mới
- ✅ Sửa sản phẩm
- ✅ Xóa/Vô hiệu hóa sản phẩm
- ✅ Xem trạng thái kho

**Các trường khi thêm sản phẩm:**
- Tên sản phẩm *
- Mô tả *
- Giá gốc (VNĐ) *
- Giá khuyến mãi (tùy chọn)
- Số lượng kho *
- Danh mục *
- URL hình ảnh

### 3. **Quản lý người dùng** ✅
- ✅ Xem danh sách người dùng
- ✅ Xem thông tin: Tên, Email, SĐT, Vai trò
- ✅ Thay đổi vai trò user:
  - Customer (Khách hàng)
  - Seller (Người bán)
  - Admin (Quản trị viên)
- ✅ Vô hiệu hóa tài khoản

### 4. **Quản lý đơn hàng** ✅
- ✅ Xem tất cả đơn hàng real-time
- ✅ Chi tiết đơn hàng: ID, User, Seller, Tổng tiền
- ✅ Cập nhật trạng thái đơn hàng:
  - ⏳ Chờ xử lý (Pending)
  - ✅ Đã xác nhận (Confirmed)
  - 🚚 Đang giao (Shipping)
  - 📦 Đã giao (Delivered)
  - ❌ Đã hủy (Cancelled)

### 5. **Flash Sales** 🔄
- Đang phát triển
- Tạo Flash Sale với % giảm giá
- Chọn sản phẩm áp dụng
- Đặt thời gian bắt đầu/kết thúc

### 6. **Group Buys** 🔄
- Đang phát triển
- Tạo chương trình mua nhóm
- Cấu hình giá theo số lượng người mua

### 7. **Báo cáo** 🔄
- Đang phát triển
- Doanh thu theo ngày/tháng
- Top sản phẩm bán chạy
- Thống kê người dùng

---

## 🎨 Giao diện Admin

### Dashboard Main
```
┌─────────────────────────────────────┐
│       Admin Dashboard               │
├─────────────────────────────────────┤
│  Thống kê hệ thống                  │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │Users │ │Items │ │Orders│        │
│  │  10  │ │  25  │ │   5  │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  Quản lý                            │
│  ┌────────┐ ┌────────┐             │
│  │Products│ │  Users │             │
│  └────────┘ └────────┘             │
│  ┌────────┐ ┌────────┐             │
│  │ Orders │ │  Flash │             │
│  └────────┘ └────────┘             │
└─────────────────────────────────────┘
```

---

## 👤 Phân quyền

### Customer (Khách hàng)
- Xem sản phẩm
- Mua hàng
- Xem đơn hàng của mình

### Seller (Người bán)
- Quản lý sản phẩm của mình
- Xem đơn hàng liên quan
- Cập nhật trạng thái đơn hàng

### Admin (Quản trị viên)
- ✅ Tất cả quyền của Customer và Seller
- ✅ Quản lý tất cả sản phẩm
- ✅ Quản lý người dùng
- ✅ Quản lý tất cả đơn hàng
- ✅ Tạo Flash Sales
- ✅ Tạo Group Buys
- ✅ Xem báo cáo tổng quan

---

## 🔧 Cách đặt user làm Admin

### Cách 1: Thông qua Firebase Console
1. Vào: https://console.firebase.google.com/u/0/project/prm393-9f30f/firestore/data
2. Chọn collection `users`
3. Tìm user cần đặt làm admin
4. Click vào document
5. Sửa field `role` từ `customer` → `admin`
6. Save

### Cách 2: Thông qua Admin Dashboard
1. Đăng nhập với tài khoản Admin hiện tại
2. Vào **Admin Dashboard** → **Quản lý người dùng**
3. Click 3 chấm ở user muốn đặt làm admin
4. Chọn **"Đặt làm Admin"**

---

## 📱 Screenshots chức năng

### 1. Admin Dashboard Home
- Thống kê real-time
- Cards management

### 2. Quản lý sản phẩm
- Grid view sản phẩm
- Button thêm mới
- Actions: Edit, Delete

### 3. Quản lý người dùng
- List view users
- Role badges (màu)
- Dropdown actions

### 4. Quản lý đơn hàng
- Timeline view orders
- Status colors
- Action buttons

---

## 🚀 Next Steps - Phát triển thêm

- [ ] Thêm search/filter trong mỗi màn hình
- [ ] Export báo cáo ra Excel/PDF
- [ ] Dashboard charts (biểu đồ)
- [ ] Notification system
- [ ] Email notifications
- [ ] Activity logs
- [ ] Backup/Restore data

---

## 📞 Firebase Collections sử dụng

Admin Dashboard tương tác với:
- `users` - Quản lý người dùng
- `products` - Quản lý sản phẩm
- `orders` - Quản lý đơn hàng
- `flash_sales` - Flash Sales
- `group_buys` - Group Buys
- `rebuy_stats` - Thống kê mua lại

---

**✨ Admin Dashboard đã sẵn sàng sử dụng!**

Test ngay bằng cách click card "Admin" trên Home Screen! 🎯
