import 'dart:convert';

import 'package:scan2serve/api/api_client.dart';

Future<List<dynamic>> fetchFavourites() async {
  final res = await apiGet('/favourites/');
  if (res.statusCode != 200) {
    throw FavouritesApiException(res.statusCode, res.body);
  }
  return jsonDecode(res.body) as List<dynamic>;
}

Future<Map<String, dynamic>> addFavourite(int menuItemId) async {
  final res = await apiPost('/favourites/', body: {'menu_item': menuItemId});
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw FavouritesApiException(res.statusCode, res.body);
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<void> removeFavourite(int favouriteId) async {
  final res = await apiDelete('/favourites/$favouriteId/');
  if (res.statusCode != 204 && res.statusCode != 200) {
    throw FavouritesApiException(res.statusCode, res.body);
  }
}

class FavouritesApiException implements Exception {
  FavouritesApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'FavouritesApiException($statusCode): $body';
}
