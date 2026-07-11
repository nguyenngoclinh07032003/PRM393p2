# Hướng dẫn Test Smart Shop App

## 🚀 Chạy ứng dụng

```bash
flutter run -d chrome --web-port=8080
```

App sẽ chạy tại: http://localhost:8080

---

## 📝 Các bước test cơ bản

### 1. Đăng ký tài khoản mới
1. Mở app
2. Click "Đăng ký"
3. Nhập thông tin:
   - Email: test@example.com
   - Password: 123456
   - Họ tên: Test User
   - Số điện thoại: 0123456789
4. Click "Đăng ký"

### 2. Tạo dữ liệu mẫu (Admin)
1. Đăng nhập vào app
2. Vào menu → Admin Dashboard
3. Click "Thêm 6 sản phẩm ngay" ở góc dưới bên phải
4. Đợi một chút để Firebase tạo dữ liệu
5. Refresh trang để thấy sản phẩm mới

**Hoặc tạo đầy đủ:**
- Vào Admin Dashboard → Menu → Seed Data
- Click "Tạo dữ liệu mẫu đầy đủ"
- Sẽ tạo: sản phẩm, Flash Sales, Group Buys

---

## 🛍️ Test chức năng Customer

### Test 1: Mua hàng cơ bản
1. ✅ Đăng nhập với tài khoản customer
2. ✅ Trang chủ → Click "Tất cả sản phẩm"
3. ✅ Chọn một sản phẩm → Xem chi tiết
4. ✅ Click "Thêm vào giỏ"
5. ✅ Vào giỏ hàng (icon giỏ hàng ở AppBar)
6. ✅ Điều chỉnh số lượng (+/-)
7. ✅ Click "Thanh toán"
8. ✅ Điền thông tin:
   - Họ tên: Nguyễn Văn A
   - SĐT: 0987654321
   - Địa chỉ: 123 Đường ABC, TP.HCM
9. ✅ Chọn phương thức thanh toán
10. ✅ Click "Đặt hàng"
11. ✅ Xem màn hình thành công

**Kiểm tra:**
- ✅ Vào Firebase Console → Firestore
- ✅ Xem collection `orders` → có order mới
- ✅ Xem collection `order_items` → có items
- ✅ ⭐ Xem collection `rebuy_stats` → có record mới với `buyCount: 1`

### Test 2: Mua lại sản phẩm (Rebuy)
**Yêu cầu:** Đã mua hàng ít nhất 1 lần (Test 1)

1. ✅ Trang chủ → Click card "Mua lại sản phẩm"
2. ✅ Xem danh sách sản phẩm đã mua
3. ✅ Mỗi sản phẩm hiển thị:
   - Số lần đã mua (ví dụ: "Đã mua 1 lần")
   - Thời gian mua gần nhất
4. ✅ Mua lại cùng sản phẩm đó 1 lần nữa
5. ✅ Quay lại màn hình Mua lại
6. ✅ Số lần mua tăng lên (ví dụ: "Đã mua 2 lần")

**Kiểm tra Firestore:**
```
Collection: rebuy_stats
Document ID: (auto)
Fields:
  - userId: "abc123"
  - productId: "product_xyz"
  - buyCount: 2  ← Tăng lên
  - lastBuyAt: (timestamp mới nhất)
  - averageDays: 0 hoặc số ngày TB giữa các lần mua
```

### Test 3: Flash Sale (Khung giờ vàng)
**Yêu cầu:** Đã tạo Flash Sale (qua Seed Data)

1. ✅ Trang chủ → Click card "Săn Sale"
2. ✅ Xem danh sách Flash Sales đang diễn ra
3. ✅ Kiểm tra:
   - Countdown timer đếm ngược
   - % giảm giá hiển thị
   - Danh sách sản phẩm áp dụng
4. ✅ Click vào một sản phẩm Flash Sale
5. ✅ Xem chi tiết sản phẩm:
   - ⭐ Banner Flash Sale màu đỏ ở đầu
   - ⭐ Giá gốc gạch ngang
   - ⭐ Giá Flash Sale màu đỏ to
   - Badge "FLASH SALE -X%"
6. ✅ Thêm vào giỏ hàng
7. ✅ Vào giỏ hàng → giá hiển thị là giá Flash Sale
8. ✅ Thanh toán → order lưu với giá Flash Sale

**Test thủ công - Tạo Flash Sale:**
1. Admin Dashboard → Firestore Console
2. Collection `flash_sales` → Add document:
```json
{
  "name": "Flash Sale 12h",
  "discountPercent": 30,
  "isAllProduct": false,
  "productIds": ["product_id_1", "product_id_2"],
  "startTime": (timestamp - giờ hiện tại),
  "endTime": (timestamp + 2 giờ),
  "status": "active"
}
```

### Test 4: Mua nhóm (Group Buy)
**Yêu cầu:** Đã tạo Group Buy (qua Seed Data)

1. ✅ Trang chủ → Click card "Mua nhóm"
2. ✅ Xem danh sách chương trình mua nhóm
3. ✅ Kiểm tra:
   - Countdown timer
   - Số người đã tham gia
   - Giá hiện tại theo mức
4. ✅ Click "Xem chi tiết"
5. ✅ Xem bảng giá động:
   - < 50 người: Giá cao nhất
   - 50-99 người: Giá trung bình  
   - ≥ 100 người: Giá thấp nhất
6. ✅ Click "Tham gia mua nhóm"
7. ✅ Số người tham gia tăng lên

**Kiểm tra Firestore:**
```
Collection: group_buys
Document ID: (ID của group buy)
Field: currentBuyerCount
→ Tăng lên sau khi tham gia
```

**Test thủ công - Tạo Group Buy:**
```json
{
  "productId": "product_xyz",
  "currentBuyerCount": 10,
  "priceUnder50": 200000,
  "priceFrom50": 170000,
  "priceFrom100": 150000,
  "startTime": (timestamp hiện tại),
  "endTime": (timestamp + 1 ngày),
  "status": "active"
}
```

### Test 5: Lịch sử đơn hàng
1. ✅ Trang chủ → Menu (icon 3 gạch) → "Đơn hàng của tôi"
2. ✅ Xem danh sách đơn hàng
3. ✅ Click vào một đơn hàng
4. ✅ Xem chi tiết:
   - Thông tin giao hàng
   - Danh sách sản phẩm
   - Tổng tiền
   - Trạng thái đơn hàng

---

## 👨‍💼 Test chức năng Admin

### Test 6: Quản lý sản phẩm
1. ✅ Menu → Admin Dashboard
2. ✅ Xem thống kê:
   - Tổng doanh thu
   - Số đơn hàng
   - Số sản phẩm
   - Số người dùng
3. ✅ Menu → Quản lý sản phẩm
4. ✅ Click "Thêm sản phẩm mới"
5. ✅ Nhập thông tin:
   - Tên: Sản phẩm Test
   - Mô tả: Mô tả test
   - Giá: 100000
   - Giảm giá: 10 (%)
   - Số lượng: 50
   - Danh mục: Chọn một danh mục
6. ✅ Click "Thêm sản phẩm"
7. ✅ Kiểm tra sản phẩm mới trong danh sách
8. ✅ Click "Sửa" → Thay đổi thông tin → Lưu
9. ✅ Click "Xóa" → Xác nhận xóa

### Test 7: Quản lý đơn hàng
1. ✅ Menu → Quản lý đơn hàng
2. ✅ Xem danh sách đơn hàng
3. ✅ Click "Chi tiết" một đơn hàng
4. ✅ Thay đổi trạng thái:
   - Pending → Processing → Shipping → Delivered
5. ✅ Kiểm tra thay đổi realtime trong Firestore

### Test 8: Quản lý người dùng
1. ✅ Menu → Quản lý người dùng
2. ✅ Xem danh sách users
3. ✅ Thay đổi role:
   - Customer → Admin
   - Admin → Customer
4. ✅ Kiểm tra thay đổi trong Firestore

---

## 🔍 Kiểm tra Firebase Console

### Collections cần có:
1. ✅ `users` - Danh sách người dùng
2. ✅ `products` - Sản phẩm
3. ✅ `carts` - Giỏ hàng
4. ✅ `orders` - Đơn hàng
5. ✅ `order_items` - Chi tiết đơn hàng
6. ✅ ⭐ `rebuy_stats` - Thống kê mua lại (auto tạo sau order)
7. ✅ `group_buys` - Mua nhóm
8. ✅ `flash_sales` - Flash Sale

### Kiểm tra Structure:

**rebuy_stats example:**
```
{
  "userId": "abc123",
  "productId": "prod_xyz",
  "buyCount": 2,
  "lastBuyAt": Timestamp,
  "averageDays": 15
}
```

**orders example:**
```
{
  "userId": "abc123",
  "sellerId": "seller123",
  "totalPrice": 150000,
  "status": "pending",
  "paymentStatus": "unpaid",
  "paymentMethod": "cod",
  "deliveryInfo": {
    "name": "Nguyễn Văn A",
    "phone": "0987654321",
    "address": "123 ABC, TP.HCM"
  },
  "createdAt": Timestamp
}
```

---

## ✅ Checklist đầy đủ

### Customer Features:
- [ ] Đăng ký tài khoản
- [ ] Đăng nhập
- [ ] Xem danh sách sản phẩm
- [ ] Tìm kiếm sản phẩm
- [ ] Xem chi tiết sản phẩm
- [ ] Thêm vào giỏ hàng
- [ ] Xem giỏ hàng
- [ ] Điều chỉnh số lượng trong giỏ
- [ ] Xóa sản phẩm khỏi giỏ
- [ ] Thanh toán (checkout)
- [ ] Xem lịch sử đơn hàng
- [ ] Xem chi tiết đơn hàng
- [ ] ⭐ Mua lại sản phẩm (Rebuy)
- [ ] ⭐ Xem sản phẩm Flash Sale
- [ ] ⭐ Mua sản phẩm với giá Flash Sale
- [ ] ⭐ Tham gia mua nhóm (Group Buy)
- [ ] ⭐ Rebuy stats tự động cập nhật sau order

### Admin Features:
- [ ] Xem Dashboard
- [ ] Xem thống kê realtime
- [ ] Thêm sản phẩm
- [ ] Sửa sản phẩm
- [ ] Xóa sản phẩm
- [ ] Xem danh sách người dùng
- [ ] Thay đổi role người dùng
- [ ] Xem danh sách đơn hàng
- [ ] Cập nhật trạng thái đơn hàng
- [ ] Tạo dữ liệu mẫu (seed data)

### Backend:
- [ ] Firebase Authentication hoạt động
- [ ] Firestore đọc/ghi dữ liệu
- [ ] ⭐ RebuyService auto update sau order
- [ ] ⭐ FlashSaleService tính giá đúng
- [ ] ⭐ GroupBuyService tính giá động
- [ ] Realtime updates hoạt động

---

## 🐛 Troubleshooting

### Lỗi: "User not found"
→ Đăng ký tài khoản mới

### Lỗi: "No products found"
→ Chạy seed data để tạo sản phẩm mẫu

### Lỗi Firebase: "Permission denied"
→ Kiểm tra Firestore Rules (đã set test mode chưa)

### Flash Sale không hiển thị giá giảm
→ Kiểm tra:
1. Flash Sale có status = "active"
2. startTime <= hiện tại <= endTime
3. productIds có chứa product ID

### Rebuy stats không tạo
→ Kiểm tra:
1. Đã đặt hàng thành công chưa?
2. Xem Firebase Console → rebuy_stats collection
3. Xem logs trong Flutter console

---

## 📱 Screenshots nên chụp khi test

1. Trang chủ với 3 feature cards
2. Danh sách sản phẩm
3. Chi tiết sản phẩm với Flash Sale banner
4. Giỏ hàng với sản phẩm
5. Màn hình thanh toán
6. Màn hình Mua lại sản phẩm
7. Màn hình Flash Sale với countdown
8. Màn hình Group Buy với giá động
9. Admin Dashboard
10. Firebase Console với rebuy_stats

---

## 🎉 Hoàn thành!

Sau khi test hết checklist trên, dự án đã hoạt động đầy đủ chức năng theo yêu cầu!
