import 'package:equatable/equatable.dart';

/// One spare part in the parts cart — enough cached display data to render
/// offline; productId (fallback guid) + unit price + isStock are what the
/// website's checkout payload sends per line.
final class PartsCartItem extends Equatable {
  const PartsCartItem({
    required this.guid,
    this.productId,
    this.productNo,
    this.nameAr,
    this.nameEn,
    this.image,
    this.price,
    this.inStock = true,
    this.qty = 1,
  });

  final String guid;
  final String? productId;
  final String? productNo;
  final String? nameAr;
  final String? nameEn;
  final String? image;
  final double? price;
  final bool inStock;
  final int qty;

  String name(String lang) =>
      (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  double get lineTotal => (price ?? 0) * qty;

  PartsCartItem copyWith({int? qty}) => PartsCartItem(
        guid: guid,
        productId: productId,
        productNo: productNo,
        nameAr: nameAr,
        nameEn: nameEn,
        image: image,
        price: price,
        inStock: inStock,
        qty: qty ?? this.qty,
      );

  factory PartsCartItem.fromJson(Map<String, dynamic> j) => PartsCartItem(
        guid: j['guid'] as String? ?? '',
        productId: j['productId'] as String?,
        productNo: j['productNo'] as String?,
        nameAr: j['nameAr'] as String?,
        nameEn: j['nameEn'] as String?,
        image: j['image'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        inStock: j['inStock'] != false,
        qty: (j['qty'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'guid': guid,
        'productId': productId,
        'productNo': productNo,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'image': image,
        'price': price,
        'inStock': inStock,
        'qty': qty,
      };

  @override
  List<Object?> get props => [guid, qty];
}
