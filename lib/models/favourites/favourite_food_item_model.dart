import 'package:scan2serve/api/media_url.dart';

class FavouriteFoodItemModel {
  const FavouriteFoodItemModel({
    required this.favouriteId,
    required this.menuItemId,
    required this.name,
    required this.priceRs,
    this.imageUrl,
  });

  final int favouriteId;
  final int menuItemId;
  final String name;
  final int priceRs;
  final String? imageUrl;

  String get priceLabel => 'Rs $priceRs';

  static FavouriteFoodItemModel? tryFromApiJson(Map<String, dynamic> json) {
    final favouriteId = json['id'] as int?;
    if (favouriteId == null) return null;

    int? menuItemId;
    Map<String, dynamic>? detail =
        json['menu_item_detail'] as Map<String, dynamic>?;
    final dynamic rawMenu = json['menu_item'];
    if (rawMenu is int) {
      menuItemId = rawMenu;
    } else if (rawMenu is Map<String, dynamic>) {
      detail ??= rawMenu;
      menuItemId = rawMenu['id'] as int?;
    }

    if (detail != null) {
      menuItemId = detail['id'] as int? ?? menuItemId;
    }
    menuItemId ??= 0;

    final name = detail?['name'] as String? ?? 'Menu item';
    final dynamic rawPrice = detail?['price'];
    int priceRs = 0;
    if (rawPrice is num) {
      priceRs = rawPrice.round();
    } else if (rawPrice is String) {
      priceRs = int.tryParse(rawPrice.split('.').first) ?? 0;
    }

    final rawImage = detail?['image'] as String? ??
        detail?['image_url'] as String?;

    return FavouriteFoodItemModel(
      favouriteId: favouriteId,
      menuItemId: menuItemId,
      name: name,
      priceRs: priceRs,
      imageUrl: absoluteMediaUrl(rawImage),
    );
  }
}
