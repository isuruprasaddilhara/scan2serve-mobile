import 'package:scan2serve/api/media_url.dart';
import 'package:scan2serve/api/menu_api.dart';
import 'package:scan2serve/formatting/rs_money.dart';
import 'package:scan2serve/models/track_order/order_status_mapping.dart';
import 'package:scan2serve/models/track_order/track_order_model.dart';

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

String? _optionalTrimmedString(dynamic v) {
  if (v == null) return null;
  final String s = '$v'.trim();
  return s.isEmpty ? null : s;
}

String? _formatTotalLine(dynamic raw) {
  if (raw == null) return null;
  final String s = '$raw'.trim();
  if (s.isEmpty) return null;
  final double? n = double.tryParse(s);
  if (n == null) return 'Total: Rs $s';
  return 'Total: ${formatRsDisplay(n.round())}';
}

String? _formatPlacedAt(dynamic raw) {
  final String? iso = _optionalTrimmedString(raw);
  if (iso == null) return null;
  final DateTime? dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  final DateTime local = dt.toLocal();
  final String d = '${local.day}/${local.month}/${local.year}';
  final String t =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return 'Placed $d · $t';
}

String _lineItemsOneLiner(List<Map<String, dynamic>> lines) {
  final List<String> parts = <String>[];
  for (final Map<String, dynamic> raw in lines) {
    final String name = _optionalTrimmedString(raw['menu_item_name']) ?? 'Item';
    final int q = _asInt(raw['quantity']);
    parts.add('$name ×$q');
  }
  const int maxLen = 140;
  String out = parts.join(' · ');
  if (out.length > maxLen) {
    out = '${out.substring(0, maxLen - 1)}…';
  }
  return out;
}

String? _orderLineItemImageUrl(Map<String, dynamic> line) {
  final nested = line['menu_item'];
  if (nested is Map<String, dynamic>) {
    final raw = rawMenuImageFromJson(nested);
    if (raw != null) return absoluteMediaUrl(raw);
  }
  final direct = line['menu_item_image'] as String? ??
      line['image_url'] as String? ??
      line['image'] as String?;
  return absoluteMediaUrl(direct);
}

/// Build UI model from `GET /orders/{id}/` JSON (and optional display name).
/// Only reads: [id], [status], [items] (name + qty + image hints), [total_amount],
/// [special_notes], [created_at]. Other keys are ignored.
TrackOrderModel trackOrderModelFromOrdersApiJson(
  Map<String, dynamic> orderJson, {
  String title = 'Track Order',
  String etaLabel = 'Est. time from restaurant',
  String customerName = '',
}) {
  final List<dynamic>? rawItems = orderJson['items'] as List<dynamic>?;
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  if (rawItems != null) {
    for (final dynamic e in rawItems) {
      if (e is Map<String, dynamic>) items.add(e);
    }
  }

  String dishName = 'Your order';
  String? imageUrl;
  if (items.isEmpty) {
    dishName = 'Your order';
  } else if (items.length == 1) {
    dishName =
        _optionalTrimmedString(items.first['menu_item_name']) ?? dishName;
    imageUrl = _orderLineItemImageUrl(items.first);
  } else {
    final String first =
        _optionalTrimmedString(items.first['menu_item_name']) ?? 'Your order';
    dishName = '$first + ${items.length - 1} more';
    imageUrl = _orderLineItemImageUrl(items.first);
  }

  final int id = _asInt(orderJson['id']);
  final String? statusRaw = _optionalTrimmedString(orderJson['status']);

  final List<String> detailLines = <String>[];
  final String? totalLine = _formatTotalLine(orderJson['total_amount']);
  if (totalLine != null) detailLines.add(totalLine);
  if (items.isNotEmpty) {
    detailLines.add(_lineItemsOneLiner(items));
  }
  final String? notes = _optionalTrimmedString(orderJson['special_notes']);
  if (notes != null) detailLines.add('Notes: $notes');
  final String? placed = _formatPlacedAt(orderJson['created_at']);
  if (placed != null) detailLines.add(placed);

  final String resolvedEta = statusRaw != null && statusRaw.isNotEmpty
      ? trackOrderStatusHeadline(statusRaw)
      : etaLabel;

  return TrackOrderModel(
    title: title,
    dishName: dishName,
    etaLabel: resolvedEta,
    imageUrl: imageUrl,
    summaryDetailLines: detailLines,
    steps: const [
      TrackStepModel(label: 'Order Sent'),
      TrackStepModel(label: 'Accepted'),
      TrackStepModel(label: 'Cooking'),
      TrackStepModel(label: 'Ready'),
    ],
    activeStepIndex: 0,
    orderNumber: '$id',
    customerName: customerName,
    apiOrderId: id,
    apiStatus: statusRaw,
  );
}
