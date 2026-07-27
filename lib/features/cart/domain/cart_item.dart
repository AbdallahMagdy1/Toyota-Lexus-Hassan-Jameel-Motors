import 'package:equatable/equatable.dart';

import '../../home/domain/home_models.dart';

/// One car in the cart — enough cached display data to render offline;
/// productId+colorId are what the website's WebUserCart procs key on.
final class CartItem extends Equatable {
  const CartItem({
    required this.slug,
    this.productId,
    this.colorId,
    this.modelTypeId,
    this.year,
    this.nameEn,
    this.nameAr,
    this.image,
    this.price,
  });

  final String slug;
  final String? productId;
  final String? colorId;
  final String? modelTypeId;
  final String? year;
  final String? nameEn;
  final String? nameAr;
  final String? image;
  final double? price;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory CartItem.fromVehicle(OnlineVehicle v, {CarColor? color}) => CartItem(
        slug: v.slug ?? '',
        productId: v.productId,
        colorId: color?.colorId ??
            (v.uniqueColors.isEmpty ? null : v.uniqueColors.first.colorId),
        modelTypeId: v.type,
        year: v.year,
        nameEn: '${v.groupEn ?? ''} ${v.year ?? ''}'.trim(),
        nameAr: '${v.groupAr ?? v.groupEn ?? ''} ${v.year ?? ''}'.trim(),
        image: v.image,
        price: v.minPrice,
      );

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        slug: j['slug'] as String? ?? '',
        productId: j['productId'] as String?,
        colorId: j['colorId'] as String?,
        modelTypeId: j['modelTypeId'] as String?,
        year: j['year'] as String?,
        nameEn: j['nameEn'] as String?,
        nameAr: j['nameAr'] as String?,
        image: j['image'] as String?,
        price: (j['price'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'productId': productId,
        'colorId': colorId,
        'modelTypeId': modelTypeId,
        'year': year,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'image': image,
        'price': price,
      };

  @override
  List<Object?> get props => [slug, colorId];
}
