/// One past order row on Feedback & Ratings.
class PastOrderFeedbackModel {
  const PastOrderFeedbackModel({
    required this.orderNumber,
    required this.dateLabel,
    required this.itemNames,
    required this.ratingOutOf5,
    required this.comment,
    this.showDelete = false,
  });

  final String orderNumber;
  final String dateLabel;
  final List<String> itemNames;
  final int ratingOutOf5;
  final String comment;

  /// When `true`, the UI offers delete — backed by `DELETE /orders/{id}/feedback/delete/`.
  final bool showDelete;

  String get itemsLine => itemNames.join(', ');

  /// Order id from feedback JSON (`my-feedbacks`, `feedback/detail`, etc.).
  static int? orderIdFromFeedbackApiMap(Map<String, dynamic> m) =>
      _orderIdFromFeedbackMap(m);

  /// Normalizes one element from **`my-feedbacks`**, detail, or order+feedback JSON.
  /// Call before [orderIdFromFeedbackApiMap] / detail parsing so nested `feedback`
  /// maps do not wipe top-level `order_id` / `order_created_at`.
  static Map<String, dynamic> normalizeFeedbackJson(Map<String, dynamic> raw) {
    return _flattenFeedbackJsonAliases(_mergeNestedFeedbackRow(raw));
  }

  /// Best datetime string for labels/sorting after [normalizeFeedbackJson].
  static String extractPrimaryDateIso(Map<String, dynamic> normalizedFlat) {
    return _pickPrimaryDateIso(normalizedFlat);
  }

  /// Parses one feedback object from `GET /orders/feedbacks/my-feedbacks/`.
  static PastOrderFeedbackModel? tryParseApiFeedback(Map<String, dynamic> m) {
    final Map<String, dynamic> flat = normalizeFeedbackJson(m);
    int? orderId = _orderIdFromFeedbackMap(flat);
    orderId ??= _guessOrderIdLoose(flat);
    if (orderId == null || orderId <= 0) return null;

    final int rating = _ratingFromDynamic(
      flat['rating'] ?? flat['stars'] ?? flat['star_rating'],
    );
    final String comment =
        '${flat['comment'] ?? flat['text'] ?? flat['review'] ?? ''}'.trim();

    final String createdRaw = _pickPrimaryDateIso(flat);

    final List<String> itemNames = _itemNamesFromFeedbackMap(flat, orderId);

    return PastOrderFeedbackModel(
      orderNumber: '$orderId',
      dateLabel: _feedbackDateLabel(createdRaw),
      itemNames: itemNames,
      ratingOutOf5: rating,
      comment: comment.isEmpty ? '—' : comment,
      showDelete: true,
    );
  }

  /// Pulls rating/comment from nested `feedback` without dropping order metadata.
  static Map<String, dynamic> _mergeNestedFeedbackRow(Map<String, dynamic> raw) {
    final Map<String, dynamic> o = Map<String, dynamic>.from(raw);
    final dynamic fbRaw = o['feedback'];
    if (fbRaw is! Map) return o;

    final Map<String, dynamic> fb = Map<String, dynamic>.from(fbRaw);

    if (fb.containsKey('rating')) {
      o['rating'] = fb['rating'];
    }
    if (fb.containsKey('comment')) {
      o['comment'] = fb['comment'];
    }
    if (fb['id'] != null) {
      o['feedback_pk'] = fb['id'];
    }

    // OrderSerializer-style row: outer `id` is the order id, nested is Feedback.
    final bool outerLooksLikeOrder = o.containsKey('items') ||
        (o.containsKey('total_amount') && o.containsKey('created_at'));
    if (outerLooksLikeOrder) {
      o['order_id'] = o['order_id'] ?? o['id'];
      o['order_created_at'] = o['order_created_at'] ?? o['created_at'];
    }

    o.remove('feedback');
    return o;
  }

  static String _pickPrimaryDateIso(Map<String, dynamic> flat) {
    const List<String> keys = <String>[
      'order_created_at',
      'order_create_time',
      'order_created',
      'created_at',
      'updated_at',
      'submitted_at',
      'createdAt',
      'updatedAt',
    ];
    for (final String k in keys) {
      final String s = '${flat[k] ?? ''}'.trim();
      if (s.isNotEmpty) {
        return s;
      }
    }
    final dynamic ord = flat['order'];
    if (ord is Map) {
      final Map<String, dynamic> om = Map<String, dynamic>.from(ord);
      for (final String k in const <String>['created_at', 'createdAt']) {
        final String s = '${om[k] ?? ''}'.trim();
        if (s.isNotEmpty) {
          return s;
        }
      }
    }
    return '';
  }

  /// Merges camelCase / duplicate keys so serializers match Django or SPA clients.
  static Map<String, dynamic> _flattenFeedbackJsonAliases(
    Map<String, dynamic> m,
  ) {
    final Map<String, dynamic> o = Map<String, dynamic>.from(m);
    void copyIfAbsent(String target, String source) {
      final dynamic v = o[source];
      if (v != null && (o[target] == null)) {
        o[target] = v;
      }
    }

    copyIfAbsent('order_id', 'orderId');
    copyIfAbsent('created_at', 'createdAt');
    copyIfAbsent('updated_at', 'updatedAt');
    copyIfAbsent('order_created_at', 'orderCreatedAt');
    copyIfAbsent('order_created_at', 'order_create_time');

    final dynamic nestedOrd = o['order'];
    if (nestedOrd is Map) {
      final Map<String, dynamic> om =
          Map<String, dynamic>.from(nestedOrd);
      if (om['id'] == null && om['pk'] != null) {
        om['id'] = om['pk'];
      }
      if (om['id'] == null && om['orderId'] != null) {
        om['id'] = om['orderId'];
      }
      o['order'] = om;
    }
    return o;
  }

  static int? _guessOrderIdLoose(Map<String, dynamic> m) {
    for (final MapEntry<String, dynamic> e in m.entries) {
      final String k = e.key.toLowerCase();
      if (k == 'menu_order' ||
          k == 'menuorder' ||
          k == 'related_order' ||
          k.endsWith('_order_id')) {
        final int v = _asInt(e.value);
        if (v > 0) return v;
      }
    }
    return null;
  }

  static int? _orderIdFromFeedbackMap(Map<String, dynamic> m) {
    final int directOid = _asInt(m['order_id']);
    if (directOid > 0) return directOid;

    final int camelOid = _asInt(m['orderId']);
    if (camelOid > 0) return camelOid;

    final int pk = _asInt(m['order_pk']);
    if (pk > 0) return pk;

    final dynamic ord = m['order'];
    if (ord is Map) {
      final Map<String, dynamic> om = Map<String, dynamic>.from(ord);
      int id = _asInt(om['id']);
      if (id <= 0) id = _asInt(om['pk']);
      if (id <= 0) id = _asInt(om['orderId']);
      if (id > 0) return id;
    } else if (ord is String) {
      final String s = ord.trim();
      final int? p = int.tryParse(s);
      if (p != null && p > 0) return p;
      final RegExpMatch? url = RegExp(r'/orders/(\d+)').firstMatch(s);
      if (url != null) {
        final int? u = int.tryParse(url.group(1)!);
        if (u != null && u > 0) return u;
      }
    } else if (ord is num) {
      final int v = ord.round();
      if (v > 0) return v;
    }

    final int legacy = _asInt(m['order']);
    if (legacy > 0) return legacy;

    return null;
  }

  static List<String> _itemNamesFromFeedbackMap(
    Map<String, dynamic> m,
    int orderId,
  ) {
    final List<String> out = <String>[];
    dynamic ord = m['order'];
    if (ord is! Map) ord = m['order_detail'];
    if (ord is! Map) ord = m['Order'];
    if (ord is Map) {
      final Map<String, dynamic> om = Map<String, dynamic>.from(ord);
      final dynamic rawItems = om['items'];
      if (rawItems is List) {
        for (final dynamic e in rawItems) {
          if (e is Map) {
            final Map<String, dynamic> row = Map<String, dynamic>.from(e);
            final String? name = _pickItemName(row);
            if (name != null && name.isNotEmpty) out.add(name);
          }
        }
      }
    }
    if (out.isEmpty) {
      out.add('Order #$orderId');
    }
    return out;
  }

  static String? _pickItemName(Map<String, dynamic> row) {
    final dynamic n = row['menu_item_name'] ??
        row['name'] ??
        row['dish_name'] ??
        row['item_name'] ??
        row['title'];
    if (n == null) return null;
    final String s = '$n'.trim();
    return s.isEmpty ? null : s;
  }

  static int _ratingFromDynamic(dynamic v) {
    if (v == null) return 5;
    if (v is num) return v.round().clamp(1, 5);
    final int? p = int.tryParse('$v'.trim());
    if (p != null) return p.clamp(1, 5);
    return 5;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v'.trim()) ?? 0;
  }

  /// Line-item names from **`GET /orders/{id}/`** (`items` array, same as my-orders).
  static List<String> itemNamesFromOrderDetailMap(Map<String, dynamic> order) {
    final List<String> out = <String>[];
    final dynamic rawItems = order['items'];
    if (rawItems is List) {
      for (final dynamic e in rawItems) {
        if (e is Map) {
          final Map<String, dynamic> row = Map<String, dynamic>.from(e);
          final String? name = _pickItemName(row);
          if (name != null && name.isNotEmpty) out.add(name);
        }
      }
    }
    return out;
  }

  /// `true` when we only show the generic **Order #id** line — fetch order detail for dishes.
  bool get lineItemsNeedOrderFetch {
    if (itemNames.isEmpty) return true;
    if (itemNames.length != 1) return false;
    final String s = itemNames.first.trim();
    return RegExp(r'^Order #\d+$').hasMatch(s);
  }

  PastOrderFeedbackModel withItemNames(List<String> names) {
    if (names.isEmpty) return this;
    return PastOrderFeedbackModel(
      orderNumber: orderNumber,
      dateLabel: dateLabel,
      itemNames: names,
      ratingOutOf5: ratingOutOf5,
      comment: comment,
      showDelete: showDelete,
    );
  }

  /// Used when **`my-feedbacks`** has not returned this row yet (server/list lag).
  factory PastOrderFeedbackModel.fromSubmitSnapshot({
    required int orderId,
    required int rating,
    required String comment,
  }) {
    final String when =
        _feedbackDateLabel(DateTime.now().toLocal().toIso8601String());
    return PastOrderFeedbackModel(
      orderNumber: '$orderId',
      dateLabel: when,
      itemNames: <String>['Order #$orderId'],
      ratingOutOf5: rating.clamp(1, 5),
      comment: comment.isEmpty ? '—' : comment,
      showDelete: true,
    );
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
