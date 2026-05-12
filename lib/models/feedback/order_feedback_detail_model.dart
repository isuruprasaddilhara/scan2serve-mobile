import 'package:scan2serve/models/feedback/past_order_feedback_model.dart';

/// Single feedback record from `GET /orders/{id}/feedback/detail/`.
class OrderFeedbackDetail {
  const OrderFeedbackDetail({
    required this.orderId,
    required this.ratingOutOf5,
    required this.comment,
    required this.dateLabel,
  });

  final int orderId;
  final int ratingOutOf5;
  final String comment;
  final String dateLabel;

  static OrderFeedbackDetail? tryParse(Map<String, dynamic> m) {
    final Map<String, dynamic> flat =
        PastOrderFeedbackModel.normalizeFeedbackJson(m);
    final int? oid = PastOrderFeedbackModel.orderIdFromFeedbackApiMap(flat);
    if (oid == null || oid <= 0) return null;

    final int rating = _ratingFromDynamic(flat['rating'] ?? flat['stars']);
    final String comment =
        '${flat['comment'] ?? flat['text'] ?? flat['review'] ?? ''}'.trim();

    final String createdRaw =
        PastOrderFeedbackModel.extractPrimaryDateIso(flat);

    return OrderFeedbackDetail(
      orderId: oid,
      ratingOutOf5: rating,
      comment: comment.isEmpty ? '—' : comment,
      dateLabel: _feedbackDateLabel(createdRaw),
    );
  }

  /// Row for Past Orders when list endpoints omit this record.
  PastOrderFeedbackModel toPastOrderCardModel() {
    return PastOrderFeedbackModel(
      orderNumber: '$orderId',
      dateLabel: dateLabel,
      itemNames: <String>['Order #$orderId'],
      ratingOutOf5: ratingOutOf5,
      comment: comment,
      showDelete: true,
    );
  }

  static int _ratingFromDynamic(dynamic v) {
    if (v == null) return 5;
    if (v is num) return v.round().clamp(1, 5);
    final int? p = int.tryParse('$v'.trim());
    if (p != null) return p.clamp(1, 5);
    return 5;
  }
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

String _feedbackDateLabel(String iso) {
  if (iso.isEmpty) return '—';
  final DateTime? dt = DateTime.tryParse(iso);
  if (dt == null) return '—';
  final DateTime local = dt.toLocal();
  final int m = local.month;
  final String mon = (m >= 1 && m <= 12) ? _monthAbbr[m - 1] : '';
  return '${local.day} $mon, ${local.year}';
}
