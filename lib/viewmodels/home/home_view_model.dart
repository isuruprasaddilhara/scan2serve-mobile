import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/menu_api.dart';
import 'package:scan2serve/formatting/rs_money.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/services/cart_store.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    _resetToFallback();
    loadMenuFromApi();
    CartStore.instance.addListener(_onCartStoreChanged);
  }

  void _onCartStoreChanged() => notifyListeners();

  final HomeModel viewData = const HomeModel(
    title: 'Scan2Serve',
    searchHint: 'Search',
    tabs: [
      'Previous Orders',
      'Starters',
      'Main Course',
      'Desserts',
      'Beverages',
      'Seafood',
      'Meat',
      'Vegetarian',
      'Salads',
      'Grilled',
    ],
    cartSummary: '',
  );

  /// Shown in the tab strip: API categories when loaded, else [viewData.tabs].
  List<String> get effectiveTabs => _apiTabs ?? viewData.tabs;

  bool menuLoading = false;
  String? menuLoadError;

  String _activeTab = 'Previous Orders';
  String _activeBottomNav = 'Home';
  String _searchQuery = '';

  List<String>? _apiTabs;
  final Map<String, List<MenuItemModel>> _categoryItems = {};

  static final Map<String, List<MenuItemModel>> _fallbackMenu = {
    'Previous Orders': const [
      MenuItemModel(
        name: 'Egg Fried Rice',
        priceLabel: 'Rs 1200',
        description: 'Delicious fried rice with egg',
      ),
      MenuItemModel(
        name: 'Fish Fried Rice',
        priceLabel: 'Rs 1600',
        description: 'Delicious fried rice with fish',
      ),
      MenuItemModel(
        name: 'Chicken Fried Rice',
        priceLabel: 'Rs 1600',
        description: 'Delicious fried rice with chicken',
      ),
    ],
    'Starters': const [
      MenuItemModel(
        name: 'Crispy Spring Rolls',
        priceLabel: 'Rs 900',
        description: 'Vegetable rolls with sweet chili sauce',
      ),
      MenuItemModel(
        name: 'Chicken Wings',
        priceLabel: 'Rs 1300',
        description: 'Crispy wings tossed in spicy glaze',
      ),
    ],
    'Main Course': const [
      MenuItemModel(
        name: 'Chicken Kottu',
        priceLabel: 'Rs 1500',
        description: 'Street-style kottu with vegetables',
      ),
      MenuItemModel(
        name: 'Seafood Nasi Goreng',
        priceLabel: 'Rs 1900',
        description: 'Wok-fried rice with prawns and squid',
      ),
    ],
    'Desserts': const [
      MenuItemModel(
        name: 'Chocolate Brownie',
        priceLabel: 'Rs 700',
        description: 'Warm brownie with chocolate sauce',
      ),
      MenuItemModel(
        name: 'Fruit Trifle',
        priceLabel: 'Rs 650',
        description: 'Fresh fruits layered with cream',
      ),
    ],
    'Beverages': const [
      MenuItemModel(
        name: 'Lime Mint Cooler',
        priceLabel: 'Rs 500',
        description: 'Refreshing mint and lime drink',
      ),
      MenuItemModel(
        name: 'Iced Coffee',
        priceLabel: 'Rs 600',
        description: 'Cold coffee with milk foam',
      ),
    ],
    'Seafood': const [
      MenuItemModel(
        name: 'Butter Garlic Prawns',
        priceLabel: 'Rs 2100',
        description: 'Pan-seared prawns in garlic butter',
      ),
      MenuItemModel(
        name: 'Grilled Seer Fish',
        priceLabel: 'Rs 2300',
        description: 'Char-grilled fish with lemon herb',
      ),
    ],
    'Meat': const [
      MenuItemModel(
        name: 'Beef Pepper Steak',
        priceLabel: 'Rs 2400',
        description: 'Tender beef in black pepper sauce',
      ),
      MenuItemModel(
        name: 'Mutton Curry',
        priceLabel: 'Rs 2200',
        description: 'Slow-cooked mutton with spices',
      ),
    ],
    'Vegetarian': const [
      MenuItemModel(
        name: 'Paneer Butter Masala',
        priceLabel: 'Rs 1400',
        description: 'Paneer cubes in creamy tomato gravy',
      ),
      MenuItemModel(
        name: 'Veg Fried Noodles',
        priceLabel: 'Rs 1100',
        description: 'Stir-fried noodles with garden veggies',
      ),
    ],
    'Salads': const [
      MenuItemModel(
        name: 'Caesar Salad',
        priceLabel: 'Rs 950',
        description: 'Crisp lettuce with creamy dressing',
      ),
      MenuItemModel(
        name: 'Greek Salad',
        priceLabel: 'Rs 980',
        description: 'Fresh olives, feta, and tomatoes',
      ),
    ],
    'Grilled': const [
      MenuItemModel(
        name: 'Grilled Chicken Breast',
        priceLabel: 'Rs 1700',
        description: 'Juicy chicken with herb seasoning',
      ),
      MenuItemModel(
        name: 'Mixed Grill Platter',
        priceLabel: 'Rs 2600',
        description: 'Assorted grilled meats and sides',
      ),
    ],
  };

  void _resetToFallback() {
    _apiTabs = null;
    _categoryItems.clear();
    for (final e in _fallbackMenu.entries) {
      _categoryItems[e.key] = List<MenuItemModel>.from(e.value);
    }
    _activeTab = effectiveTabs.isNotEmpty ? effectiveTabs.first : 'Previous Orders';
  }

  /// Loads `/menu/categories/` + `/menu/items/` and replaces tabs when data exists.
  Future<void> loadMenuFromApi() async {
    menuLoadError = null;
    menuLoading = true;
    notifyListeners();
    try {
      final categories = await fetchMenuCategories();
      final items = await fetchMenuItems();

      final idToName = <int, String>{};
      for (final c in categories) {
        final id = c['id'] as int?;
        final name = c['name'] as String?;
        if (id != null && name != null) {
          idToName[id] = name;
        }
      }

      final grouped = <String, List<MenuItemModel>>{};
      for (final raw in items) {
        if (raw['availability'] == false) continue;
        final catId = raw['category'] as int?;
        final tab = idToName[catId] ?? 'Other';
        grouped.putIfAbsent(tab, () => []).add(menuItemFromApiJson(raw));
      }

      if (grouped.isEmpty) {
        menuLoading = false;
        notifyListeners();
        return;
      }

      final tabOrder = <String>[];
      for (final c in categories) {
        final name = c['name'] as String?;
        if (name != null && grouped.containsKey(name)) {
          tabOrder.add(name);
        }
      }
      for (final k in grouped.keys) {
        if (!tabOrder.contains(k)) {
          tabOrder.add(k);
        }
      }

      _categoryItems
        ..clear()
        ..addAll(grouped);
      _apiTabs = tabOrder;

      if (!_apiTabs!.contains(_activeTab)) {
        _activeTab = _apiTabs!.first;
      }
    } catch (e) {
      menuLoadError = e.toString();
      _resetToFallback();
    } finally {
      menuLoading = false;
      notifyListeners();
    }
  }

  String get activeTab => _activeTab;
  List<MenuItemModel> get activeItems => _categoryItems[_activeTab] ?? const [];
  String get searchQuery => _searchQuery;

  List<MenuItemModel> get displayedItems {
    final String q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return List<MenuItemModel>.from(activeItems);
    }
    final List<MenuItemModel> out = <MenuItemModel>[];
    for (final List<MenuItemModel> list in _categoryItems.values) {
      for (final MenuItemModel item in list) {
        if (_menuItemMatchesQuery(item, q)) {
          out.add(item);
        }
      }
    }
    return out;
  }

  bool _menuItemMatchesQuery(MenuItemModel item, String q) {
    if (item.name.toLowerCase().contains(q)) return true;
    if (item.description.toLowerCase().contains(q)) return true;
    if (item.priceLabel.toLowerCase().contains(q)) return true;
    final String digitsQuery = q.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsQuery.isNotEmpty) {
      final String digitsPrice =
          item.priceLabel.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsPrice.contains(digitsQuery)) return true;
    }
    return false;
  }

  String get activeBottomNav => _activeBottomNav;
  bool get showCartSummary => CartStore.instance.hasItems;
  int get cartItemCount => CartStore.instance.totalQuantity;
  int get cartTotalRs => CartStore.instance.totalRs;
  String get cartSummaryText =>
      '$cartItemCount Item${cartItemCount == 1 ? '' : 's'} Selected';
  String get cartTotalFormatted =>
      formatRsDisplay(CartStore.instance.totalRs);

  void onMenuTap() {
    debugPrint('Menu tapped');
  }

  void onAppBarMenuItemTap(String id) {
    debugPrint('App bar menu item: $id');
  }

  void onLogoutTap() {
    clearAuthTokens();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  void onAddItemTap(MenuItemModel item, {int quantity = 1}) {
    debugPrint('Add item tapped: ${item.name} x$quantity');
    CartStore.instance.addMenuItem(item, quantity);
  }

  void onBottomNavTap(String nav) {
    if (_activeBottomNav == nav) return;
    _activeBottomNav = nav;
    notifyListeners();
  }

  void onTabSelected(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCartStoreChanged);
    super.dispose();
  }
}
