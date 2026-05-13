import 'package:flutter/material.dart';
import 'package:scan2serve/models/cart/cart_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/cart/cart_view_model.dart';
import 'package:scan2serve/views/checkout/checkout_page.dart';

/// Soft tokens for a clean cart layout (reference UI).
abstract final class _CartTheme {
  static const Color titleText = Color(0xFF2D2438);
  static const Color bodyMuted = Color(0xFF8B8499);
  static const LinearGradient checkoutGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFC9B6EC),
      Color(0xFF8E6FD0),
    ],
  );
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CartViewModel();
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
        final CartScreenModel data = _viewModel.viewData;
        final List<CartItemModel> items = _viewModel.items;
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _CartTopBar(
                  title: data.title,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Your cart is empty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: _CartTheme.bodyMuted.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final CartItemModel item = items[index];
                            return _CartItemCard(
                              item: item,
                              onIncrement: () =>
                                  _viewModel.incrementQuantity(item.id),
                              onDecrement: () =>
                                  _viewModel.decrementQuantity(item.id),
                            );
                          },
                        ),
                ),
                _CartBottomPanel(
                  totalLabel: data.totalLabel,
                  totalValue: _viewModel.formattedTotal,
                  checkoutLabel: data.checkoutLabel,
                  checkoutEnabled: items.isNotEmpty,
                  onCheckout: () {
                    if (items.isEmpty) return;
                    _viewModel.onCheckoutTap();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CheckoutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartTopBar extends StatelessWidget {
  const _CartTopBar({
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF5C5470),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: -0.2,
                color: _CartTheme.titleText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: _CartTheme.titleText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.unitPriceLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3D3550),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.lineTotalLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: _CartTheme.titleText,
                ),
              ),
              const SizedBox(height: 14),
              _CartQuantityPill(
                quantity: item.quantity,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartQuantityPill extends StatelessWidget {
  const _CartQuantityPill({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      width: 138,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(color: AppColors.quantityStepperBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _QtyStepperSide(
              color: AppColors.quantityStepperFill,
              icon: Icons.remove_rounded,
              onTap: onDecrement,
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.quantityStepperCenter,
              child: Center(
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: AppColors.quantityStepperAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _QtyStepperSide(
              color: AppColors.quantityStepperFill,
              icon: Icons.add_rounded,
              onTap: onIncrement,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepperSide extends StatelessWidget {
  const _QtyStepperSide({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.quantityStepperAccent.withValues(alpha: 0.12),
        highlightColor: AppColors.quantityStepperAccent.withValues(alpha: 0.08),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: AppColors.quantityStepperAccent,
          ),
        ),
      ),
    );
  }
}

class _CartBottomPanel extends StatelessWidget {
  const _CartBottomPanel({
    required this.totalLabel,
    required this.totalValue,
    required this.checkoutLabel,
    required this.checkoutEnabled,
    required this.onCheckout,
  });

  final String totalLabel;
  final String totalValue;
  final String checkoutLabel;
  final bool checkoutEnabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.appBarBackground,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD9D0E8).withValues(alpha: 0.75),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFD9D0E8).withValues(alpha: 0.85),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: _CartTheme.titleText,
                ),
              ),
              Text(
                totalValue,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: _CartTheme.titleText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GradientCheckoutButton(
            label: checkoutLabel,
            enabled: checkoutEnabled,
            onPressed: onCheckout,
          ),
        ],
      ),
    );
  }
}

class _GradientCheckoutButton extends StatelessWidget {
  const _GradientCheckoutButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: enabled ? _CartTheme.checkoutGradient : null,
            color: enabled ? null : const Color(0xFFE3DDEE),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: enabled ? const Color(0xFF1A1520) : const Color(0xFFADA3BC),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
