import 'package:flutter/material.dart';
import 'package:scan2serve/api/favourites_api.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/models/favourites/favourite_food_item_model.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/models/profile/profile_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/profile/profile_view_model.dart';
import 'package:scan2serve/views/favourites/favourite_foods_page.dart';
import 'package:scan2serve/views/feedback/feedback_ratings_page.dart';
import 'package:scan2serve/views/orders/my_orders_page.dart';
import 'package:scan2serve/views/profile/personal_information_page.dart';
import 'package:scan2serve/views/settings/settings_page.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/views/welcome/welcome_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _ProfileUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color iconTileBg = Color(0xFFEDE4FA);
}

int _orderLineQuantity(dynamic raw) {
  if (raw == null) return 1;
  if (raw is int) {
    return raw < 1 ? 1 : raw;
  }
  if (raw is num) {
    final int q = raw.toInt();
    return q < 1 ? 1 : q;
  }
  final int? p = int.tryParse('$raw'.trim());
  return (p == null || p < 1) ? 1 : p;
}

/// Picks the [menu_item_name] with the highest total quantity across all order `items`.
String? _guessMostOrderedDish(List<MyOrderModel> orders) {
  final Map<String, int> totals = <String, int>{};
  for (final MyOrderModel o in orders) {
    final List<Map<String, dynamic>>? rows = o.itemRows;
    if (rows == null) continue;
    for (final Map<String, dynamic> m in rows) {
      final String name = (m['menu_item_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      final int q = _orderLineQuantity(m['quantity']);
      totals[name] = (totals[name] ?? 0) + q;
    }
  }
  if (totals.isEmpty) return null;
  String bestName = totals.keys.first;
  int bestTotal = totals[bestName]!;
  for (final MapEntry<String, int> e in totals.entries) {
    if (e.value > bestTotal ||
        (e.value == bestTotal && e.key.compareTo(bestName) < 0)) {
      bestName = e.key;
      bestTotal = e.value;
    }
  }
  return bestName;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileViewModel _viewModel;
  Map<String, dynamic>? _apiProfile;
  int? _ordersCountFromApi;
  /// From order history (most ordered) or first saved favourite; no demo fallback.
  String? _favouriteSubtitleFromApi;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomerProfile());
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final Map<String, dynamic> me = await fetchCustomerMe();
      List<MyOrderModel> orders = <MyOrderModel>[];
      try {
        orders = await fetchMyOrdersList();
      } catch (_) {
        orders = <MyOrderModel>[];
      }

      String? favSubtitle = _guessMostOrderedDish(orders);
      if (favSubtitle == null || favSubtitle.isEmpty) {
        try {
          final List<dynamic> favList = await fetchFavourites();
          for (final dynamic raw in favList) {
            if (raw is! Map<String, dynamic>) continue;
            final FavouriteFoodItemModel? it =
                FavouriteFoodItemModel.tryFromApiJson(raw);
            final String n = it?.name.trim() ?? '';
            if (it != null && n.isNotEmpty) {
              favSubtitle = n;
              break;
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _apiProfile = me;
        _ordersCountFromApi = orders.length;
        _favouriteSubtitleFromApi = favSubtitle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiProfile = null;
        _ordersCountFromApi = null;
        _favouriteSubtitleFromApi = null;
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final ProfileModel data = _viewModel.viewData;
        final String displayName =
            _apiProfile?['name'] as String? ?? data.userName;
        final String displayEmail =
            _apiProfile?['email'] as String? ?? data.email;
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileTopBar(
                  title: data.title,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _UserHeaderCard(
                          name: displayName,
                          email: displayEmail,
                          editLabel: data.editProfileLabel,
                          onEdit: () {
                            _viewModel.onEditProfileTap();
                            Navigator.of(context)
                                .push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const PersonalInformationPage(),
                              ),
                            )
                                .then((_) {
                              if (mounted) _loadCustomerProfile();
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        _StatsRow(
                          orders: _apiProfile != null
                              ? (_ordersCountFromApi ?? 0)
                              : data.ordersCount,
                          favourite: _apiProfile != null
                              ? (_favouriteSubtitleFromApi ?? 'None yet')
                              : data.favouriteFood,
                        ),
                        const SizedBox(height: 20),
                        _MenuCard(
                          rows: data.menuRows,
                          onRowTap: (id) => _onMenuRow(context, id),
                        ),
                        const SizedBox(height: 16),
                        _LogoutButton(
                          label: data.logoutLabel,
                          onTap: () => _confirmLogout(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                ScanBottomNavBar(
                  activeNav: 'Profile',
                  onNavTap: (nav) => _onBottomNav(context, nav),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBottomNav(BuildContext context, String nav) {
    if (nav == 'Profile') return;
    if (nav == 'Home') {
      navigateToHomeAsRoot(context);
      return;
    }
    if (nav == 'Track') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TrackOrderPage()),
      );
    }
  }

  void _onMenuRow(BuildContext context, String id) {
    _viewModel.onMenuRowTap(id);
    if (id == 'track_order') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TrackOrderPage()),
      );
      return;
    }
    if (id == 'my_orders') {
      Navigator.of(context)
          .push<void>(
        MaterialPageRoute<void>(builder: (_) => const MyOrdersPage()),
      )
          .then((_) {
        if (mounted) _loadCustomerProfile();
      });
      return;
    }
    if (id == 'favourite_foods') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const FavouriteFoodsPage()),
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
  }

  void _confirmLogout(BuildContext context) {
    _viewModel.onLogoutTap();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: const Color(0xFF4B4360),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ProfileUi.titlePurple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD9CCE8)),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/scan2serve_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserHeaderCard extends StatelessWidget {
  const _UserHeaderCard({
    required this.name,
    required this.email,
    required this.editLabel,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFE8DFF5),
            child: Icon(
              Icons.person_rounded,
              size: 44,
              color: Colors.purple.shade300,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ProfileUi.titlePurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _ProfileUi.titlePurple,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18, color: Colors.purple.shade400),
                  label: Text(
                    editLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade500,
                    side: BorderSide(color: Colors.purple.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.orders,
    required this.favourite,
  });

  final int orders;
  final String favourite;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.shopping_bag_outlined,
              value: '$orders',
              label: 'Orders',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_outline,
              value: null,
              label: 'Favourite:',
              subtitle: favourite,
              favouriteLayout: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
    this.favouriteLayout = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final bool favouriteLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: const Color(0xFF9B77D6)),
          if (favouriteLayout && subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ProfileUi.titlePurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ProfileUi.titlePurple,
                height: 1.2,
              ),
            ),
          ] else ...[
            if (value != null) ...[
              const SizedBox(height: 8),
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ProfileUi.titlePurple,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ProfileUi.titlePurple,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.rows,
    required this.onRowTap,
  });

  final List<ProfileMenuRowModel> rows;
  final void Function(String id) onRowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            InkWell(
              onTap: () => onRowTap(rows[i].id),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(18) : Radius.zero,
                bottom: i == rows.length - 1 ? const Radius.circular(18) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _ProfileUi.iconTileBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        rows[i].icon,
                        color: const Color(0xFF8B6FC4),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        rows[i].label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A314A),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD32F2F),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.white, fontWeight: FontWeight.w800, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
