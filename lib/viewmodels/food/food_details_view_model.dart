import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/favourites_api.dart';
import 'package:scan2serve/models/food/food_details_model.dart';

class FoodDetailsViewModel extends ChangeNotifier {
  FoodDetailsViewModel({required FoodDetailsModel model}) : _model = model;

  final FoodDetailsModel _model;
  int _quantity = 1;
  bool _favouriteBusy = false;
  bool _isFavourite = false;
  int? _favouriteRowId;

  FoodDetailsModel get viewData => _model;
  int get quantity => _quantity;
  bool get favouriteBusy => _favouriteBusy;
  bool get isFavourite => _isFavourite;
  bool get canUseFavourite =>
      _model.menuItemId != null &&
      (authAccessToken.value != null && authAccessToken.value!.isNotEmpty);

  void increment() {
    _quantity++;
    notifyListeners();
  }

  void decrement() {
    if (_quantity <= 1) return;
    _quantity--;
    notifyListeners();
  }

  void onAddToCart() {
    debugPrint('Add to cart: ${_model.name}, qty=$_quantity');
  }

  Future<void> syncFavouriteFromApi() async {
    final id = _model.menuItemId;
    if (id == null) return;
    if (authAccessToken.value == null || authAccessToken.value!.isEmpty) {
      _isFavourite = false;
      _favouriteRowId = null;
      notifyListeners();
      return;
    }
    try {
      final list = await fetchFavourites();
      _favouriteRowId = null;
      _isFavourite = false;
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        int? mid;
        final dynamic rm = m['menu_item'];
        if (rm is int) {
          mid = rm;
        } else if (rm is Map<String, dynamic>) {
          mid = rm['id'] as int?;
        }
        final detail = m['menu_item_detail'] as Map<String, dynamic>?;
        mid = detail?['id'] as int? ?? mid;
        if (mid == id) {
          _favouriteRowId = m['id'] as int?;
          _isFavourite = true;
          break;
        }
      }
    } catch (_) {
      _favouriteRowId = null;
      _isFavourite = false;
    }
    notifyListeners();
  }

  /// Returns a message for [SnackBar] on failure, or null on success.
  Future<String?> toggleFavourite() async {
    final id = _model.menuItemId;
    if (id == null) return 'This item cannot be favourited yet.';
    if (authAccessToken.value == null || authAccessToken.value!.isEmpty) {
      return 'Sign in to save favourites.';
    }
    if (_favouriteBusy) return null;
    _favouriteBusy = true;
    notifyListeners();
    try {
      if (_isFavourite && _favouriteRowId != null) {
        await removeFavourite(_favouriteRowId!);
        _isFavourite = false;
        _favouriteRowId = null;
      } else {
        final row = await addFavourite(id);
        _favouriteRowId = row['id'] as int?;
        _isFavourite = true;
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _favouriteBusy = false;
      notifyListeners();
    }
  }
}
