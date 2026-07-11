import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/config/app_constants.dart';
import '../backend/utils/product_image_utils.dart';

class SeedData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _buildProducts() {
    return [
      {
        'id': 'phone-iphone-15-pro',
        'name': 'iPhone 15 Pro 256GB',
        'description':
            'Chip A17 Pro, camera 48MP, khung titan, man hinh Super Retina XDR.',
        'price': 29990000,
        'salePrice': 27990000,
        'stock': 50,
        'category': 'Điện thoại',
      },
      {
        'id': 'phone-samsung-s24-ultra',
        'name': 'Samsung Galaxy S24 Ultra',
        'description':
            'Camera 200MP, S Pen, Galaxy AI, man hinh Dynamic AMOLED 2X.',
        'price': 33990000,
        'salePrice': 31990000,
        'stock': 40,
        'category': 'Điện thoại',
      },
      {
        'id': 'phone-xiaomi-14',
        'name': 'Xiaomi 14 5G',
        'description': 'Snapdragon 8 Gen 3, camera Leica, sac nhanh 90W.',
        'price': 22990000,
        'salePrice': 20990000,
        'stock': 45,
        'category': 'Điện thoại',
      },
      {
        'id': 'phone-oppo-reno11',
        'name': 'OPPO Reno11 F 5G',
        'description': 'Thiet ke mong nhe, camera chan dung 64MP, pin 5000mAh.',
        'price': 8990000,
        'salePrice': 7990000,
        'stock': 70,
        'category': 'Điện thoại',
      },
      {
        'id': 'phone-vivo-v30',
        'name': 'vivo V30 5G',
        'description':
            'Camera Aura Light, man hinh AMOLED 120Hz, sac nhanh 80W.',
        'price': 13990000,
        'salePrice': 12990000,
        'stock': 35,
        'category': 'Điện thoại',
      },
      {
        'id': 'phone-pixel-8-pro',
        'name': 'Google Pixel 8 Pro',
        'description': 'Tensor G3, camera AI, Android thuan, cap nhat lau dai.',
        'price': 24990000,
        'salePrice': 22990000,
        'stock': 20,
        'category': 'Điện thoại',
      },
      {
        'id': 'laptop-macbook-air-m3',
        'name': 'MacBook Air M3 13 inch',
        'description': 'Chip Apple M3, RAM 16GB, SSD 512GB, pin den 18 gio.',
        'price': 34990000,
        'salePrice': 32990000,
        'stock': 25,
        'category': 'Laptop',
      },
      {
        'id': 'laptop-dell-xps-13',
        'name': 'Dell XPS 13 Plus',
        'description': 'Intel Core i7, RAM 16GB, SSD 1TB, thiet ke sieu mong.',
        'price': 39990000,
        'salePrice': 36990000,
        'stock': 18,
        'category': 'Laptop',
      },
      {
        'id': 'laptop-asus-zenbook-14',
        'name': 'ASUS Zenbook 14 OLED',
        'description': 'Man hinh OLED 2.8K, Intel Core Ultra 7, AI ready.',
        'price': 28990000,
        'salePrice': 26990000,
        'stock': 30,
        'category': 'Laptop',
      },
      {
        'id': 'laptop-lenovo-legion-5',
        'name': 'Lenovo Legion 5 Gaming',
        'description':
            'Ryzen 7, RTX 4060, man hinh 165Hz, tan nhiet hieu nang cao.',
        'price': 31990000,
        'salePrice': 29990000,
        'stock': 16,
        'category': 'Laptop',
      },
      {
        'id': 'laptop-hp-pavilion-15',
        'name': 'HP Pavilion 15',
        'description':
            'Intel Core i5, RAM 16GB, SSD 512GB, phu hop hoc tap va van phong.',
        'price': 18990000,
        'salePrice': 16990000,
        'stock': 42,
        'category': 'Laptop',
      },
      {
        'id': 'watch-apple-series-9',
        'name': 'Apple Watch Series 9',
        'description': 'Theo doi suc khoe, GPS, man hinh luon bat, chip S9.',
        'price': 10990000,
        'salePrice': 9990000,
        'stock': 55,
        'category': 'Đồng hồ',
      },
      {
        'id': 'watch-samsung-watch6',
        'name': 'Samsung Galaxy Watch6',
        'description':
            'Man hinh Super AMOLED, do thanh phan co the, theo doi giac ngu.',
        'price': 6990000,
        'salePrice': 5990000,
        'stock': 62,
        'category': 'Đồng hồ',
      },
      {
        'id': 'watch-garmin-venu-3',
        'name': 'Garmin Venu 3',
        'description':
            'GPS the thao, pin toi 14 ngay, theo doi suc khoe chuyen sau.',
        'price': 11990000,
        'salePrice': 10990000,
        'stock': 24,
        'category': 'Đồng hồ',
      },
      {
        'id': 'watch-huawei-gt4',
        'name': 'Huawei Watch GT 4',
        'description': 'Thiet ke thanh lich, pin dai, nhieu che do luyen tap.',
        'price': 6490000,
        'salePrice': 5790000,
        'stock': 36,
        'category': 'Đồng hồ',
      },
      {
        'id': 'camera-canon-r50',
        'name': 'Canon EOS R50 Kit',
        'description':
            'Mirrorless APS-C, quay 4K, lay net Dual Pixel, phu hop vlog.',
        'price': 18990000,
        'salePrice': 17490000,
        'stock': 14,
        'category': 'Máy ảnh',
      },
      {
        'id': 'camera-sony-zve10',
        'name': 'Sony ZV-E10',
        'description':
            'May anh vlog, cam bien APS-C, mic dinh huong, thay ong kinh.',
        'price': 19990000,
        'salePrice': 18490000,
        'stock': 19,
        'category': 'Máy ảnh',
      },
      {
        'id': 'camera-fujifilm-xs20',
        'name': 'Fujifilm X-S20',
        'description':
            'Mau film Fujifilm, chong rung IBIS, quay 6.2K, pin khoe.',
        'price': 32990000,
        'salePrice': 30990000,
        'stock': 10,
        'category': 'Máy ảnh',
      },
      {
        'id': 'camera-gopro-hero12',
        'name': 'GoPro Hero 12 Black',
        'description':
            'Action camera 5.3K, chong rung HyperSmooth, chong nuoc.',
        'price': 10990000,
        'salePrice': 9990000,
        'stock': 33,
        'category': 'Máy ảnh',
      },
      {
        'id': 'audio-airpods-pro-2',
        'name': 'AirPods Pro 2 USB-C',
        'description': 'Chong on chu dong, am thanh khong gian, hop sac USB-C.',
        'price': 6490000,
        'salePrice': 5790000,
        'stock': 100,
        'category': 'Âm thanh',
      },
      {
        'id': 'audio-sony-wh1000xm5',
        'name': 'Sony WH-1000XM5',
        'description': 'Tai nghe chong on cao cap, pin 30 gio, am thanh Hi-Res.',
        'price': 8990000,
        'salePrice': 7990000,
        'stock': 45,
        'category': 'Âm thanh',
      },
      {
        'id': 'audio-jbl-charge-5',
        'name': 'JBL Charge 5',
        'description': 'Loa Bluetooth chong nuoc IP67, bass manh, pin 20 gio.',
        'price': 3990000,
        'salePrice': 3490000,
        'stock': 80,
        'category': 'Âm thanh',
      },
      {
        'id': 'audio-soundcore-liberty-4',
        'name': 'Soundcore Liberty 4 NC',
        'description':
            'Tai nghe true wireless, chong on, pin lau, app tuy chinh EQ.',
        'price': 2490000,
        'salePrice': 1990000,
        'stock': 75,
        'category': 'Âm thanh',
      },
      {
        'id': 'audio-marshall-emberton-ii',
        'name': 'Marshall Emberton II',
        'description':
            'Loa Bluetooth phong cach co dien, am thanh 360 do, pin 30 gio.',
        'price': 4990000,
        'salePrice': 4490000,
        'stock': 28,
        'category': 'Âm thanh',
      },
    ].map((product) {
      final id = product['id'] as String;
      final imageUrl = ProductImageUtils.imageForSeedProduct(id);
      return {
        ...product,
        'imageUrl': imageUrl,
        'imageUrls': [imageUrl],
      };
    }).toList();
  }

  static final List<Map<String, dynamic>> _products = _buildProducts();

  static Future<void> addSampleProducts(String sellerId) async {
    final batch = _firestore.batch();

    for (final product in _products) {
      final id = product['id'] as String;
      final productData = Map<String, dynamic>.from(product)..remove('id');
      productData.addAll({
        'sellerId': sellerId,
        'category': _categoryForProductId(id),
        'status': AppConstants.productActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        _firestore.collection(AppConstants.productsCollection).doc(id),
        productData,
      );
    }

    await batch.commit();
  }

  /// Cập nhật ảnh cho sản phẩm có URL hỏng/trống hoặc link tgdd.
  static Future<int> repairProductImages() async {
    final snapshot =
        await _firestore.collection(AppConstants.productsCollection).get();

    final batch = _firestore.batch();
    var updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final imageUrl = data['imageUrl'] as String? ?? '';
      final imageUrls = List<String>.from(data['imageUrls'] ?? []);
      final primary = imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

      if (!ProductImageUtils.needsFallback(primary)) continue;

      final fixed = ProductImageUtils.resolve(
        productId: doc.id,
        url: primary,
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
      );

      batch.update(doc.reference, {
        'imageUrl': fixed,
        'imageUrls': [fixed],
      });
      updated++;
    }

    if (updated > 0) {
      await batch.commit();
    }
    return updated;
  }

  static Future<void> addFlashSale() async {
    final flashSale = {
      'name': 'Flash Sale Gio Vang',
      'productIds': [
        'phone-iphone-15-pro',
        'phone-samsung-s24-ultra',
        'audio-airpods-pro-2',
        'laptop-macbook-air-m3',
      ],
      'isAllProduct': true,
      'discountPercent': 15.0,
      'startTime': Timestamp.fromDate(DateTime.now()),
      'endTime':
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 6))),
      'status': 'active',
    };

    await _firestore
        .collection(AppConstants.flashSalesCollection)
        .doc('sample-flash-sale')
        .set(flashSale);
  }

  static Future<void> addGroupBuy() async {
    final groupBuy = {
      'productId': 'audio-airpods-pro-2',
      'currentBuyerCount': 25,
      'priceUnder50': 5790000,
      'priceFrom50': 5490000,
      'priceFrom100': 4990000,
      'startTime': Timestamp.fromDate(DateTime.now()),
      'endTime':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'status': 'active',
      'participantIds': <String>[],
    };

    await _firestore
        .collection(AppConstants.groupBuysCollection)
        .doc('sample-group-buy')
        .set(groupBuy);
  }

  static Future<void> seedAll(String sellerId) async {
    await addSampleProducts(sellerId);
    await repairProductImages();
    await addFlashSale();
    await addGroupBuy();
  }

  static String _categoryForProductId(String id) {
    if (id.startsWith('phone-')) return 'Điện thoại';
    if (id.startsWith('laptop-')) return 'Laptop';
    if (id.startsWith('watch-')) return 'Đồng hồ';
    if (id.startsWith('camera-')) return 'Máy ảnh';
    if (id.startsWith('audio-')) return 'Âm thanh';
    return 'Khác';
  }
}
