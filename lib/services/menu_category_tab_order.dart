/// Sorts API menu category names for chip order: starters → mains → sides →
/// drinks → desserts → order-history style tabs last.
List<String> organizeMenuTabOrder(List<String> tabs) {
  final List<String> copy = List<String>.from(tabs);
  copy.sort((String a, String b) {
    final int ra = _menuCategorySortRank(a);
    final int rb = _menuCategorySortRank(b);
    if (ra != rb) {
      return ra.compareTo(rb);
    }
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return copy;
}

int _menuCategorySortRank(String raw) {
  final String s = raw.toLowerCase().trim();

  if (s.contains('previous') ||
      s.contains('past order') ||
      s == 'history' ||
      s.contains('order history')) {
    return 900;
  }
  if (s.contains('dessert') || s == 'sweets' || s.contains('sweet treats')) {
    return 700;
  }
  if (s.contains('beverage') ||
      s.contains('drink') ||
      s.contains('juice') ||
      s.contains('coffee') ||
      s.contains('tea') ||
      s.contains('smoothie') ||
      s.contains('shake') ||
      s.contains('mocktail') ||
      s.contains('cocktail') ||
      s.contains('milkshake') ||
      s.contains('soda') ||
      s.contains('soft drink')) {
    return 600;
  }
  if (s.contains('side') ||
      s.contains('extra') ||
      s.contains('add-on') ||
      s.contains('addon')) {
    return 450;
  }
  if (s.contains('salad')) {
    return 120;
  }
  if (s.contains('starter') ||
      s.contains('appetizer') ||
      s.contains('soup')) {
    return 80;
  }
  if (s == 'new' ||
      s.contains('popular') ||
      s.contains('featured') ||
      s.contains('recommended') ||
      s.contains('trending') ||
      s.contains('specials')) {
    return 20;
  }
  // Default: mains and other savory categories (pizza, grill, rice, curry, etc.)
  return 200;
}
