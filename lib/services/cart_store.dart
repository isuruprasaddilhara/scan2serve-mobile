import 'package:flutter/foundation.dart';
import 'package:scan2serve/formatting/rs_money.dart';
import 'package:scan2serve/models/cart/cart_model.dart';
import 'package:scan2serve/models/home/home_model.dart';

/// Shared cart for signed-in users and guests (same UI flow).
class CartStore extends ChangeNotifier {
  CartStore._();
  static final CartStore instance = CartStore._();

  final List<CartItemModel> _lines = <CartItemModel>[];

  List<CartItemModel> get items => List<CartItemModel>.unmodifiable(_lines);

  int get totalQuantity =>
      _lines.fold<int>(0, (int s, CartItemModel e) => s + e.quantity);

  int get totalRs =>
      _lines.fold<int>(0, (int s, CartItemModel e) => s + e.lineTotalRs);

  bool get hasItems => _lines.isNotEmpty;

  String _lineId(MenuItemModel item) {
    final int? mid = item.menuItemId;
    if (mid != null) return 'mid_$mid';
    final String slug = item.name.trim().toLowerCase();
    final int price = parseRsAmount(item.priceLabel);
    return 'name_${slug.hashCode}_$price';
  }

  CartItemModel _fromMenu(MenuItemModel item, int quantity) {
    final int unit = parseRsAmount(item.priceLabel);
    return CartItemModel(
      id: _lineId(item),
      name: item.name,
      unitPriceRs: unit,
      quantity: quantity,
      description: item.description,
      imageUrl: item.imageUrl,
      menuItemId: item.menuItemId,
    );
  }

  /// Same key used when merging lines in [addMenuItem].
  String lineIdForMenuItem(MenuItemModel item) => _lineId(item);

  int quantityInCart(MenuItemModel item) {
    final String id = _lineId(item);
    for (final CartItemModel e in _lines) {
      if (e.id == id) return e.quantity;
    }
    return 0;
  }

  /// Add or merge quantities for the same menu row.
  void addMenuItem(MenuItemModel item, [int quantity = 1]) {
    final int q = quantity < 1 ? 1 : quantity;
    final String id = _lineId(item);
    final int index = _lines.indexWhere((CartItemModel e) => e.id == id);
    if (index >= 0) {
      final CartItemModel cur = _lines[index];
      _lines[index] =
          cur.copyWith(quantity: cur.quantity + q);
    } else {
      _lines.add(_fromMenu(item, q));
    }
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final int index = _lines.indexWhere((CartItemModel e) => e.id == id);
    if (index < 0) return;
    final CartItemModel cur = _lines[index];
    _lines[index] = cur.copyWith(quantity: cur.quantity + 1);
    notifyListeners();
  }

  void decrementQuantity(String id) {
    final int index = _lines.indexWhere((CartItemModel e) => e.id == id);
    if (index < 0) return;
    final CartItemModel cur = _lines[index];
    final int next = cur.quantity - 1;
    if (next <= 0) {
      _lines.removeAt(index);
    } else {
      _lines[index] = cur.copyWith(quantity: next);
    }
    notifyListeners();
  }

  void removeLine(String id) {
    final int before = _lines.length;
    _lines.removeWhere((CartItemModel e) => e.id == id);
    if (_lines.length != before) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
