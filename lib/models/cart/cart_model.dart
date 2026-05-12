/// One row on the cart screen (data only).
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.name,
    required this.unitPriceRs,
    required this.quantity,
    this.description = '',
    this.imageUrl,
    this.menuItemId,
  });

  final String id;
  final String name;
  final int unitPriceRs;
  final int quantity;
  final String description;
  final String? imageUrl;
  /// Backend `menu_item` id for `POST /orders/`; null if the line was not from API menu.
  final int? menuItemId;

  int get lineTotalRs => unitPriceRs * quantity;

  String get unitPriceLabel => 'Rs $unitPriceRs';
  String get lineTotalLabel => 'Rs $lineTotalRs';

  CartItemModel copyWith({int? quantity, int? menuItemId}) {
    return CartItemModel(
      id: id,
      name: name,
      unitPriceRs: unitPriceRs,
      quantity: quantity ?? this.quantity,
      description: description,
      imageUrl: imageUrl,
      menuItemId: menuItemId ?? this.menuItemId,
    );
  }
}

/// Static copy for the cart screen chrome (title, etc.).
class CartScreenModel {
  const CartScreenModel({
    required this.title,
    required this.totalLabel,
    required this.checkoutLabel,
  });

  final String title;
  final String totalLabel;
  final String checkoutLabel;
}
