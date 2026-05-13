import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/models/favourites/favourite_food_item_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/favourites/favourite_foods_view_model.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/dish_image.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _FavUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color heart = Color(0xFF9B77D6);
}

class FavouriteFoodsPage extends StatefulWidget {
  const FavouriteFoodsPage({super.key});

  @override
  State<FavouriteFoodsPage> createState() => _FavouriteFoodsPageState();
}

class _FavouriteFoodsPageState extends State<FavouriteFoodsPage> {
  late final FavouriteFoodsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FavouriteFoodsViewModel();
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
        final List<FavouriteFoodItemModel> items = _viewModel.items;
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FavouriteTopBar(
                  title: FavouriteFoodsViewModel.screenTitle,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _buildBody(context, items),
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

  Widget _buildBody(BuildContext context, List<FavouriteFoodItemModel> items) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _viewModel.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No favourites yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _viewModel.refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final FavouriteFoodItemModel item = items[index];
          return _FavouriteFoodCard(
            item: item,
            onHeartTap: () async {
              try {
                await _viewModel.removeFavouriteById(item.favouriteId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} removed from favourites'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _onBottomNav(BuildContext context, String nav) {
    if (nav == 'Profile') {
      Navigator.of(context).pop();
      return;
    }
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
}

class _FavouriteItemImage extends StatelessWidget {
  const _FavouriteItemImage({required this.item});

  final FavouriteFoodItemModel item;

  @override
  Widget build(BuildContext context) {
    return DishImageBox(
      width: 72,
      height: 72,
      imageUrl: item.imageUrl,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class _FavouriteTopBar extends StatelessWidget {
  const _FavouriteTopBar({
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
                color: _FavUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FavouriteFoodCard extends StatelessWidget {
  const _FavouriteFoodCard({
    required this.item,
    required this.onHeartTap,
  });

  final FavouriteFoodItemModel item;
  final VoidCallback onHeartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _FavouriteItemImage(item: item),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _FavUi.titlePurple,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.priceLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _FavUi.titlePurple,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onHeartTap,
            icon: const Icon(Icons.favorite_rounded),
            color: _FavUi.heart,
            tooltip: 'Remove from favourites',
          ),
        ],
      ),
    );
  }
}
