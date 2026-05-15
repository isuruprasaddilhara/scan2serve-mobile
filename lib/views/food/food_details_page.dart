import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/models/food/food_details_model.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/viewmodels/food/food_details_view_model.dart';
import 'package:scan2serve/viewmodels/home/home_view_model.dart';
import 'package:scan2serve/views/cart/cart_page.dart';
import 'package:scan2serve/views/chatbot/chatbot_page.dart';
import 'package:scan2serve/views/profile/profile_page.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/cart_summary_pill.dart';
import 'package:scan2serve/widgets/dish_image.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

class FoodDetailsPage extends StatefulWidget {
  const FoodDetailsPage({
    super.key,
    required this.item,
    this.homeViewModel,
  });

  final MenuItemModel item;
  /// When opened from [HomePage], keeps cart count and bottom nav in sync.
  final HomeViewModel? homeViewModel;

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  late final FoodDetailsViewModel _viewModel;
  late final Listenable _listenable;

  @override
  void initState() {
    super.initState();
    _viewModel = FoodDetailsViewModel(
      model: FoodDetailsModel(
        name: widget.item.name,
        description: widget.item.description,
        priceLabel: widget.item.priceLabel,
        menuItemId: widget.item.menuItemId,
        imageUrl: widget.item.imageUrl,
      ),
    );
    _viewModel.syncFavouriteFromApi();
    authAccessToken.addListener(_onAuthChanged);
    _listenable = Listenable.merge([
      _viewModel,
      CartStore.instance,
      if (widget.homeViewModel != null) widget.homeViewModel!,
    ]);
  }

  void _onAuthChanged() {
    _viewModel.syncFavouriteFromApi();
  }

  @override
  void dispose() {
    authAccessToken.removeListener(_onAuthChanged);
    _viewModel.dispose();
    super.dispose();
  }

  bool get _showCartPill => CartStore.instance.hasItems;

  int get _pillItemCount => CartStore.instance.totalQuantity;

  int get _pillTotalRs => CartStore.instance.totalRs;

  String get _activeBottomNav =>
      widget.homeViewModel?.activeBottomNav ?? 'Home';

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartPage()),
    );
  }

  void _openChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChatbotPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleBottomNavTap(String nav) {
    final navigator = Navigator.of(context);
    final home = widget.homeViewModel;
    if (nav == 'Home') {
      navigateToHomeAsRoot(context);
      return;
    }
    if (nav == 'Profile') {
      final String? token = authAccessToken.value?.trim();
      if (token == null || token.isEmpty) {
        return;
      }
    }
    home?.onBottomNavTap(nav);
    navigator.pop();
    if (nav == 'Track') {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const TrackOrderPage()),
      );
    } else if (nav == 'Profile') {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
      );
    }
  }

  void _onAddToCartPressed() {
    final int q = _viewModel.quantity;
    CartStore.instance.addMenuItem(widget.item, q);
    _viewModel.onAddToCart();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _listenable,
      builder: (context, _) {
        final data = _viewModel.viewData;
        final double screenH = MediaQuery.sizeOf(context).height;
        final double imageHeight = (screenH * 0.26).clamp(168.0, 248.0);
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: _FoodDetailsTopBar(
                  title: 'Food Details',
                  onBackTap: () => Navigator.of(context).pop(),
                  trailing: _viewModel.canUseFavourite
                      ? IconButton(
                          onPressed: _viewModel.favouriteBusy
                              ? null
                              : () async {
                                  final err = await _viewModel.toggleFavourite();
                                  if (!context.mounted) return;
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(err),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _viewModel.isFavourite
                                              ? 'Saved to favourites'
                                              : 'Removed from favourites',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                          icon: _viewModel.favouriteBusy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _viewModel.isFavourite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: const Color(0xFF9B77D6),
                                ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: DishImageCover(
                            imageUrl: data.imageUrl,
                            fit: BoxFit.cover,
                            backgroundColor: const Color(0xFFF0ECF7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Color(0xFF2E2440),
                        ),
                      ),
                      if (data.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          data.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        data.priceLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B4AA0),
                        ),
                      ),
                      // Space so scroll content clears the sticky footer on small phones.
                      SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                    ],
                  ),
                ),
              ),
              Material(
                elevation: 8,
                shadowColor: Colors.black26,
                color: AppColors.screenBackground,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5C5468),
                              ),
                            ),
                            const Spacer(),
                            _QuantitySelector(
                              quantity: _viewModel.quantity,
                              onDecrement: _viewModel.decrement,
                              onIncrement: _viewModel.increment,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AddToCartButton(
                          onPressed: _onAddToCartPressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  BottomNavWithChatFab(
                    activeNav: _activeBottomNav,
                    onNavTap: _handleBottomNavTap,
                    onChatTap: _openChatbot,
                  ),
                  if (_showCartPill)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 64 + 2,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: CartSummaryPill(
                          itemCount: _pillItemCount,
                          totalRs: _pillTotalRs,
                          onTap: _openCart,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shorter app bar so more room remains for dish + actions on small screens.
class _FoodDetailsTopBar extends StatelessWidget {
  const _FoodDetailsTopBar({
    required this.title,
    required this.onBackTap,
    this.trailing,
  });

  final String title;
  final VoidCallback onBackTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF4B4360),
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF3A314A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: trailing != null
                ? Align(alignment: Alignment.centerRight, child: trailing!)
                : null,
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.quantityStepperFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.quantityStepperBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove, size: 22, color: AppColors.quantityStepperAccent),
            ),
          ),
          Container(
            width: 44,
            color: AppColors.quantityStepperCenter,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.quantityStepperAccent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add, size: 22, color: AppColors.quantityStepperAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.shopping_cart_outlined, size: 24),
        label: const Text(
          'Add to Cart',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E6FD0),
          foregroundColor: const Color(0xFF1A1520),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
