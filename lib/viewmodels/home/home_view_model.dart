import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/menu_api.dart';
import 'package:scan2serve/formatting/rs_money.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/services/cart_store.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    _clearMenuState();
    loadMenuFromApi();
    CartStore.instance.addListener(_onCartStoreChanged);
  }

  void _onCartStoreChanged() => notifyListeners();

  bool _menuRefreshInFlight = false;

  final HomeModel viewData = const HomeModel(
    title: 'Scan2Serve',
    searchHint: 'Search',
    tabs: <String>[],
    cartSummary: '',
  );

  /// Category chips: only real API category names after a successful load.
  List<String> get effectiveTabs => _apiTabs ?? const <String>[];

  bool menuLoading = false;
  String? menuLoadError;

  String _activeTab = '';
  String _activeBottomNav = 'Home';
  String _searchQuery = '';

  List<String>? _apiTabs;
  final Map<String, List<MenuItemModel>> _categoryItems = {};

  void _clearMenuState() {
    _apiTabs = null;
    _categoryItems.clear();
    _activeTab = '';
  }

  /// Refetches categories + items from the API.
  ///
  /// [silent]: no top loading bar; on failure keeps the previous menu and does not clear the UI.
  Future<void> loadMenuFromApi({bool silent = false}) async {
    if (_menuRefreshInFlight) return;
    _menuRefreshInFlight = true;
    if (!silent) {
      menuLoadError = null;
      menuLoading = true;
      notifyListeners();
    }
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
        if (!menuItemIsAvailableForDisplay(raw)) continue;
        final catId = raw['category'] as int?;
        final tab = idToName[catId] ?? 'Other';
        grouped.putIfAbsent(tab, () => []).add(menuItemFromApiJson(raw));
      }

      if (grouped.isEmpty) {
        _categoryItems.clear();
        _apiTabs = null;
        _activeTab = '';
        menuLoadError = null;
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
      menuLoadError = null;
    } catch (e) {
      if (silent) {
        debugPrint('Silent menu refresh failed: $e');
      } else {
        menuLoadError = e.toString();
        _clearMenuState();
      }
    } finally {
      if (!silent) {
        menuLoading = false;
      }
      _menuRefreshInFlight = false;
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
