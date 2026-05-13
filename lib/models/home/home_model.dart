class HomeModel {
  const HomeModel({
    required this.title,
    required this.searchHint,
    required this.tabs,
    required this.cartSummary,
  });

  final String title;
  final String searchHint;
  final List<String> tabs;
  final String cartSummary;
}

class MenuItemModel {
  const MenuItemModel({
    required this.name,
    required this.priceLabel,
    required this.description,
    this.menuItemId,
    this.imageUrl,
    this.rating,
    this.reviewCount,
  });

  final String name;
  final String priceLabel;
  final String description;
  final int? menuItemId;
  /// Absolute URL from API (see [menuItemFromApiJson]).
  final String? imageUrl;
  /// Average rating when provided by API (e.g. feedback aggregates).
  final double? rating;
  /// Number of reviews/ratings when provided by API.
  final int? reviewCount;
}
