import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/models/feedback/order_feedback_detail_model.dart';
import 'package:scan2serve/models/feedback/past_order_feedback_model.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/session/active_track_order_session.dart';

enum FeedbackTab { pastOrders, writeFeedback }

class FeedbackRatingsViewModel extends ChangeNotifier {
  FeedbackRatingsViewModel() : _pastOrders = <PastOrderFeedbackModel>[] {
    authAccessToken.addListener(_onAuthTokenChanged);
  }

  static const String screenTitle = 'Feedback & Ratings';

  FeedbackTab _tab = FeedbackTab.pastOrders;
  final List<PastOrderFeedbackModel> _pastOrders;

  bool _ordersLoading = false;
  String? _ordersError;
  List<MyOrderModel> _myOrders = <MyOrderModel>[];
  int? _selectedOrderId;

  bool _pastFeedbacksLoading = false;
  String? _pastFeedbacksError;

  /// Order IDs that already have feedback (for Write tab + duplicate prevention).
  final Set<int> _orderIdsWithFeedback = <int>{};

  /// Until **`my-feedbacks`** includes these orders, keep showing them in Past Orders.
  final Map<int, PastOrderFeedbackModel> _optimisticPastByOrderId =
      <int, PastOrderFeedbackModel>{};

  bool _submitting = false;

  FeedbackTab get tab => _tab;
  List<PastOrderFeedbackModel> get pastOrders =>
      List<PastOrderFeedbackModel>.unmodifiable(_pastOrders);

  bool get pastFeedbacksLoading => _pastFeedbacksLoading;
  String? get pastFeedbacksError => _pastFeedbacksError;

  bool get ordersLoading => _ordersLoading;
  String? get ordersError => _ordersError;
  List<MyOrderModel> get myOrdersForFeedback =>
      List<MyOrderModel>.unmodifiable(_myOrders);
  int? get selectedOrderId => _selectedOrderId;
  bool get submitting => _submitting;

  /// Orders that do not yet have feedback (Write Feedback dropdown).
  List<MyOrderModel> get ordersEligibleForNewFeedback {
    final List<MyOrderModel> out = <MyOrderModel>[];
    for (final MyOrderModel o in _myOrders) {
      final int id = o.orderIdParsed ?? int.tryParse(o.orderNo) ?? 0;
      if (id > 0 && !_orderIdsWithFeedback.contains(id)) {
        out.add(o);
      }
    }
    return List<MyOrderModel>.unmodifiable(out);
  }

  bool get isLoggedIn =>
      (authAccessToken.value?.trim().isNotEmpty ?? false);

  int? get guestOrderId => activeTrackOrderId.value;

  String? get guestToken {
    final String? t = activeTrackGuestToken.value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Refetch when JWT changes (login / logout) so Past Orders does not stay empty or stale.
  void _onAuthTokenChanged() {
    loadPastFeedbacks();
    if (_tab == FeedbackTab.writeFeedback) {
      prepareWriteFeedbackTab();
    }
  }

  @override
  void dispose() {
    authAccessToken.removeListener(_onAuthTokenChanged);
    super.dispose();
  }

  void setTab(FeedbackTab value) {
    if (_tab == value) return;
    _tab = value;
    notifyListeners();
    if (value == FeedbackTab.writeFeedback) {
      prepareWriteFeedbackTab();
    } else if (value == FeedbackTab.pastOrders) {
      loadPastFeedbacks();
    }
  }

  void setSelectedOrderId(int? id) {
    if (_selectedOrderId == id) return;
    _selectedOrderId = id;
    notifyListeners();
  }

  /// Loads past feedback: **`my-feedbacks`** when logged in; **guest:** detail for tracked order.
  Future<void> loadPastFeedbacks() async {
    if (!isLoggedIn) {
      _pastFeedbacksLoading = true;
      _pastFeedbacksError = null;
      notifyListeners();
      _pastOrders.clear();
      try {
        final int? oid = activeTrackOrderId.value;
        final String? gt = guestToken;
        if (oid != null && oid > 0 && gt != null && gt.isNotEmpty) {
          await _injectPastRowFromDetailIfMissing(oid, guestToken: gt);
        }
        _mergeOptimisticPastRows(<PastOrderFeedbackModel>[]);
        await _enrichLoadedPastOrdersInPlace(guestToken: gt);
        _rebuildFeedbackOrderIdsFromPastList();
      } catch (_) {}
      _pastFeedbacksLoading = false;
      notifyListeners();
      return;
    }

    _pastFeedbacksLoading = true;
    _pastFeedbacksError = null;
    notifyListeners();

    try {
      final List<PastOrderFeedbackModel> rows = await fetchMyFeedbacksList();
      _pastOrders
        ..clear()
        ..addAll(rows);
      _mergeOptimisticPastRows(rows);
      await _enrichLoadedPastOrdersInPlace();
      _rebuildFeedbackOrderIdsFromPastList();
    } on OrdersApiException catch (e) {
      _pastFeedbacksError =
          parseOrdersErrorMessage(e.body) ?? 'Could not load your feedback.';
      _pastOrders.clear();
    } catch (_) {
      _pastFeedbacksError = 'Could not load your feedback.';
      _pastOrders.clear();
    } finally {
      _pastFeedbacksLoading = false;
      notifyListeners();
    }
  }

  void _mergeOptimisticPastRows(List<PastOrderFeedbackModel> apiRows) {
    final Set<int> apiOrderIds = <int>{};
    for (final PastOrderFeedbackModel r in apiRows) {
      final int? id = int.tryParse(r.orderNumber.trim());
      if (id != null && id > 0) {
        apiOrderIds.add(id);
      }
    }
    _optimisticPastByOrderId.removeWhere(
      (int oid, _) => apiOrderIds.contains(oid),
    );
    for (final MapEntry<int, PastOrderFeedbackModel> e
        in _optimisticPastByOrderId.entries) {
      final int oid = e.key;
      final bool has = _pastOrders.any(
        (PastOrderFeedbackModel r) =>
            int.tryParse(r.orderNumber.trim()) == oid,
      );
      if (!has) {
        _pastOrders.insert(0, e.value);
      }
    }
  }

  void _rebuildFeedbackOrderIdsFromPastList() {
    _orderIdsWithFeedback.clear();
    for (final PastOrderFeedbackModel r in _pastOrders) {
      final int? id = int.tryParse(r.orderNumber.trim());
      if (id != null && id > 0) {
        _orderIdsWithFeedback.add(id);
      }
    }
    for (final int oid in _optimisticPastByOrderId.keys) {
      _orderIdsWithFeedback.add(oid);
    }
  }

  /// Fetches **`GET /orders/{id}/`** so Past Orders shows real dish lines (not only `Order #id`).
  Future<void> _enrichLoadedPastOrdersInPlace({String? guestToken}) async {
    if (_pastOrders.isEmpty) return;
    final List<PastOrderFeedbackModel> next =
        await Future.wait(_pastOrders.map(
      (PastOrderFeedbackModel r) =>
          _enrichPastRowLineItemsFromOrderApi(r, guestToken: guestToken),
    ));
    _pastOrders
      ..clear()
      ..addAll(next);
  }

  Future<PastOrderFeedbackModel> _enrichPastRowLineItemsFromOrderApi(
    PastOrderFeedbackModel row, {
    String? guestToken,
  }) async {
    if (!row.lineItemsNeedOrderFetch) return row;
    final int? oid = int.tryParse(row.orderNumber.trim());
    if (oid == null || oid <= 0) return row;
    try {
      final Map<String, dynamic> m =
          await fetchOrder(oid, guestToken: guestToken);
      final List<String> names =
          PastOrderFeedbackModel.itemNamesFromOrderDetailMap(m);
      if (names.isEmpty) return row;
      return row.withItemNames(names);
    } catch (_) {
      return row;
    }
  }

  Future<void> _injectPastRowFromDetailIfMissing(
    int orderId, {
    String? guestToken,
  }) async {
    if (_pastOrders.any(
          (PastOrderFeedbackModel e) =>
              int.tryParse(e.orderNumber.trim()) == orderId,
        )) {
      return;
    }
    try {
      final OrderFeedbackDetail? d =
          await fetchOrderFeedbackDetail(orderId, guestToken: guestToken);
      if (d == null) return;
      _pastOrders.insert(0, d.toPastOrderCardModel());
      _orderIdsWithFeedback.add(orderId);
      notifyListeners();
    } catch (_) {}
  }

  /// Reload orders (signed-in) or guest session order when opening Write Feedback.
  Future<void> prepareWriteFeedbackTab() async {
    refreshGuestOrderFromSession();
    if (!isLoggedIn) {
      _ordersLoading = false;
      _ordersError = null;
      _myOrders = <MyOrderModel>[];
      _selectedOrderId = guestOrderId;
      notifyListeners();
      return;
    }

    _ordersLoading = true;
    _ordersError = null;
    notifyListeners();

    try {
      _myOrders = await fetchMyOrdersList();
      try {
        final List<PastOrderFeedbackModel> existing =
            await fetchMyFeedbacksList();
        _orderIdsWithFeedback.clear();
        for (final PastOrderFeedbackModel r in existing) {
          final int? id = int.tryParse(r.orderNumber.trim());
          if (id != null && id > 0) {
            _orderIdsWithFeedback.add(id);
          }
        }
        for (final int oid in _optimisticPastByOrderId.keys) {
          _orderIdsWithFeedback.add(oid);
        }
      } catch (_) {
        _rebuildFeedbackOrderIdsFromPastList();
      }

      final List<MyOrderModel> eligible = ordersEligibleForNewFeedback
          .where((MyOrderModel o) => o.status != MyOrderStatus.cancelled)
          .toList();
      final List<MyOrderModel> pickFrom =
          eligible.isNotEmpty ? eligible : ordersEligibleForNewFeedback;

      if (pickFrom.isEmpty) {
        _selectedOrderId = null;
      } else {
        final bool stillValid = _selectedOrderId != null &&
            pickFrom.any(
              (MyOrderModel o) => (o.orderIdParsed ?? 0) == _selectedOrderId,
            );
        if (!stillValid) {
          _selectedOrderId =
              pickFrom.first.orderIdParsed ?? int.tryParse(pickFrom.first.orderNo);
        }
      }
    } on OrdersApiException catch (e) {
      _ordersError =
          parseOrdersErrorMessage(e.body) ?? 'Could not load your orders.';
      _myOrders = <MyOrderModel>[];
      _selectedOrderId = null;
    } catch (_) {
      _ordersError = 'Could not load your orders.';
      _myOrders = <MyOrderModel>[];
      _selectedOrderId = null;
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  void refreshGuestOrderFromSession() {
    if (isLoggedIn) return;
    final int? oid = activeTrackOrderId.value;
    if (_selectedOrderId != oid) {
      _selectedOrderId = oid;
      notifyListeners();
    }
  }

  Future<({String? error, String thanks})> submitWriteFeedback({
    required int rating,
    required String comment,
  }) async {
    final int? orderId = _resolveOrderIdForSubmit();
    if (orderId == null || orderId <= 0) {
      return (
        error: isLoggedIn
            ? 'Choose an order to rate.'
            : 'No order selected. Use Track Order after checkout, or log in to pick an order.',
        thanks: '',
      );
    }

    final String? gt = isLoggedIn ? null : guestToken;
    if (!isLoggedIn && (gt == null || gt.isEmpty)) {
      return (
        error:
            'Guest token missing. Open Track Order from your order URL or receipt.',
        thanks: '',
      );
    }

    final String trimmed = comment.trim();

    _submitting = true;
    notifyListeners();
    try {
      OrderFeedbackDetail? already;
      try {
        already = await fetchOrderFeedbackDetail(
          orderId,
          guestToken: gt,
        );
      } catch (_) {
        already = null;
      }
      if (already != null) {
        return (
          error:
              'You already submitted feedback for this order. Remove it from Past Orders first, or pick another order.',
          thanks: '',
        );
      }

      final SubmitOrderFeedbackResult res = await submitOrderFeedback(
        orderId,
        rating: rating.clamp(1, 5),
        comment: trimmed,
        guestToken: gt,
      );
      _optimisticPastByOrderId[orderId] = PastOrderFeedbackModel.fromSubmitSnapshot(
        orderId: orderId,
        rating: rating.clamp(1, 5),
        comment: trimmed,
      );
      await loadPastFeedbacks();
      await _injectPastRowFromDetailIfMissing(orderId, guestToken: gt);
      _rebuildFeedbackOrderIdsFromPastList();
      return (error: null, thanks: res.message);
    } on OrdersApiException catch (e) {
      return (
        error: parseOrdersErrorMessage(e.body) ?? 'Could not submit feedback.',
        thanks: '',
      );
    } catch (_) {
      return (error: 'Could not submit feedback.', thanks: '');
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  int? _resolveOrderIdForSubmit() {
    if (isLoggedIn) {
      if (_selectedOrderId != null && _selectedOrderId! > 0) {
        return _selectedOrderId;
      }
      if (_myOrders.isNotEmpty) {
        final MyOrderModel o = _myOrders.first;
        return o.orderIdParsed ?? int.tryParse(o.orderNo);
      }
      return null;
    }
    return guestOrderId ?? _selectedOrderId;
  }

  /// Deletes feedback on the server, then removes the row locally.
  Future<String?> deletePastFeedback(PastOrderFeedbackModel row) async {
    if (!row.showDelete) {
      return 'This entry cannot be deleted.';
    }
    final int? oid = int.tryParse(row.orderNumber.trim());
    if (oid == null || oid <= 0) {
      return 'Invalid order.';
    }
    try {
      await deleteOrderFeedback(
        oid,
        guestToken: isLoggedIn ? null : guestToken,
      );
      _pastOrders.removeWhere(
        (PastOrderFeedbackModel e) => e.orderNumber == row.orderNumber,
      );
      _optimisticPastByOrderId.remove(oid);
      _orderIdsWithFeedback.remove(oid);
      notifyListeners();
      return null;
    } on OrdersApiException catch (e) {
      return parseOrdersErrorMessage(e.body) ?? 'Could not delete feedback.';
    } catch (_) {
      return 'Could not delete feedback.';
    }
  }
}
