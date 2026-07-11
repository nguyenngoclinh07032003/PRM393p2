import 'package:flutter/material.dart';

class PolicySectionData {
  final String id;
  final String title;
  final IconData icon;
  final List<String> items;

  const PolicySectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });
}

class QualityCommitmentData {
  static const title = 'Cam kết chất lượng';
  static const subtitle =
      'SmartDeal Shop cam kết mang đến sản phẩm chính hãng, giao hàng an toàn '
      'và chính sách đổi trả minh bạch cho mọi khách hàng.';

  static const commitmentChips = [
    ('Chính hãng', Icons.verified_outlined),
    ('Đổi trả 7 ngày', Icons.replay_outlined),
    ('Kiểm tra trước khi nhận', Icons.fact_check_outlined),
    ('Giao hàng an toàn', Icons.local_shipping_outlined),
  ];

  static const sections = [
    PolicySectionData(
      id: 'authentic',
      title: 'Sản phẩm chính hãng',
      icon: Icons.verified_user_outlined,
      items: [
        'Nguồn gốc sản phẩm được khai báo rõ trên trang chi tiết.',
        'Nhà cung cấp là đối tác chính hãng hoặc nhà phân phối uy tín.',
        'Kèm chứng nhận hoặc hóa đơn VAT khi giao hàng (nếu có).',
        'Tem bảo hành chính hãng được dán đầy đủ trên sản phẩm.',
        'Điều kiện xác minh: mã serial/IMEI hợp lệ, tem nguyên vẹn, phụ kiện đủ bộ.',
      ],
    ),
    PolicySectionData(
      id: 'inspection',
      title: 'Chính sách kiểm tra hàng',
      icon: Icons.inventory_2_outlined,
      items: [
        'Khách được kiểm tra bên ngoài sản phẩm trước khi nhận.',
        'Được kiểm tra màu sắc, mẫu mã và số lượng so với đơn hàng.',
        'Sản phẩm niêm phong: chỉ được mở niêm phong khi shipper đồng ý hỗ trợ kiểm tra ngoại quan.',
        'Không áp dụng kiểm tra trước: thực phẩm đóng gói kín, sản phẩm tiêu hao đã mở seal.',
      ],
    ),
    PolicySectionData(
      id: 'return',
      title: 'Chính sách đổi trả',
      icon: Icons.assignment_return_outlined,
      items: [
        'Đổi trả trong vòng 7 ngày kể từ khi nhận hàng thành công.',
        'Điều kiện: sản phẩm còn nguyên tem, đủ phụ kiện, không trầy xước do sử dụng.',
        'Hoàn tiền 100% khi giao sai mẫu, lỗi kỹ thuật từ nhà sản xuất hoặc hư hỏng do vận chuyển.',
        'Từ chối đổi trả: sản phẩm đã qua sử dụng, thiếu phụ kiện, hết hạn đổi trả.',
        'Chi phí vận chuyển đổi trả: miễn phí nếu lỗi từ shop; khách chịu phí nếu đổi ý.',
      ],
    ),
    PolicySectionData(
      id: 'delivery',
      title: 'Chính sách giao hàng',
      icon: Icons.local_shipping_outlined,
      items: [
        'Thời gian giao dự kiến: 1–3 ngày nội thành, 3–7 ngày tỉnh thành khác.',
        'Đơn vị vận chuyển: GHN, GHTK, Viettel Post (tùy khu vực).',
        'Theo dõi trạng thái đơn trực tiếp tại mục Đơn hàng của tôi.',
        'Giao chậm: shop hỗ trợ tra soát và bồi hoàn voucher nếu quá cam kết.',
        'Hư hỏng khi giao: chụp ảnh hiện trường, từ chối nhận hoặc đổi mới trong 24h.',
      ],
    ),
    PolicySectionData(
      id: 'warranty',
      title: 'Chính sách bảo hành',
      icon: Icons.build_circle_outlined,
      items: [
        'Thời gian bảo hành theo tiêu chuẩn hãng (thường 12–24 tháng).',
        'Trung tâm bảo hành chính hãng trên toàn quốc.',
        'Điều kiện: tem bảo hành còn nguyên, không rơi vào trường hợp người dùng gây hỏng.',
        'Quy trình: Liên hệ hỗ trợ → Cung cấp hóa đơn & serial → Chuyển TTBH → Nhận lại máy.',
      ],
    ),
  ];

  static const faq = [
    (
      'Tôi có được đổi size/màu không?',
      'Có, trong 7 ngày nếu sản phẩm còn nguyên seal và tồn kho cho phép.',
    ),
    (
      'Làm sao biết sản phẩm chính hãng?',
      'Kiểm tra tem, serial trên website hãng và hóa đơn kèm theo.',
    ),
    (
      'Giao hàng COD có kiểm tra được không?',
      'Có, bạn được xem và kiểm tra ngoại quan trước khi thanh toán.',
    ),
  ];
}
