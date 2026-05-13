enum MyOrderStatus { completed, preparing, cancelled }

class MyOrderModel {
  const MyOrderModel({
    required this.orderNo,
    required this.tableNo,
    required this.itemCount,
    required this.dateLabel,
    required this.amountRs,
    required this.status,
    this.itemRows,
    this.apiSpecialNotes,
    this.apiCreatedAtIso,
  });

  final String orderNo;
  final String tableNo;
  final int itemCount;
  final String dateLabel;
  final int amountRs;
  final MyOrderStatus status;

  /// When set (from `GET /orders/` rows), detail screen can show real lines.
  final List<Map<String, dynamic>>? itemRows;

  final String? apiSpecialNotes;
  final String? apiCreatedAtIso;

  String get amountLabel => 'Rs $amountRs';
  String get itemCountLabel => '$itemCount ${itemCount == 1 ? 'Item' : 'Items'}';

  int? get orderIdParsed => int.tryParse(orderNo);

  factory MyOrderModel.fromOrdersApiMap(Map<String, dynamic> m) {
    final int id = _asInt(m['id']);
    final int table = _asInt(m['table']);
    final List<dynamic>? raw = m['items'] as List<dynamic>?;
    List<Map<String, dynamic>>? rows;
    int count = 0;
    if (raw != null) {
      rows = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map<String, dynamic>) {
          rows.add(e);
        } else if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
      count = rows.length;
    }
    final String? created = m['created_at'] as String?;
    final String? notes = m['special_notes'] as String?;
    final String? notesTrim = notes?.trim();
    return MyOrderModel(
      orderNo: '$id',
      tableNo: table > 0 ? 'T$table' : '—',
      itemCount: count,
      dateLabel: _orderListDateLabel(created),
      amountRs: _moneyFromDynamic(m['total_amount']),
      status: _mapApiOrderStatus(m['status']),
      itemRows: (rows == null || rows.isEmpty) ? null : rows,
      apiSpecialNotes:
          (notesTrim == null || notesTrim.isEmpty) ? null : notesTrim,
      apiCreatedAtIso:
          (created != null && created.trim().isNotEmpty) ? created.trim() : null,
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

int _moneyFromDynamic(dynamic v) {
  final double? d = double.tryParse('$v'.trim());
  return d == null ? 0 : d.round();
}

const List<String> _monthAbbr = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _orderListDateLabel(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final DateTime? dt = DateTime.tryParse(iso.trim());
  if (dt == null) return '—';
  final DateTime local = dt.toLocal();
  final int m = local.month;
  final String mon = (m >= 1 && m <= 12) ? _monthAbbr[m - 1] : '';
  return '${local.day} $mon, ${local.year}';
}

MyOrderStatus _mapApiOrderStatus(dynamic raw) {
  final String s = '$raw'.trim().toLowerCase();
  switch (s) {
    case 'cancelled':
      return MyOrderStatus.cancelled;
    case 'completed':
    case 'served':
    case 'requested':
    case 'ready':
      return MyOrderStatus.completed;
    default:
      return MyOrderStatus.preparing;
  }
}
