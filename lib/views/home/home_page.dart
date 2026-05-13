import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/favourites_api.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/session/session_table.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/home/home_view_model.dart';
import 'package:scan2serve/views/cart/cart_page.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/cart_summary_pill.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';
import 'package:scan2serve/views/feedback/feedback_ratings_page.dart';
import 'package:scan2serve/views/food/food_details_page.dart';
import 'package:scan2serve/widgets/dish_image.dart';
import 'package:scan2serve/views/chatbot/chatbot_page.dart';
import 'package:scan2serve/views/login/login_page.dart';
import 'package:scan2serve/views/orders/my_orders_page.dart';
import 'package:scan2serve/views/profile/profile_page.dart';
import 'package:scan2serve/views/settings/settings_page.dart';
import 'package:scan2serve/views/signup/sign_up_page.dart';
import 'package:scan2serve/views/welcome/welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  /// Keyboard / IME toolbar (e.g. Gboard strip) only after user taps search — not on load.
  bool _searchEditing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus &&
        _searchController.text.trim().isEmpty &&
        _searchEditing) {
      setState(() => _searchEditing = false);
    }
  }

  /// Close keyboard when tapping outside search or using another control.
  void _blurSearch() {
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final HomeModel data = _viewModel.viewData;
        final activeTab = _viewModel.activeTab;
        final items = _viewModel.displayedItems;
        final bool searching = _viewModel.searchQuery.trim().isNotEmpty;
        final List<String> tabs = _viewModel.effectiveTabs;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.screenBackground,
          drawer: _HomeDrawer(
            onItemTap: _onDrawerItemTap,
            onLogoutTap: _onLogoutTap,
          ),
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: data.title,
                  onMenuTap: () {
                    _blurSearch();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                if (_viewModel.menuLoading)
                  const LinearProgressIndicator(minHeight: 2),
                if (_viewModel.menuLoadError != null)
                  Material(
                    color: const Color(0xFFFFF3E0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Menu: ${_viewModel.menuLoadError} (showing offline sample)',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _HomeWelcomeBanner(),
                                  const SizedBox(height: 16),
                                  _SearchBar(
                                    hint: data.searchHint,
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    readOnly: !_searchEditing,
                                    onTapActivate: () {
                                      if (!_searchEditing) {
                                        setState(() => _searchEditing = true);
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            _searchFocusNode.requestFocus();
                                          }
                                        });
                                      }
                                    },
                                    onChanged: _viewModel.setSearchQuery,
                                    onClear: () {
                                      _searchController.clear();
                                      _viewModel.clearSearch();
                                      _blurSearch();
                                      setState(() => _searchEditing = false);
                                    },
                                    onDismissKeyboard: _blurSearch,
                                    showClear: searching,
                                  ),
                                  const SizedBox(height: 20),
                                  _TabStrip(
                                    tabs: tabs,
                                    activeTab: activeTab,
                                    onTabTap: (tab) {
                                      _blurSearch();
                                      _viewModel.onTabSelected(tab);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searching
                                        ? 'Search results (${items.length})'
                                        : activeTab,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2B2238),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 190),
                            sliver: items.isEmpty
                                ? SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 40,
                                      ),
                                      child: Center(
                                        child: Text(
                                          searching
                                              ? 'No dishes match your search'
                                              : 'No items in this category',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final MenuItemModel item =
                                            items[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: _MenuItemCard(
                                            key: ValueKey(item.menuItemId ?? item.name),
                                            item: item,
                                            onTapFood: () =>
                                                _openFoodDetails(item),
                                            onAddTap: () {
                                              _blurSearch();
                                              _viewModel.onAddItemTap(item);
                                            },
                                          ),
                                        );
                                      },
                                      childCount: items.length,
                                    ),
                                  ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            BottomNavWithChatFab(
                              activeNav: _viewModel.activeBottomNav,
                              onNavTap: _handleBottomNavTap,
                              onChatTap: _openChatbot,
                            ),
                            if (_viewModel.showCartSummary)
                              Positioned(
                                left: 0,
                                right: 0,
                                // Flush to nav strip: [BottomNavWithChatFab] reserves space above
                                // the 64px bar for the chat FAB; keep pill above the bar only.
                                bottom: 64 + 2,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CartSummaryPill(
                                    itemCount: _viewModel.cartItemCount,
                                    totalRs: _viewModel.cartTotalRs,
                                    onTap: _openCart,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBottomNavTap(String nav) {
    _blurSearch();
    _viewModel.onBottomNavTap(nav);
    if (nav == 'Home') {
      return;
    }
    if (nav == 'Track') {
      _openTrackOrder();
      return;
    }
    if (nav == 'Profile') {
      final String? token = authAccessToken.value?.trim();
      if (token == null || token.isEmpty) {
        return;
      }
      _openProfile();
      return;
    }
  }

  void _openFoodDetails(MenuItemModel item) {
    _blurSearch();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodDetailsPage(item: item, homeViewModel: _viewModel),
      ),
    );
  }

  void _onDrawerItemTap(String id) {
    _blurSearch();
    Navigator.of(context).pop();
    _viewModel.onAppBarMenuItemTap(id);
    if (id == 'cart') {
      _openCart();
      return;
    }
    if (id == 'order_track') {
      _openTrackOrder();
      return;
    }
    if (id == 'chatbot') {
      _openChatbot();
      return;
    }
    if (id == 'my_orders') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MyOrdersPage()),
      );
      return;
    }
    if (id == 'feedback') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const FeedbackRatingsPage()),
      );
      return;
    }
    if (id == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
      );
      return;
    }
    if (id == 'profile') {
      _openProfile();
      return;
    }
    if (id == 'drawer_login') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (id == 'drawer_sign_up') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SignUpPage()),
      );
      return;
    }
    final String message = switch (id) {
      'home' => 'Home',
      'profile' => 'Profile',
      'cart' => 'Cart',
      'order_track' => 'Order Track',
      'chatbot' => 'Chatbot',
      'my_orders' => 'My Orders',
      'feedback' => 'Feedback',
      'settings' => 'Settings',
      _ => id,
    };
    if (id != 'home') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message — UI only (connect screen later)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCart() {
    _blurSearch();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartPage()),
    );
  }

  void _openTrackOrder() {
    _blurSearch();
    final int? oid = activeTrackOrderId.value;
    final String? guest = activeTrackGuestToken.value;
    final Widget page = oid != null
        ? TrackOrderPage(orderId: oid, guestToken: guest)
        : const TrackOrderPage();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _openChatbot() {
    _blurSearch();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChatbotPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openProfile() {
    _blurSearch();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
    );
  }

  void _onLogoutTap() {
    _blurSearch();
    Navigator.of(context).pop();
    _viewModel.onLogoutTap();
    CartStore.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }
}

abstract final class _WelcomeBannerPalette {
  static const Color titleDark = Color(0xFF2B2238);
  static const Color muted = Color(0xFF8B8499);
  static const Color accentPurple = Color(0xFF9B77D6);
  static const Color iconTileBg = Color(0xFFF0E8FA);
}

/// Welcome card: signed-in name from API, else "Guest"; table from [sessionTableCode].
class _HomeWelcomeBanner extends StatefulWidget {
  const _HomeWelcomeBanner();

  @override
  State<_HomeWelcomeBanner> createState() => _HomeWelcomeBannerState();
}

class _HomeWelcomeBannerState extends State<_HomeWelcomeBanner> {
  String? _resolvedName;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    authAccessToken.addListener(_onAuthOrTableChanged);
    sessionTableCode.addListener(_onAuthOrTableChanged);
    _refreshNameFromApi();
  }

  @override
  void dispose() {
    authAccessToken.removeListener(_onAuthOrTableChanged);
    sessionTableCode.removeListener(_onAuthOrTableChanged);
    super.dispose();
  }

  void _onAuthOrTableChanged() {
    _refreshNameFromApi();
    setState(() {});
  }

  Future<void> _refreshNameFromApi() async {
    final String? tokenSnapshot = authAccessToken.value?.trim();
    if (tokenSnapshot == null || tokenSnapshot.isEmpty) {
      if (mounted) {
        setState(() {
          _resolvedName = null;
          _loadingProfile = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _resolvedName = null;
        _loadingProfile = true;
      });
    }
    try {
      final Map<String, dynamic> me = await fetchCustomerMe();
      if (!mounted || authAccessToken.value?.trim() != tokenSnapshot) return;
      String name = (me['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        name = (me['first_name'] as String?)?.trim() ?? '';
      }
      if (name.isEmpty) {
        final String email = (me['email'] as String?)?.trim() ?? '';
        if (email.contains('@')) {
          name = email.split('@').first;
        }
      }
      setState(() {
        _resolvedName = name.isEmpty ? null : name;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted || authAccessToken.value?.trim() != tokenSnapshot) return;
      setState(() {
        _resolvedName = null;
        _loadingProfile = false;
      });
    }
  }

  String get _greetingName {
    final String? token = authAccessToken.value?.trim();
    if (token == null || token.isEmpty) return 'Guest';
    if (_loadingProfile) return '…';
    final String? n = _resolvedName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Customer';
  }

  String get _tableLabel {
    final String? raw = sessionTableCode.value?.trim();
    if (raw == null || raw.isEmpty) return '—';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _WelcomeBannerPalette.iconTileBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person,
              size: 28,
              color: _WelcomeBannerPalette.accentPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _WelcomeBannerPalette.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _greetingName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _WelcomeBannerPalette.titleDark,
                        ),
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _WelcomeBannerPalette.accentPurple,
                      ),
                    ),
                    Text(
                      _tableLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _WelcomeBannerPalette.accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan, order and enjoy your meal.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: _WelcomeBannerPalette.muted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.onItemTap,
    required this.onLogoutTap,
  });

  final void Function(String id) onItemTap;
  final VoidCallback onLogoutTap;

  static const Color _text = Color(0xFF3A314A);
  static const Color _icon = Color(0xFF4B4360);

  static bool _isSignedIn(String? token) =>
      token != null && token.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.screenBackground,
      child: SafeArea(
        child: ValueListenableBuilder<String?>(
          valueListenable: authAccessToken,
          builder: (context, token, _) {
            final signedIn = _isSignedIn(token);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.appBarBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/scan2serve_logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _DrawerTile(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () => onItemTap('home'),
                ),
                if (signedIn)
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () => onItemTap('profile'),
                  ),
                _DrawerTile(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Cart',
                  onTap: () => onItemTap('cart'),
                ),
                _DrawerTile(
                  icon: Icons.track_changes_outlined,
                  label: 'Track Order',
                  onTap: () => onItemTap('order_track'),
                ),
                _DrawerTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chatbot',
                  onTap: () => onItemTap('chatbot'),
                ),
                if (signedIn)
                  _DrawerTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Orders',
                    onTap: () => onItemTap('my_orders'),
                  ),
                _DrawerTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Feedback & Ratings',
                  onTap: () => onItemTap('feedback'),
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => onItemTap('settings'),
                ),
                const Spacer(),
                if (signedIn) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onLogoutTap,
                        icon: const Icon(Icons.logout_rounded, fontWeight: FontWeight.w800, size: 24),
                        label: const Text('Log out'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Browsing as a guest',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _text.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => onItemTap('drawer_login'),
                            icon: const Icon(Icons.login_rounded, size: 22),
                            label: const Text('Log in'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF9B77D6),
                              foregroundColor: const Color(0xFF1A1520),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => onItemTap('drawer_sign_up'),
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B4AA0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _HomeDrawer._icon, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _HomeDrawer._text,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onMenuTap});

  final String title;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu, size: 28, color: Color(0xFF4B4360)),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32 * 0.78,
                color: Color(0xFF3A314A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/scan2serve_logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
    required this.onTapActivate,
    required this.onChanged,
    required this.onClear,
    required this.onDismissKeyboard,
    required this.showClear,
  });

  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final VoidCallback onTapActivate;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onDismissKeyboard;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1DAED)),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        showCursor: !readOnly,
        enableInteractiveSelection: !readOnly,
        onTap: onTapActivate,
        onTapOutside: (_) => onDismissKeyboard(),
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1B1722),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF2E2A36),
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 40,
          ),
          suffixIcon: showClear
              ? IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade700),
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.tabs,
    required this.activeTab,
    required this.onTabTap,
  });

  final List<String> tabs;
  final String activeTab;
  final ValueChanged<String> onTabTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: InkWell(
                  onTap: () => onTabTap(tab),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab,
                        style: TextStyle(
                          fontSize: 31 * 0.46,
                          fontWeight: tab == activeTab
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: tab == activeTab
                              ? const Color(0xFF3C2E52)
                              : const Color(0xFF8C819D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 3,
                        width: tab == activeTab ? 42 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B77D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  const _MenuItemCard({
    required this.item,
    required this.onAddTap,
    this.onTapFood,
  });

  final MenuItemModel item;
  final VoidCallback onAddTap;
  final VoidCallback? onTapFood;

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _favBusy = false;
  bool _isFavourite = false;
  int? _favouriteRowId;

  MenuItemModel get item => widget.item;

  @override
  void initState() {
    super.initState();
    authAccessToken.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFavourite());
  }

  @override
  void dispose() {
    authAccessToken.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _syncFavourite();
  }

  Future<void> _syncFavourite() async {
    final mid = item.menuItemId;
    if (mid == null) return;
    if (authAccessToken.value == null || authAccessToken.value!.isEmpty) {
      if (mounted) {
        setState(() {
          _isFavourite = false;
          _favouriteRowId = null;
        });
      }
      return;
    }
    try {
      final list = await fetchFavourites();
      int? rowId;
      var fav = false;
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        int? itemId;
        final dynamic rm = m['menu_item'];
        if (rm is int) {
          itemId = rm;
        } else if (rm is Map<String, dynamic>) {
          itemId = rm['id'] as int?;
        }
        final detail = m['menu_item_detail'] as Map<String, dynamic>?;
        itemId = detail?['id'] as int? ?? itemId;
        if (itemId == mid) {
          rowId = m['id'] as int?;
          fav = true;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _favouriteRowId = rowId;
          _isFavourite = fav;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFavourite = false;
          _favouriteRowId = null;
        });
      }
    }
  }

  Future<void> _onHeartTap(BuildContext context) async {
    final mid = item.menuItemId;
    if (mid == null) return;
    if (authAccessToken.value == null || authAccessToken.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save favourites.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_favBusy) return;
    setState(() => _favBusy = true);
    try {
      if (_isFavourite && _favouriteRowId != null) {
        await removeFavourite(_favouriteRowId!);
        _isFavourite = false;
        _favouriteRowId = null;
      } else {
        final row = await addFavourite(mid);
        _favouriteRowId = row['id'] as int?;
        _isFavourite = true;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavourite ? 'Saved to favourites' : 'Removed from favourites',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeart = item.menuItemId != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F78B1).withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (showHeart) ...[
            SizedBox(
              width: 40,
              child: _favBusy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: () => _onHeartTap(context),
                      icon: Icon(
                        _isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: const Color(0xFF9B77D6),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: InkWell(
              onTap: widget.onTapFood,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 31 * 0.66,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3C2E52),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      fontSize: 22 * 0.66,
                      color: Color(0xFF3E3350),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 21 * 0.6,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D3550),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              DishImageBox(
                width: 96,
                height: 58,
                imageUrl: item.imageUrl,
                borderRadius: BorderRadius.circular(30),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: InkWell(
                  onTap: widget.onAddTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

