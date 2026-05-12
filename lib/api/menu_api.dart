import 'dart:convert';

import 'package:scan2serve/api/api_client.dart';
import 'package:scan2serve/api/media_url.dart';
import 'package:scan2serve/models/home/home_model.dart';

class MenuApiException implements Exception {
  MenuApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'MenuApiException($statusCode): $body';
}

Future<List<Map<String, dynamic>>> fetchMenuCategories() async {
  final res = await apiGet('/menu/categories/');
  if (res.statusCode != 200) {
    throw MenuApiException(res.statusCode, res.body);
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! List<dynamic>) {
    throw MenuApiException(res.statusCode, 'Expected list for /menu/categories/');
  }
  return decoded.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> fetchMenuItems() async {
  final res = await apiGet('/menu/items/');
  if (res.statusCode != 200) {
    throw MenuApiException(res.statusCode, res.body);
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! List<dynamic>) {
    throw MenuApiException(res.statusCode, 'Expected list for /menu/items/');
  }
  return decoded.cast<Map<String, dynamic>>();
}

String? _stringField(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// Picks image URL from common DRF / nested shapes.
String? rawMenuImageFromJson(Map<String, dynamic> json) {
  final direct = _stringField(json, ['image_url', 'image', 'photo', 'thumbnail']);
  if (direct != null) return direct;

  final nested = json['menu_item'];
  if (nested is Map<String, dynamic>) {
    final n = _stringField(nested, ['image_url', 'image', 'photo', 'thumbnail']);
    if (n != null) return n;
  }
  return null;
}

int _priceToInt(dynamic price) {
  if (price is int) return price;
  if (price is double) return price.round();
  if (price is String) {
    return int.tryParse(price.split('.').first) ?? 0;
  }
  return 0;
}

MenuItemModel menuItemFromApiJson(Map<String, dynamic> json) {
  final id = json['id'] as int?;
  final name = json['name'] as String? ?? 'Item';
  final desc = json['description'] as String? ?? '';
  final p = _priceToInt(json['price']);
  final rawImg = rawMenuImageFromJson(json);

  return MenuItemModel(
    name: name,
    priceLabel: 'Rs $p',
    description: desc,
    menuItemId: id,
    imageUrl: absoluteMediaUrl(rawImg),
  );
}
