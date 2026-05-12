import 'dart:convert';

import 'package:scan2serve/api/api_client.dart';
import 'package:scan2serve/models/feedback/order_feedback_detail_model.dart';
import 'package:scan2serve/models/feedback/past_order_feedback_model.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';

int _jsonInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  throw FormatException('Expected int in order response, got $v');
}

/// `POST /orders/` — body matches backend: `table`, `special_notes`, `items`, `feedback`.
/// Auth: Bearer JWT when logged in; guests omit it. Response includes `guest_token` for guests.
Future<CreateOrderResult> createOrder({
  required int table,
  required List<Map<String, dynamic>> items,
  String? specialNotes,
}) async {
  final res = await apiPost(
    '/orders/',
    body: <String, dynamic>{
      'table': table,
      'special_notes': specialNotes?.trim() ?? '',
      'items': items,
      'feedback': null,
    },
  );
  if (res.statusCode == 201) {
    final Map<String, dynamic> m =
        jsonDecode(res.body) as Map<String, dynamic>;
    final dynamic userRaw = m['user'];
    final dynamic guestRaw = m['guest_token'];
    return CreateOrderResult(
      orderId: _jsonInt(m['id']),
      table: _jsonInt(m['table']),
      userId: userRaw == null ? null : _jsonInt(userRaw),
      guestToken: guestRaw is String && guestRaw.isNotEmpty ? guestRaw : null,
    );
  }
  throw OrdersApiException(res.statusCode, res.body);
}

class CreateOrderResult {
  const CreateOrderResult({
    required this.orderId,
    required this.table,
    this.userId,
    this.guestToken,
  });

  final int orderId;
  final int table;
  final int? userId;
  final String? guestToken;
}

/// Best-effort message from DRF-style JSON for SnackBars.
String? parseOrdersErrorMessage(String body) {
  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final dynamic detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    final List<String> parts = <String>[];
    for (final MapEntry<String, dynamic> e in decoded.entries) {
      if (e.key == 'detail') continue;
      final dynamic v = e.value;
      if (v is List) {
        for (final dynamic x in v) {
          if (x is String && x.trim().isNotEmpty) parts.add(x.trim());
        }
      } else if (v is String && v.trim().isNotEmpty) {
        parts.add(v.trim());
      }
    }
    if (parts.isNotEmpty) return parts.join(' ');
  } catch (_) {}
  return null;
}

int _sortKeyForOrderMap(Map<String, dynamic> m) {
  final DateTime? dt = DateTime.tryParse('${m['created_at'] ?? ''}');
  return dt?.millisecondsSinceEpoch ?? 0;
}

/// [jsonDecode] often yields `Map` values that are not `Map<String, dynamic>` at runtime.
Map<String, dynamic>? _jsonObjectToStringKeyMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<MyOrderModel> _myOrdersFromResponseBody(String body) {
  final Object? decoded = jsonDecode(body);
  final List<Map<String, dynamic>> raw = <Map<String, dynamic>>[];

  void addAllFromList(List<dynamic> list) {
    for (final Object? e in list) {
      final Map<String, dynamic>? row = _jsonObjectToStringKeyMap(e);
      if (row == null) continue;
      final int id = _jsonIntLoose(row['id']);
      if (id <= 0) continue;
      raw.add(row);
    }
  }

  if (decoded is List) {
    addAllFromList(List<dynamic>.from(decoded));
  } else if (decoded is Map) {
    final Map<String, dynamic> root = Map<String, dynamic>.from(decoded);
    const List<String> listKeys = <String>[
      'results',
      'orders',
      'data',
      'my_orders',
    ];
    bool found = false;
    for (final String k in listKeys) {
      final Object? v = root[k];
      if (v is List) {
        addAllFromList(List<dynamic>.from(v));
        if (raw.isNotEmpty) {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      for (final Object? v in root.values) {
        if (v is List && v.isNotEmpty) {
          addAllFromList(List<dynamic>.from(v));
          if (raw.isNotEmpty) break;
        }
      }
    }
  }

  raw.sort(
    (Map<String, dynamic> a, Map<String, dynamic> b) =>
        _sortKeyForOrderMap(b).compareTo(_sortKeyForOrderMap(a)),
  );
  return raw.map(MyOrderModel.fromOrdersApiMap).toList();
}

int _jsonIntLoose(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v'.trim()) ?? 0;
}

/// Lists the signed-in **customer’s** orders (Bearer JWT).
///
/// Backend: **`GET /orders/my-orders/`** — JSON array of orders (same fields as
/// `GET /orders/{id}/`). Staff use **`GET /orders/`** instead.
Future<List<MyOrderModel>> fetchMyOrdersList() async {
  const List<String> paths = <String>[
    '/orders/my-orders/',
    '/users/customer/orders/',
    '/users/customer/me/orders/',
  ];
  OrdersApiException? lastError;
  for (final String path in paths) {
    final res = await apiGet(path);
    if (res.statusCode == 200) {
      return _myOrdersFromResponseBody(res.body);
    }
    lastError = OrdersApiException(res.statusCode, res.body);
    if (res.statusCode == 404) {
      continue;
    }
    if (res.statusCode == 403) {
      final String? msg = parseOrdersErrorMessage(res.body)?.toLowerCase();
      if (msg != null &&
          (msg.contains('staff') || msg.contains('permission'))) {
        continue;
      }
    }
    throw lastError;
  }
  throw lastError ??
      OrdersApiException(
        404,
        '{"detail":"Orders list not found. Expected GET /orders/my-orders/."}',
      );
}

int _sortKeyForFeedbackMap(Map<String, dynamic> m) {
  final Map<String, dynamic> n =
      PastOrderFeedbackModel.normalizeFeedbackJson(m);
  final DateTime? dt = DateTime.tryParse(
    PastOrderFeedbackModel.extractPrimaryDateIso(n),
  );
  return dt?.millisecondsSinceEpoch ?? 0;
}

/// Logged-in **customer** feedback history (Bearer JWT only).
///
/// Django: **`GET /orders/feedbacks/my-feedbacks/`** ([CustomerFeedbackListView]).
Future<List<PastOrderFeedbackModel>> fetchMyFeedbacksList() async {
  const List<String> paths = <String>[
    '/orders/feedbacks/my-feedbacks/',
    '/orders/my-feedbacks/',
    '/feedbacks/my-feedbacks/',
    '/users/customer/feedbacks/',
  ];
  OrdersApiException? lastError;
  for (final String path in paths) {
    final res = await apiGet(path);
    if (res.statusCode == 200) {
      return _myFeedbacksFromResponseBody(res.body);
    }
    lastError = OrdersApiException(res.statusCode, res.body);
    if (res.statusCode == 404 || res.statusCode == 403) {
      continue;
    }
    throw lastError;
  }
  throw lastError ??
      OrdersApiException(
        404,
        '{"detail":"Feedback list not found."}',
      );
}

List<PastOrderFeedbackModel> _myFeedbacksFromResponseBody(String body) {
  final Object? decoded = jsonDecode(body);
  final List<Map<String, dynamic>> raw = <Map<String, dynamic>>[];

  void addAllFromList(List<dynamic> list) {
    for (final Object? e in list) {
      final Map<String, dynamic>? row = _jsonObjectToStringKeyMap(e);
      if (row == null) continue;
      raw.add(row);
    }
  }

  if (decoded is List) {
    addAllFromList(List<dynamic>.from(decoded));
  } else if (decoded is Map) {
    final Map<String, dynamic> root = Map<String, dynamic>.from(decoded);
    const List<String> listKeys = <String>[
      'results',
      'feedbacks',
      'customer_feedbacks',
      'data',
      'my_feedbacks',
      'feedback',
      'items',
      'objects',
      'feedback_list',
    ];
    bool found = false;
    for (final String k in listKeys) {
      final Object? v = root[k];
      if (v is List) {
        addAllFromList(List<dynamic>.from(v));
        if (raw.isNotEmpty) {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      for (final Object? v in root.values) {
        if (v is List && v.isNotEmpty) {
          addAllFromList(List<dynamic>.from(v));
          if (raw.isNotEmpty) break;
        }
      }
    }
  }

  raw.sort(
    (Map<String, dynamic> a, Map<String, dynamic> b) =>
        _sortKeyForFeedbackMap(b).compareTo(_sortKeyForFeedbackMap(a)),
  );

  final List<PastOrderFeedbackModel> out = <PastOrderFeedbackModel>[];
  for (final Map<String, dynamic> m in raw) {
    final PastOrderFeedbackModel? row = PastOrderFeedbackModel.tryParseApiFeedback(m);
    if (row != null) out.add(row);
  }
  return out;
}

/// GET `/orders/{id}/feedback/detail/` — feedback for a single order.
/// Returns **`null`** when the server responds **404** (no feedback for that order).
/// Logged-in: Bearer JWT; **guest:** `X-Guest-Token` only when [guestToken] is set.
Future<OrderFeedbackDetail?> fetchOrderFeedbackDetail(
  int orderId, {
  String? guestToken,
}) async {
  final Map<String, String> headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiGet(
    '/orders/$orderId/feedback/detail/',
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode == 404) {
    return null;
  }
  if (res.statusCode != 200) {
    throw OrdersApiException(res.statusCode, res.body);
  }
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return OrderFeedbackDetail.tryParse(decoded);
    }
  } catch (_) {}
  return null;
}

/// DELETE `/orders/{id}/feedback/delete/` — remove feedback for that order.
/// Logged-in: Bearer JWT; **guest:** `X-Guest-Token` only when [guestToken] is set.
Future<void> deleteOrderFeedback(
  int orderId, {
  String? guestToken,
}) async {
  final Map<String, String> headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiDelete(
    '/orders/$orderId/feedback/delete/',
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode != 204 && res.statusCode != 200) {
    throw OrdersApiException(res.statusCode, res.body);
  }
}

/// POST `/orders/{id}/request-bill/` — logged-in: Bearer JWT; **guest:** `X-Guest-Token` only (no Bearer).
Future<RequestBillResult> requestBill(
  int orderId, {
  String? guestToken,
}) async {
  final Map<String, String> headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiPost(
    '/orders/$orderId/request-bill/',
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw OrdersApiException(res.statusCode, res.body);
  }
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final String msg =
          (decoded['message'] as String?)?.trim() ?? 'Bill requested.';
      final int oid = _jsonIntLoose(decoded['order_id']);
      final dynamic ta = decoded['total_amount'];
      final double? total = ta is num ? ta.toDouble() : double.tryParse('$ta');
      final String? st = decoded['status'] as String?;
      return RequestBillResult(
        message: msg,
        orderId: oid > 0 ? oid : orderId,
        totalAmount: total,
        status: st?.trim(),
      );
    }
  } catch (_) {}
  return RequestBillResult(message: 'Bill requested.', orderId: orderId);
}

/// POST `/orders/{id}/feedback/` — body: `{ "rating": int, "comment": string }`.
/// Logged-in: Bearer JWT; **guest:** `X-Guest-Token` only (no Bearer).
Future<SubmitOrderFeedbackResult> submitOrderFeedback(
  int orderId, {
  required int rating,
  required String comment,
  String? guestToken,
}) async {
  final Map<String, String> headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiPost(
    '/orders/$orderId/feedback/',
    body: <String, dynamic>{
      'rating': rating,
      'comment': comment,
    },
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw OrdersApiException(res.statusCode, res.body);
  }
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final String msg = (decoded['message'] as String?)?.trim() ??
          (decoded['detail'] as String?)?.trim() ??
          '';
      return SubmitOrderFeedbackResult(
        message: msg.isNotEmpty ? msg : 'Thank you for your feedback!',
      );
    }
  } catch (_) {}
  return const SubmitOrderFeedbackResult(
    message: 'Thank you for your feedback!',
  );
}

class SubmitOrderFeedbackResult {
  const SubmitOrderFeedbackResult({required this.message});

  final String message;
}

class RequestBillResult {
  const RequestBillResult({
    required this.message,
    required this.orderId,
    this.totalAmount,
    this.status,
  });

  final String message;
  final int orderId;
  final double? totalAmount;
  final String? status;
}

/// DELETE `/orders/{id}/` — same path as [fetchOrder]; cancel while status is `pending`.
/// Pass [guestToken] for guest orders (same header as GET).
Future<void> deleteOrder(
  int orderId, {
  String? guestToken,
}) async {
  final headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiDelete(
    '/orders/$orderId/',
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode != 204 && res.statusCode != 200) {
    throw OrdersApiException(res.statusCode, res.body);
  }
}

/// GET single order — JWT or **guest** via `X-Guest-Token` only when [guestToken] is set.
Future<Map<String, dynamic>> fetchOrder(
  int orderId, {
  String? guestToken,
}) async {
  final headers = <String, String>{};
  final String? gt = guestToken?.trim();
  if (gt != null && gt.isNotEmpty) {
    headers['X-Guest-Token'] = gt;
  }
  final bool guestAuth = gt != null && gt.isNotEmpty;
  final res = await apiGet(
    '/orders/$orderId/',
    headers: headers.isEmpty ? null : headers,
    includeBearer: !guestAuth,
  );
  if (res.statusCode != 200) {
    throw OrdersApiException(res.statusCode, res.body);
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

class OrdersApiException implements Exception {
  OrdersApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'OrdersApiException($statusCode): $body';
}
