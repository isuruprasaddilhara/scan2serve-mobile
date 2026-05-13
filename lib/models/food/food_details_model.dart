class FoodDetailsModel {
  const FoodDetailsModel({
    required this.name,
    required this.description,
    required this.priceLabel,
    this.menuItemId,
    this.imageUrl,
  });

  final String name;
  final String description;
  final String priceLabel;
  final int? menuItemId;
  final String? imageUrl;
}
