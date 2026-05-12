import 'package:scan2serve/api/media_url.dart';
import 'package:scan2serve/api/menu_api.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';

class OrderLineItemModel {
  const OrderLineItemModel({
    required this.name,
    required this.quantity,
    required this.lineTotalRs,
    this.imageUrl,
    this.menuItemId,
  });

  final String name;
  final int quantity;
  final int lineTotalRs;
  final String? imageUrl;
  /// Backend `menu_item` pk — required for cart checkout / reorder.
  final int? menuItemId;

  String get lineTotalLabel => 'Rs $lineTotalRs';
}

int _detailQty(dynamic v) {
  if (v == null) return 1;
  if (v is int) return v < 1 ? 1 : v;
  if (v is num) return v.toInt() < 1 ? 1 : v.toInt();
  return int.tryParse('$v') ?? 1;
}

int _detailMoney(dynamic v) {
  final double? d = double.tryParse('$v'.trim());
  return d == null ? 0 : d.round();
}

int? _menuItemPk(Map<String, dynamic> m) {
  final dynamic v = m['menu_item'];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is Map) {
    final Map<String, dynamic> om = Map<String, dynamic>.from(v);
    final dynamic id = om['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
  }
  return int.tryParse('$v'.trim());
}

String? _orderLineImageUrl(Map<String, dynamic> m) {
  final dynamic nested = m['menu_item'];
  if (nested is Map) {
    final String? raw =
        rawMenuImageFromJson(Map<String, dynamic>.from(nested));
    if (raw != null) return absoluteMediaUrl(raw);
  }
  final String? direct = m['menu_item_image'] as String?;
  final String? alt = m['image_url'] as String? ?? m['image'] as String?;
  return absoluteMediaUrl(direct ?? alt);
}

String _timeFromIso(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final DateTime? dt = DateTime.tryParse(iso.trim());
  if (dt == null) return '—';
  final DateTime local = dt.toLocal();
  final int h24 = local.hour;
  final bool am = h24 < 12;
  final int h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${local.minute.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.orderNo,
    required this.tableNo,
    required this.dateLabel,
    required this.timeLabel,
    required this.status,
    required this.lineItems,
    required this.subtotalRs,
    required this.serviceChargeRs,
    required this.taxRs,
    required this.totalRs,
    required this.specialNote,
  });

  final String orderNo;
  final String tableNo;
  final String dateLabel;
  final String timeLabel;
  final MyOrderStatus status;
  final List<OrderLineItemModel> lineItems;
  final int subtotalRs;
  final int serviceChargeRs;
  /// 8% of subtotal (bill breakdown).
  final int taxRs;
  final int totalRs;
  final String specialNote;

  factory OrderDetailModel.fromMyOrder(MyOrderModel order) {
    final List<OrderLineItemModel> lines;
    if (order.itemRows != null && order.itemRows!.isNotEmpty) {
      lines = order.itemRows!
          .map(
            (Map<String, dynamic> m) => OrderLineItemModel(
              name: (m['menu_item_name'] as String?)?.trim() ?? 'Item',
              quantity: _detailQty(m['quantity']),
              lineTotalRs: _detailMoney(m['price']),
              menuItemId: _menuItemPk(m),
              imageUrl: _orderLineImageUrl(m),
            ),
          )
          .toList();
    } else {
      final int n = order.itemCount;
      if (n <= 0) {
        lines = <OrderLineItemModel>[
          OrderLineItemModel(
            name: 'Items',
            quantity: 1,
            lineTotalRs: order.amountRs,
          ),
        ];
      } else {
        final int each = order.amountRs ~/ n;
        lines = List<OrderLineItemModel>.generate(
          n,
          (int i) => OrderLineItemModel(
            name: 'Item ${i + 1}',
            quantity: 1,
            lineTotalRs: i < n - 1 ? each : order.amountRs - each * (n - 1),
          ),
        );
      }
    }

    final int lineSum =
        lines.fold<int>(0, (int s, OrderLineItemModel e) => s + e.lineTotalRs);
    final int declared = order.amountRs;
    final int subtotalRs = lineSum > 0 ? lineSum : (declared > 0 ? declared : 0);
    // Always show true 5% / 8% of subtotal — do not derive “service” as total − subtotal
    // (that bundles tax and rounding into one line and breaks the 5% label).
    final int serviceChargeRs =
        subtotalRs == 0 ? 0 : (subtotalRs * 0.05).round();
    final int taxRs = subtotalRs == 0 ? 0 : (subtotalRs * 0.08).round();
    final int totalRs = subtotalRs + serviceChargeRs + taxRs;

    final String note = (order.apiSpecialNotes != null &&
            order.apiSpecialNotes!.trim().isNotEmpty)
        ? order.apiSpecialNotes!.trim()
        : '—';

    return OrderDetailModel(
      orderNo: order.orderNo,
      tableNo: order.tableNo,
      dateLabel: order.dateLabel,
      timeLabel: _timeFromIso(order.apiCreatedAtIso),
      status: order.status,
      lineItems: lines,
      subtotalRs: subtotalRs,
      serviceChargeRs: serviceChargeRs,
      taxRs: taxRs,
      totalRs: totalRs,
      specialNote: note,
    );
  }
}
