import 'package:flutter/material.dart';
import 'package:scan2serve/api/favourites_api.dart';
import 'package:scan2serve/models/favourites/favourite_food_item_model.dart';

class FavouriteFoodsViewModel extends ChangeNotifier {
  FavouriteFoodsViewModel() {
    refresh();
  }

  static const String screenTitle = 'Favourite Foods';

  final List<FavouriteFoodItemModel> _items = [];
  bool _loading = true;
  String? _errorMessage;

  List<FavouriteFoodItemModel> get items =>
      List<FavouriteFoodItemModel>.unmodifiable(_items);

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final raw = await fetchFavourites();
      _items
        ..clear()
        ..addAll(
          raw
              .map((e) => FavouriteFoodItemModel.tryFromApiJson(
                    e as Map<String, dynamic>,
                  ))
              .whereType<FavouriteFoodItemModel>(),
        );
    } catch (e) {
      _errorMessage = e.toString();
      _items.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavouriteById(int favouriteId) async {
    await removeFavourite(favouriteId);
    _items.removeWhere((e) => e.favouriteId == favouriteId);
    notifyListeners();
  }
}
