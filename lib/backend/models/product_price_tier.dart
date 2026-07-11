class ProductPriceTier {
  const ProductPriceTier({
    required this.minQty,
    required this.unitPrice,
    this.maxQty,
  });

  final int minQty;
  final int? maxQty;
  final double unitPrice;

  factory ProductPriceTier.fromMap(Map<String, dynamic> data) {
    return ProductPriceTier(
      minQty: (data['minQty'] as num?)?.toInt() ?? 1,
      maxQty: data['maxQty'] == null ? null : (data['maxQty'] as num).toInt(),
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minQty': minQty,
      'maxQty': maxQty,
      'unitPrice': unitPrice,
    };
  }

  ProductPriceTier copyWith({
    int? minQty,
    int? maxQty,
    bool clearMaxQty = false,
    double? unitPrice,
  }) {
    return ProductPriceTier(
      minQty: minQty ?? this.minQty,
      maxQty: clearMaxQty ? null : (maxQty ?? this.maxQty),
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  String get rangeLabel {
    if (maxQty == null) return 'Từ $minQty trở lên';
    if (minQty == maxQty) return '$minQty cái';
    return '$minQty - $maxQty cái';
  }

  bool matchesQuantity(int quantity) {
    if (quantity < minQty) return false;
    if (maxQty == null) return true;
    return quantity <= maxQty!;
  }
}
