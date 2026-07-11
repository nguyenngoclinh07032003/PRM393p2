# Smart Shop App

## 1. Giới thiệu dự án

**Smart Shop App** là ứng dụng bán hàng trực tuyến được xây dựng trên nền tảng **Firebase**, cho phép khách hàng mua sắm, săn khuyến mãi và tham gia các chương trình mua hàng thông minh. Hệ thống hỗ trợ quản lý sản phẩm, đơn hàng theo thời gian thực và các chương trình giảm giá linh hoạt.

---

# 2. Mục tiêu dự án

Xây dựng một ứng dụng thương mại điện tử có khả năng:

* Mua hàng trực tuyến.
* Mua lại sản phẩm đã từng mua.
* Phân tích tần suất mua lại của khách hàng.
* Mua theo nhóm với giá thay đổi theo số lượng người tham gia.
* Khuyến mãi theo khung giờ vàng (Flash Sale).
* Quản lý sản phẩm và giảm giá cho nhà bán hàng.
* Theo dõi đơn hàng theo thời gian thực (Realtime).

---

# 3. Công nghệ sử dụng

## Frontend

* Flutter (Mobile Application)

## Backend

* Firebase Cloud Functions
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Messaging (FCM)

---

# 4. Kiến trúc hệ thống

```text
Flutter App
      |
Firebase Authentication
      |
Cloud Firestore
      |
Cloud Functions
      |
Firebase Storage
      |
Firebase Cloud Messaging
```

---

# 5. Vai trò người dùng

## Customer

* Đăng ký tài khoản
* Đăng nhập
* Xem sản phẩm
* Xem chi tiết sản phẩm
* Thêm sản phẩm vào giỏ hàng
* Đặt hàng
* Mua lại sản phẩm
* Xem lịch sử mua hàng
* Tham gia mua nhóm
* Săn khuyến mãi khung giờ vàng

## Seller

* Quản lý sản phẩm
* Thêm sản phẩm mới
* Cấu hình sản phẩm
* Cấu hình giảm giá
* Cấu hình khung giờ vàng
* Quản lý đơn hàng
* Xem báo cáo doanh thu

## Admin

* Quản lý người dùng
* Quản lý sản phẩm
* Quản lý đơn hàng
* Theo dõi đơn hàng theo thời gian thực
* Quản lý chương trình khuyến mãi
* Xem báo cáo thống kê

---

# 6. Chức năng chính

## 6.1 Mua lại sản phẩm (Rebuy)

Khách hàng có thể mua lại nhanh những sản phẩm đã từng mua.

Ví dụ:

* Kem đánh răng: 5 lần
* Sữa tắm: 3 lần
* Nước giặt: 4 lần

Hệ thống sẽ gợi ý các sản phẩm thường xuyên được mua lại.

---

## 6.2 Tần suất mua lại

Hệ thống tính số lần mua sản phẩm của từng khách hàng.

Công thức:

```text
Purchase Frequency =
Tổng số lần mua / Khoảng thời gian sử dụng
```

Ví dụ:

```text
Sữa tắm:
6 lần mua / 6 tháng
=> Tần suất: 1 lần/tháng
```

---

## 6.3 Mua theo nhóm (Group Buying)

Giá sản phẩm thay đổi theo số lượng người tham gia mua.

Ví dụ:

| Số người mua  | Giá bán     |
| ------------- | ----------- |
| < 50 người    | 200.000 VNĐ |
| 50 - 99 người | 170.000 VNĐ |
| >= 100 người  | 150.000 VNĐ |

Logic:

```text
Nếu số người mua >= 100
    Giá = 150.000

Nếu số người mua >= 50
    Giá = 170.000

Nếu số người mua < 50
    Giá = 200.000
```

---

## 6.4 Khung giờ vàng (Flash Sale)

Hệ thống hỗ trợ giảm giá theo thời gian cố định.

Ví dụ:

* 12:00 - 13:00: Giảm 20% toàn bộ sản phẩm.
* 20:00 - 22:00: Giảm 30% cho một số sản phẩm.

Khi hết thời gian, giá sản phẩm sẽ quay về giá gốc.

---

# 7. Cấu trúc cơ sở dữ liệu Firebase

## Collections

```text
users
products
carts
orders
order_items
rebuy_stats
group_buys
flash_sales
discounts
notifications
```

---

# 8. Thiết kế Collection

## users

```json
{
  "uid": "",
  "fullName": "",
  "email": "",
  "phone": "",
  "role": "customer | seller | admin",
  "status": "active",
  "createdAt": "timestamp"
}
```

---

## products

```json
{
  "sellerId": "",
  "name": "",
  "description": "",
  "price": 0,
  "salePrice": 0,
  "stock": 0,
  "imageUrl": "",
  "category": "",
  "status": "active",
  "createdAt": "timestamp"
}
```

---

## carts

```json
{
  "userId": "",
  "productId": "",
  "quantity": 0,
  "price": 0,
  "createdAt": "timestamp"
}
```

---

## orders

```json
{
  "userId": "",
  "sellerId": "",
  "totalPrice": 0,
  "status": "pending",
  "paymentStatus": "unpaid",
  "createdAt": "timestamp"
}
```

---

## order_items

```json
{
  "orderId": "",
  "productId": "",
  "productName": "",
  "quantity": 0,
  "price": 0
}
```

---

## rebuy_stats

```json
{
  "userId": "",
  "productId": "",
  "buyCount": 0,
  "lastBuyAt": "timestamp",
  "averageDays": 0
}
```

---

## group_buys

```json
{
  "productId": "",
  "currentBuyerCount": 0,
  "priceUnder50": 0,
  "priceFrom50": 0,
  "priceFrom100": 0,
  "startTime": "timestamp",
  "endTime": "timestamp",
  "status": "active"
}
```

---

## flash_sales

```json
{
  "name": "",
  "productIds": [],
  "isAllProduct": false,
  "discountPercent": 0,
  "startTime": "",
  "endTime": "",
  "status": "active"
}
```

---

## discounts

```json
{
  "sellerId": "",
  "productId": "",
  "discountType": "percent",
  "discountValue": 0,
  "startTime": "timestamp",
  "endTime": "timestamp",
  "status": "active"
}
```

---

# 9. Luồng hoạt động hệ thống

## Mua hàng

```text
Login
↓
Product List
↓
Product Detail
↓
Add To Cart
↓
Checkout
↓
Create Order
↓
Realtime Update
```

---

## Mua lại sản phẩm

```text
Order History
↓
Read Previous Orders
↓
Calculate Purchase Frequency
↓
Recommend Products
↓
Buy Again
```

---

## Mua nhóm

```text
Join Group Buy
↓
Increase Buyer Count
↓
Recalculate Price
↓
Apply New Price
```

---

## Flash Sale

```text
Configure Flash Sale
↓
Start Time Reached
↓
Apply Discount Price
↓
End Time Reached
↓
Restore Original Price
```

---

# 10. Màn hình hệ thống

## Customer Screens

* Splash Screen
* Login Screen
* Register Screen
* Home Screen
* Product List Screen
* Product Detail Screen
* Cart Screen
* Checkout Screen
* Order History Screen
* Buy Again Screen
* Group Buy Screen
* Flash Sale Screen
* Profile Screen

## Seller Screens

* Seller Dashboard
* Product Management
* Add Product
* Edit Product
* Discount Configuration
* Flash Sale Configuration
* Order Management
* Revenue Report

## Admin Screens

* Admin Dashboard
* User Management
* Product Management
* Realtime Order Dashboard
* Discount Management
* System Reports

---

# 11. Điểm nổi bật của hệ thống

* Firebase Realtime Database với Cloud Firestore
* Đơn hàng cập nhật theo thời gian thực
* Mua lại sản phẩm thông minh
* Phân tích tần suất mua hàng
* Mua theo nhóm với giá động
* Flash Sale theo khung giờ vàng
* Hệ thống giảm giá linh hoạt
* Kiến trúc phù hợp cho ứng dụng thương mại điện tử hiện đại
