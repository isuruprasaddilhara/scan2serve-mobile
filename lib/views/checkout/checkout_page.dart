import 'package:flutter/material.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/models/cart/cart_model.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/session/session_table.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/widgets/dish_image.dart';
import 'package:scan2serve/viewmodels/checkout/checkout_view_model.dart';
import 'package:scan2serve/views/home/home_page.dart';

abstract final class _CheckoutUi {
  static const Color titleDark = Color(0xFF1A1520);
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color accentPurple = Color(0xFF9B77D6);
  static const Color muted = Color(0xFF8B8499);
  static const Color infoCardBg = Color(0xFFEDE4FA);
  static const Color discountGreen = Color(0xFF2E7D4A);
  static const LinearGradient confirmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC9B6EC), Color(0xFF8E6FD0)],
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutViewModel _viewModel;
  late final TextEditingController _notesController;
  static const int _notesMax = 120;

  @override
  void initState() {
    super.initState();
    _viewModel = CheckoutViewModel();
    _notesController = TextEditingController();
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CheckoutTopBar(
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    children: [
                      const _OrderInfoRow(),
                      const SizedBox(height: 18),
                      _YourOrderSection(
                        items: _viewModel.items,
                        onEditCart: () => Navigator.of(context).pop(),
                        onIncrement: _viewModel.incrementQuantity,
                        onDecrement: _viewModel.decrementQuantity,
                        onRemove: _viewModel.removeItem,
                      ),
                      const SizedBox(height: 18),
                      _SpecialInstructionsField(
                        controller: _notesController,
                        maxLength: _notesMax,
                        lengthUsed: _notesController.text.length,
                      ),
                      const SizedBox(height: 18),
                      _BillSummaryBlock(
                        subtotal: _viewModel.subtotalRs,
                        service: _viewModel.serviceChargeRs,
                        tax: _viewModel.taxRs,
                        discount: _viewModel.appliedDiscountRs,
                        total: _viewModel.totalRs,
                      ),
                      SizedBox(
                        height: 12 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                ),
                _ConfirmOrderFooter(
                  enabled: !_viewModel.isEmpty && !_viewModel.isSubmitting,
                  isSubmitting: _viewModel.isSubmitting,
                  onConfirm: () => _onConfirmOrder(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onConfirmOrder(BuildContext context) async {
    if (_viewModel.isEmpty || _viewModel.isSubmitting) return;
    final CreateOrderResult result;
    try {
      result = await _viewModel.submitOrder(_notesController.text);
    } on CheckoutSubmissionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
      return;
    } on OrdersApiException catch (e) {
      if (!context.mounted) return;
      final String msg =
          parseOrdersErrorMessage(e.body) ?? 'Could not place order (${e.statusCode}).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not place order: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    final bool? goHome = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: Color(0xFF2EAF4A),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Order Confirmed!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _CheckoutUi.titlePurple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order #${result.orderId} has been sent to the kitchen.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _CheckoutUi.muted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _CheckoutUi.accentPurple,
                    foregroundColor: const Color(0xFF1A1520),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    setActiveTrackOrderSession(result.orderId, guestToken: result.guestToken);
    if (goHome != true || !context.mounted) return;
    CartStore.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (_) => false,
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({required this.onBack});

  final VoidCallback onBack;

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
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: const Color(0xFF4B4360),
          ),
          const Expanded(
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _CheckoutUi.titlePurple,
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

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionTableListenables,
      builder: (BuildContext context, Widget? child) {
        final String label = tableDisplayLabelForUi();
        final int resolved = resolveTableIdForOrder();
        return Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.table_restaurant_outlined,
                label: 'Table',
                value: label,
                subvalue: 'Order sent as table $resolved',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _InfoChip(
                icon: Icons.schedule_outlined,
                label: 'Estimated Time',
                value: '15-20 min',
                subvalue: 'Prep time',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.subvalue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subvalue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: _CheckoutUi.infoCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF4A3F6B)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D3550),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1520),
            ),
          ),
          if (subvalue != null) ...[
            const SizedBox(height: 2),
            Text(
              subvalue!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D3550),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _YourOrderSection extends StatelessWidget {
  const _YourOrderSection({
    required this.items,
    required this.onEditCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final List<CartItemModel> items;
  final VoidCallback onEditCart;
  final void Function(String id) onIncrement;
  final void Function(String id) onDecrement;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Your Order',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _CheckoutUi.titlePurple,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEditCart,
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.purple.shade500),
                label: Text(
                  'Edit Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No items — go back to your cart.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _CheckoutUi.muted),
              ),
            )
          else
            ...List.generate(items.length, (i) {
              final CartItemModel item = items[i];
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 12 : 16),
                child: _CheckoutLineItem(
                  item: item,
                  onIncrement: () => onIncrement(item.id),
                  onDecrement: () => onDecrement(item.id),
                  onRemove: () => onRemove(item.id),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CheckoutLineItem extends StatelessWidget {
  const _CheckoutLineItem({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String blurb = item.description.isNotEmpty
        ? item.description
        : 'Freshly prepared for you.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DishImageBox(
          width: 72,
          height: 72,
          imageUrl: item.imageUrl,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _CheckoutUi.titleDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                blurb,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3D3550),
                ),
              ),
              const SizedBox(height: 10),
              _CheckoutQtyRow(
                quantity: item.quantity,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.lineTotalLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _CheckoutUi.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckoutQtyRow extends StatelessWidget {
  const _CheckoutQtyRow({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    const double h = 36;
    return Container(
      height: h,
      width: 120,
      decoration: BoxDecoration(
        color: AppColors.quantityStepperCenter,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.quantityStepperBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onDecrement,
              child: const Center(
                child: Icon(Icons.remove_rounded, size: 20, color: AppColors.quantityStepperAccent),
              ),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.quantityStepperAccent,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onIncrement,
              child: const Center(
                child: Icon(Icons.add_rounded, size: 20, color: AppColors.quantityStepperAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialInstructionsField extends StatelessWidget {
  const _SpecialInstructionsField({
    required this.controller,
    required this.maxLength,
    required this.lengthUsed,
  });

  final TextEditingController controller;
  final int maxLength;
  final int lengthUsed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.purple.shade400, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Special Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _CheckoutUi.titlePurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: 4,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(),
              decoration: InputDecoration(
                hintText: 'Add notes for the kitchen (e.g. less spicy, no onions).',
                hintStyle: TextStyle(
                  color: _CheckoutUi.muted.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: _CheckoutUi.infoCardBg.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: Text(
                '$lengthUsed/$maxLength',
                style: const TextStyle(fontSize: 12, color: _CheckoutUi.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BillSummaryBlock extends StatelessWidget {
  const _BillSummaryBlock({
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.discount,
    required this.total,
  });

  final int subtotal;
  final int service;
  final int tax;
  final int discount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.purple.shade400, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _CheckoutUi.titlePurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BillRow(label: 'Subtotal', value: 'Rs $subtotal'),
          const SizedBox(height: 8),
          _BillRow(label: 'Service Charge (5%)', value: 'Rs $service'),
          const SizedBox(height: 8),
          _BillRow(label: 'Tax (8%)', value: 'Rs $tax'),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _BillRow(
              label: 'Discount',
              value: '- Rs $discount',
              valueColor: _CheckoutUi.discountGreen,
            ),
          ],
          LayoutBuilder(
            builder: (context, c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CustomPaint(
                  painter: _DashedLinePainter(color: Colors.grey.shade300),
                  size: Size(c.maxWidth, 1),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _CheckoutUi.titleDark,
                ),
              ),
              Text(
                'Rs $total',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _CheckoutUi.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: _CheckoutUi.muted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? _CheckoutUi.titleDark,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 5;
    const double gap = 4;
    double x = 0;
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ConfirmOrderFooter extends StatelessWidget {
  const _ConfirmOrderFooter({
    required this.enabled,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: enabled ? onConfirm : null,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: enabled ? _CheckoutUi.confirmGradient : null,
                    color: enabled ? null : const Color(0xFFE3DDEE),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSubmitting) ...[
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF1A1520),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ] else ...[
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 24,
                                color: enabled ? const Color(0xFF1A1520) : const Color(0xFFADA3BC),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isSubmitting ? 'Placing order…' : 'Confirm Order',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.15,
                                color: enabled ? const Color(0xFF1A1520) : const Color(0xFFADA3BC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your order will be sent to the kitchen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: enabled
                                ? const Color(0xFF1A1520).withValues(alpha: 0.85)
                                : const Color(0xFFB0A8C4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Secure & Safe',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
