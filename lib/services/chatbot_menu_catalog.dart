import 'dart:collection' show LinkedHashSet;

import 'package:scan2serve/api/menu_api.dart';
import 'package:scan2serve/models/home/home_model.dart';

/// Parsed intent for showing the in-chat menu carousel.
enum MenuCatalogTag {
  all,
  veg,
  chicken,
  beef,
  pork,
  meat,
}

final class MenuCatalogMatch {
  const MenuCatalogMatch({
    required this.tags,
    required this.botIntro,
    this.narrowTokens = const <String>[],
  });

  final Set<MenuCatalogTag> tags;
  final String botIntro;
  /// When length ≥ 2, each dish must contain every token in name+description (e.g. "chicken pizza").
  final List<String> narrowTokens;
}

String _menuBlob(MenuItemModel m) => '${m.name} ${m.description}'.toLowerCase();

/// Egg / egg dishes are excluded from the veg carousel (lacto-vegetarian style).
bool _mentionsEgg(String s) {
  if (RegExp(r'\begg\b').hasMatch(s)) return true;
  if (RegExp(r'\beggs\b').hasMatch(s)) return true;
  if (RegExp(r'\bomelet(te)?s?\b').hasMatch(s)) return true;
  return false;
}

bool _hasMeatProtein(String s) {
  const keys = <String>[
    'chicken',
    'beef',
    'pork',
    'lamb',
    'mutton',
    'duck',
    'turkey',
    'fish',
    'prawn',
    'shrimp',
    'crab',
    'salmon',
    'tuna',
    'seafood',
    'squid',
    'cuttlefish',
    'veal',
    'bacon',
    'ham',
    'sausage',
    'anchovy',
    'octopus',
    'eel',
  ];
  for (final String k in keys) {
    if (s.contains(k)) return true;
  }
  return false;
}

bool _matchesVeg(MenuItemModel m) {
  final String blob = _menuBlob(m);
  final String name = m.name.toLowerCase();

  if (_hasMeatProtein(blob)) return false;
  if (_mentionsEgg(blob)) return false;

  if (RegExp(r'\b(veg|veggie)\b').hasMatch(blob)) return true;
  if (blob.contains('vegetarian') || blob.contains('vegan')) return true;
  // Avoid matching descriptions like "with vegetables" on egg/meat dishes.
  if (RegExp(r'\bvegetables?\b').hasMatch(name)) return true;
  if (blob.contains('tofu') || blob.contains('paneer')) return true;
  return false;
}

bool _itemMatchesTags(MenuItemModel m, Set<MenuCatalogTag> tags) {
  final Set<MenuCatalogTag> active = tags.contains(MenuCatalogTag.all) && tags.length == 1
      ? {MenuCatalogTag.all}
      : tags.where((MenuCatalogTag t) => t != MenuCatalogTag.all).toSet();
  if (active.isEmpty) return true;

  final String s = _menuBlob(m);
  for (final MenuCatalogTag t in active) {
    switch (t) {
      case MenuCatalogTag.all:
        return true;
      case MenuCatalogTag.veg:
        if (_matchesVeg(m)) return true;
        break;
      case MenuCatalogTag.chicken:
        if (s.contains('chicken')) return true;
        break;
      case MenuCatalogTag.beef:
        if (s.contains('beef')) return true;
        break;
      case MenuCatalogTag.pork:
        if (s.contains('pork')) return true;
        break;
      case MenuCatalogTag.meat:
        if (_hasMeatProtein(s)) return true;
        break;
    }
  }
  return false;
}

const Set<String> _searchStopWords = {
  'the', 'a', 'an', 'i', 'me', 'my', 'we', 'our', 'you', 'your', 'u',
  'want', 'wants', 'would', 'like', 'liked',
  'show', 'shows', 'showing', 'give', 'gives', 'see', 'list', 'lists',
  'menu', 'menus', 'dish', 'dishes', 'food', 'foods', 'item', 'items', 'option', 'options',
  'some', 'any', 'please', 'pls',
  'about', 'for', 'with', 'from', 'into', 'out', 'can', 'could', 'should',
  'do', 'does', 'did', 'have', 'has', 'had', 'get', 'got',
  'what', 'which', 'when', 'where', 'why', 'how',
  'tell', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'there', 'here', 'something', 'anything', 'everything',
  'quick', 'look', 'browse', 'browsing', 'all', 'every',
  'and', 'or', 'but', 'not', 'no', 'yes', 'ok', 'okay',
  'very', 'too', 'also', 'just', 'only', 'maybe',
  'hey', 'hello', 'hi', 'thanks', 'thank',
  'recommend', 'suggest', 'best', 'good', 'great',
  'order', 'orders', 'pick', 'need', 'needs', 'know', 'more',
  'restaurant', 'table', 'booking', 'help', 'wait', 'minute', 'minutes',
};

/// Alphanumeric tokens (length ≥ 2) for specific-dish style queries.
List<String> _meaningfulSearchTokens(String lowerTrimmed) {
  final LinkedHashSet<String> unique = LinkedHashSet<String>();
  for (final String part in lowerTrimmed.split(RegExp(r'[^a-z0-9]+'))) {
    if (part.length < 2) continue;
    if (_searchStopWords.contains(part)) continue;
    unique.add(part);
  }
  return unique.toList(growable: false);
}

String _introFor(Set<MenuCatalogTag> tags) {
  final Set<MenuCatalogTag> active = tags.where((MenuCatalogTag t) => t != MenuCatalogTag.all).toSet();
  if (active.isEmpty || tags.contains(MenuCatalogTag.all) && active.isEmpty) {
    return 'Here are dishes from our menu. Tap a card to see details and add to cart.';
  }
  if (active.length == 1) {
    return switch (active.single) {
      MenuCatalogTag.veg => 'Here are vegetarian-friendly picks. Tap a card for full details.',
      MenuCatalogTag.chicken => 'Here are chicken dishes. Tap a card for full details.',
      MenuCatalogTag.beef => 'Here are beef dishes. Tap a card for full details.',
      MenuCatalogTag.pork => 'Here are pork dishes. Tap a card for full details.',
      MenuCatalogTag.meat => 'Here are meat and seafood options. Tap a card for full details.',
      MenuCatalogTag.all => 'Here are dishes from our menu. Tap a card for full details.',
    };
  }
  return 'Here are dishes that match what you asked for. Tap a card for full details.';
}

/// Returns null when the message should be handled by the normal chat API instead.
MenuCatalogMatch? parseMenuCatalogRequest(String raw) {
  final String t = raw.toLowerCase().trim();
  if (t.isEmpty) return null;

  // "View Menu" stays on the assistant API (unchanged from before).
  if (t == 'view menu') return null;

  final Set<MenuCatalogTag> tags = <MenuCatalogTag>{};

  if (RegExp(r'\b(vegetarian|vegan|veggie)\b').hasMatch(t) || RegExp(r'\bveg\b').hasMatch(t)) {
    tags.add(MenuCatalogTag.veg);
  }
  if (RegExp(r'\bchicken\b').hasMatch(t)) tags.add(MenuCatalogTag.chicken);
  if (RegExp(r'\bbeef\b').hasMatch(t)) tags.add(MenuCatalogTag.beef);
  if (RegExp(r'\bpork\b').hasMatch(t)) tags.add(MenuCatalogTag.pork);
  if (RegExp(r'\bmeat\b').hasMatch(t)) tags.add(MenuCatalogTag.meat);

  final bool browseCue = RegExp(r'\b(menu|dishes)\b').hasMatch(t) ||
      (RegExp(r'\b(food|items|options)\b').hasMatch(t) &&
          RegExp(r'\b(show|see|browse|list|view|give)\b').hasMatch(t)) ||
      RegExp(r'\b(order|pick)\s+something\b').hasMatch(t) ||
      RegExp(r'what(\s+\w+){0,4}\s+(do you have|can i (get|order)|you (have|serve|offer))').hasMatch(t);

  final List<String> searchTokens = _meaningfulSearchTokens(t);

  /// Short dish-name style queries (e.g. "kottu", "pizza") use the same in-chat
  /// carousel as "veg", instead of falling through to plain `/chat/` text.
  bool dishKeywordBrowse = false;
  if (tags.isEmpty && !browseCue) {
    if (searchTokens.isEmpty) return null;
    if (t.contains('?')) return null;
    final int wordCount =
        t.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;
    if (wordCount > 6) return null;
    tags.add(MenuCatalogTag.all);
    dishKeywordBrowse = true;
  }

  if (tags.isEmpty) tags.add(MenuCatalogTag.all);

  final List<String> narrowTokens =
      dishKeywordBrowse || searchTokens.length >= 2 ? searchTokens : const <String>[];

  final String botIntro = narrowTokens.isNotEmpty
      ? 'Here are dishes that best match your search. Tap a card for full details.'
      : _introFor(tags);

  return MenuCatalogMatch(tags: tags, botIntro: botIntro, narrowTokens: narrowTokens);
}

/// Loads the menu from the API and applies [match] filters. Max [limit] items.
Future<List<MenuItemModel>> loadMenuItemsForCatalog(MenuCatalogMatch match, {int limit = 24}) async {
  final List<Map<String, dynamic>> raw = await fetchMenuItems();
  final List<MenuItemModel> items = <MenuItemModel>[];
  for (final Map<String, dynamic> row in raw) {
    if (!menuItemIsAvailableForDisplay(row)) continue;
    items.add(menuItemFromApiJson(row));
  }
  List<MenuItemModel> filtered =
      items.where((MenuItemModel m) => _itemMatchesTags(m, match.tags)).toList(growable: false);

  if (match.narrowTokens.isNotEmpty) {
    filtered = filtered
        .where((MenuItemModel m) {
          final String blob = _menuBlob(m);
          return match.narrowTokens.every((String tok) => blob.contains(tok));
        })
        .toList(growable: false);
  }

  if (filtered.length <= limit) return filtered;
  return filtered.sublist(0, limit);
}
