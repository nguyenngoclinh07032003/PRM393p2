# 🛍️ Customer Guide - Hướng dẫn mua hàng

## ✅ Màn hình Customer đã có

Smart Shop App bây giờ đã có đầy đủ màn hình cho Customer!

---

## 📱 Các màn hình Customer

### 1. **Home Screen** ✅
- Welcome banner
- Quick actions
- Feature cards:
  - Sản phẩm
  - Mua lại
  - Mua nhóm
  - Flash Sale
  - Lịch sử
  - Tài khoản
  - Admin (nếu là admin)

### 2. **Product List Screen** ✅
- Xem tất cả sản phẩm dạng grid
- Search sản phẩm
- Hiển thị giá, giảm giá, kho
- Click để xem chi tiết

### 3. **Product Detail Screen** ✅
- Hình ảnh sản phẩm
- Tên, mô tả
- Giá gốc & giá khuyến mãi
- Số lượng kho
- Danh mục
- Nút "Thêm vào giỏ"
- Nút "Mua ngay"

### 4. **Cart Screen** ✅
- Danh sách sản phẩm trong giỏ
- Tăng/giảm số lượng
- Xóa sản phẩm
- Tổng tiền
- Nút "Thanh toán"

### 5. **Checkout Screen** ✅
- Form thông tin giao hàng:
  - Họ tên
  - Số điện thoại
  - Địa chỉ
- Chọn phương thức thanh toán:
  - COD (Thanh toán khi nhận hàng)
  - Chuyển khoản ngân hàng
  - Ví điện tử
- Tóm tắt đơn hàng
- Nút "Đặt hàng"

### 6. **Order Success Screen** ✅
- Thông báo đặt hàng thành công
- Mã đơn hàng
- Nút "Xem đơn hàng"
- Nút "Về trang chủ"

### 7. **Order History Screen** ✅
- Danh sách tất cả đơn hàng
- Trạng thái đơn hàng (màu sắc)
- Tổng tiền
- Click để xem chi tiết

### 8. **Order Detail Screen** ✅
- Thông tin đơn hàng
- Danh sách sản phẩm
- Trạng thái, thanh toán
- Tổng tiền

---

## 🛒 Luồng mua hàng

### Cách 1: Mua từ danh sách sản phẩm
```
Home → Sản phẩm → Product List → Product Detail
→ Thêm vào giỏ → Cart → Checkout → Success
```

### Cách 2: Mua ngay
```
Product Detail → Mua ngay → Checkout → Success
```

---

## 📖 Hướng dẫn chi tiết

### 1. Xem sản phẩm

**Bước 1:** Từ Home Screen, click card "Sản phẩm"

**Bước 2:** Browse danh sách sản phẩm
- Sử dụng search bar để tìm kiếm
- Click vào sản phẩm để xem chi tiết

### 2. Thêm vào giỏ hàng

**Cách 1 - Từ Product Detail:**
1. Click vào sản phẩm
2. Xem thông tin chi tiết
3. Click "Thêm vào giỏ"

**Cách 2 - Mua nhiều:**
1. Thêm nhiều sản phẩm vào giỏ
2. Click icon giỏ hàng ở header
3. Điều chỉnh số lượng nếu cần

### 3. Xem giỏ hàng

**Từ bất kỳ màn hình nào:**
- Click icon 🛒 trên AppBar
- Xem danh sách sản phẩm
- Tăng/giảm số lượng
- Xóa sản phẩm không cần

### 4. Thanh toán

**Bước 1:** Trong Cart Screen, click "Thanh toán"

**Bước 2:** Điền thông tin giao hàng
- Họ và tên *
- Số điện thoại *
- Địa chỉ giao hàng *

**Bước 3:** Chọn phương thức thanh toán
- ✅ COD (Thanh toán khi nhận hàng)
- 💳 Chuyển khoản
- 📱 Ví điện tử

**Bước 4:** Kiểm tra lại thông tin

**Bước 5:** Click "Đặt hàng"

### 5. Xem lịch sử đơn hàng

**Cách 1:** Home → Card "Lịch sử"

**Cách 2:** Từ Order Success → "Xem đơn hàng"

---

## 📊 Trạng thái đơn hàng

| Trạng thái | Màu sắc | Ý nghĩa |
|------------|---------|---------|
| Chờ xử lý | 🟠 Cam | Đơn mới, chờ shop xác nhận |
| Đã xác nhận | 🔵 Xanh | Shop đã xác nhận |
| Đang giao | 🟣 Tím | Shipper đang giao |
| Đã giao | 🟢 Xanh lá | Đã nhận hàng |
| Đã hủy | 🔴 Đỏ | Đơn bị hủy |

---

## 🎨 UI/UX Features

### Product List
- ✅ Grid view (2 cột)
- ✅ Product image
- ✅ Product name
- ✅ Price (gạch ngang nếu có giảm giá)
- ✅ Sale price (màu đỏ)
- ✅ Discount badge
- ✅ Stock quantity

### Product Detail
- ✅ Large product image
- ✅ Category badge
- ✅ Price & sale price
- ✅ Discount percentage
- ✅ Stock indicator
- ✅ Full description
- ✅ Action buttons (sticky bottom)

### Cart
- ✅ Product thumbnail
- ✅ Quantity controls (+/-)
- ✅ Delete button
- ✅ Item subtotal
- ✅ Cart total
- ✅ Item count badge

### Checkout
- ✅ Clean form layout
- ✅ Form validation
- ✅ Payment method selection (radio buttons)
- ✅ Order summary card
- ✅ Loading state

### Order History
- ✅ Card layout
- ✅ Color-coded status
- ✅ Date & time
- ✅ Total price
- ✅ "View detail" button

---

## 🔄 Chức năng sắp có

### Mua lại sản phẩm (Rebuy)
- Gợi ý sản phẩm đã mua
- One-click rebuy
- Tính tần suất mua

### Mua nhóm (Group Buy)
- Giá giảm theo số người
- Real-time buyer count
- Timer countdown

### Flash Sale
- Giảm giá theo khung giờ
- Countdown timer
- Limited stock

### Profile
- Thông tin cá nhân
- Địa chỉ giao hàng
- Phương thức thanh toán
- Cài đặt

---

## 💡 Tips

### Mua hàng nhanh:
1. Sử dụng search để tìm sản phẩm nhanh
2. Click "Mua ngay" để bỏ qua giỏ hàng
3. Lưu thông tin giao hàng cho lần sau

### Tiết kiệm:
1. Check Flash Sale hàng ngày
2. Tham gia Group Buy để có giá tốt
3. Theo dõi sản phẩm yêu thích

### Theo dõi đơn hàng:
1. Check email xác nhận đơn hàng
2. Xem trạng thái trong "Lịch sử"
3. Liên hệ shop nếu có vấn đề

---

## 📱 Screenshots Flow

### Flow 1: Mua hàng cơ bản
```
Home Screen
   ↓
Product List (Grid view với 6-8 sản phẩm)
   ↓
Product Detail (Chi tiết iPhone 15 Pro)
   ↓
Cart (2 sản phẩm, tổng 60M)
   ↓
Checkout (Form + payment)
   ↓
Order Success (Mã đơn #abc12345)
   ↓
Order History (List orders)
```

### Flow 2: Xem lịch sử
```
Home Screen
   ↓
Click "Lịch sử"
   ↓
Order History (List tất cả orders)
   ↓
Order Detail (Chi tiết 1 order)
```

---

## ✅ Checklist đầy đủ

### Authentication
- [x] Đăng ký
- [x] Đăng nhập
- [x] Đăng xuất

### Products
- [x] Xem danh sách
- [x] Tìm kiếm
- [x] Xem chi tiết
- [x] Filter theo category

### Cart
- [x] Thêm vào giỏ
- [x] Xem giỏ hàng
- [x] Tăng/giảm số lượng
- [x] Xóa khỏi giỏ
- [x] Clear cart

### Orders
- [x] Checkout
- [x] Đặt hàng
- [x] Xem lịch sử
- [x] Xem chi tiết đơn
- [x] Theo dõi trạng thái

### Coming Soon
- [ ] Rebuy products
- [ ] Group buys
- [ ] Flash sales
- [ ] Wishlist
- [ ] Product reviews
- [ ] Notifications

---

**🎯 Customer features đã sẵn sàng 100% cho demo và sử dụng!**

Enjoy shopping! 🛍️
