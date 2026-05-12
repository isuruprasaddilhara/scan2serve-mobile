import 'package:flutter/material.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/models/orders/order_detail_model.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/cart/cart_page.dart';
import 'package:scan2serve/widgets/dish_image.dart';

/// Adds past-order lines to [CartStore] (needs `menu_item` ids from the orders API) and opens [CartPage].
void _reorderPastOrderToCart(BuildContext context, OrderDetailModel detail) {
  final List<OrderLineItemModel> lines = detail.lineItems
      .where(
        (OrderLineItemModel e) =>
            e.menuItemId != null && e.menuItemId! > 0 && e.quantity >= 1,
      )
      .toList();
  if (lines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cannot reorder: dish IDs are missing for this order. Add items from the menu.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  for (final OrderLineItemModel line in lines) {
    final int unit = line.quantity > 0
        ? (line.lineTotalRs / line.quantity).round()
        : line.lineTotalRs;
    CartStore.instance.addMenuItem(
      MenuItemModel(
        name: line.name,
        priceLabel: 'Rs $unit',
        description: '',
        menuItemId: line.menuItemId,
        imageUrl: line.imageUrl,
      ),
      line.quantity,
    );
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        lines.length == 1
            ? 'Added to cart — review and checkout'
            : '${lines.length} items added to cart',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CartPage()),
  );
}

abstract final class _DetailUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF8B8499);
  static const Color accent = Color(0xFF9B77D6);
  static const Color iconBg = Color(0xFFEDE4FA);
  static const LinearGradient reorderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC9B6EC), Color(0xFF8E6FD0)],
  );
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.detail});

  final OrderDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailTopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _SummaryCard(detail: detail),
                  const SizedBox(height: 14),
                  _OrderItemsCard(items: detail.lineItems),
                  const SizedBox(height: 14),
                  _BillSummaryCard(
                    subtotal: detail.subtotalRs,
                    service: detail.serviceChargeRs,
                    tax: detail.taxRs,
                    total: detail.totalRs,
                  ),
                  const SizedBox(height: 14),
                  _SpecialNoteCard(note: detail.specialNote),
                  SizedBox(height: 100 + bottom),
                ],
              ),
            ),
            _BottomActions(
              bottomInset: bottom,
              onDownload: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download bill — connect backend later'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onReorder: () => _reorderPastOrderToCart(context, detail),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack});

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
              'Order Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _DetailUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});

  final OrderDetailModel detail;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _DetailUi.iconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 28,
                  color: _DetailUi.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${detail.orderNo}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _DetailUi.titlePurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.table_restaurant_outlined,
                          text: 'Table: ${detail.tableNo}',
                        ),
                        _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          text: detail.dateLabel,
                        ),
                        _MetaChip(
                          icon: Icons.access_time_rounded,
                          text: detail.timeLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: detail.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: _DetailUi.muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _DetailUi.muted,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MyOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (String text, Color bg, Color fg) = switch (status) {
      MyOrderStatus.completed => (
          'Completed',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      MyOrderStatus.preparing => (
          'Preparing',
          const Color(0xFFFFF1E2),
          const Color(0xFFE59A43),
        ),
      MyOrderStatus.cancelled => (
          'Cancelled',
          const Color(0xFFFFECEF),
          const Color(0xFFD95C6E),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.items});

  final List<OrderLineItemModel> items;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.purple.shade400),
              const SizedBox(width: 8),
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _DetailUi.titlePurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _LineItemRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item});

  final OrderLineItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DishImageBox(
          width: 52,
          height: 52,
          imageUrl: item.imageUrl,
          borderRadius: BorderRadius.circular(10),
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
                  color: _DetailUi.titlePurple,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _DetailUi.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _DetailUi.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          item.lineTotalLabel,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1520),
          ),
        ),
      ],
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.total,
  });

  final int subtotal;
  final int service;
  final int tax;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.purple.shade400),
              const SizedBox(width: 8),
              const Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _DetailUi.titlePurple,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LayoutBuilder(
              builder: (context, c) {
                return CustomPaint(
                  painter: _DashedLinePainter(color: Colors.grey.shade300),
                  size: Size(c.maxWidth, 1),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _DetailUi.titlePurple,
                ),
              ),
              Text(
                'Rs $total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _DetailUi.accent,
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
  const _BillRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: _DetailUi.muted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1520),
          ),
        ),
      ],
    );
  }
}

class _SpecialNoteCard extends StatelessWidget {
  const _SpecialNoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: Colors.purple.shade400),
              const SizedBox(width: 8),
              const Text(
                'Special Note',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _DetailUi.titlePurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _DetailUi.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.bottomInset,
    required this.onDownload,
    required this.onReorder,
  });

  final double bottomInset;
  final VoidCallback onDownload;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 22),
              label: const Text(
                'Download Bill',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DetailUi.accent,
                side: const BorderSide(color: Color(0xFFD7C8F2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onReorder,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _DetailUi.reorderGradient,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, color: Color(0xFF1A1520), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Reorder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1520),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
