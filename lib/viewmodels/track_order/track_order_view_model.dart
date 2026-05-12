import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/models/track_order/order_status_mapping.dart';
import 'package:scan2serve/models/track_order/track_order_factory.dart';
import 'package:scan2serve/models/track_order/track_order_model.dart';
import 'package:scan2serve/session/active_track_order_session.dart';

class TrackOrderViewModel extends ChangeNotifier {
  TrackOrderViewModel({
    TrackOrderModel? model,
    int? orderId,
    String? guestToken,
  }) {
    final String? gt = guestToken?.trim();
    _guestToken = (gt == null || gt.isEmpty) ? null : gt;

    if (model != null) {
      _model = model;
      _trackingOrderId =
          model.apiOrderId ?? int.tryParse(model.orderNumber.trim());
      _loading = false;
    } else if (orderId != null && orderId > 0) {
      _trackingOrderId = orderId;
      _loading = true;
      _loadInitial(orderId);
    } else {
      _loading = true;
      unawaited(_bootstrapImplicitOrder());
    }
  }

  static const Duration _pollInterval = Duration(seconds: 10);

  /// Guest checkout session token, if tracking via `X-Guest-Token`.
  String? _guestToken;

  /// Order id used for `GET /orders/{id}/` and polling.
  int? _trackingOrderId;

  TrackOrderModel? _model;
  bool _loading = false;
  String? _loadError;
  String _customerName = '';
  Timer? _pollTimer;
  bool _refreshInFlight = false;
  bool _appPaused = false;

  bool get isLoading => _loading;
  String? get loadError => _loadError;

  /// Loaded order from API / passed [model]. Null when there is nothing to track yet.
  TrackOrderModel? get trackedOrder => _model;

  bool get hasTrackedOrder => _model != null;

  bool _disposed = false;

  /// Pause/resume background polling (e.g. app lifecycle).
  void setAppPaused(bool paused) {
    if (_appPaused == paused) return;
    _appPaused = paused;
    if (paused) {
      _stopPolling();
    } else if (_trackingOrderId != null &&
        !_loading &&
        !isTerminalTrackPollingStatus(_model?.apiStatus)) {
      unawaited(_refreshSilently());
      _startPolling();
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startPolling() {
    if (_disposed ||
        _appPaused ||
        _trackingOrderId == null ||
        isTerminalTrackPollingStatus(_model?.apiStatus)) {
      return;
    }
    _stopPolling();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_refreshSilently());
    });
  }

  /// No explicit order: use post-checkout session, else latest **`my-orders`** row (logged-in).
  Future<void> _bootstrapImplicitOrder() async {
    final int? sessionOid = activeTrackOrderId.value;
    final String? sessionGt = activeTrackGuestToken.value?.trim();
    if (sessionOid != null && sessionOid > 0) {
      _trackingOrderId = sessionOid;
      if (sessionGt != null && sessionGt.isNotEmpty) {
        _guestToken = sessionGt;
      }
      await _loadInitial(sessionOid);
      return;
    }

    final String? jwt = authAccessToken.value?.trim();
    if (jwt != null && jwt.isNotEmpty) {
      try {
        final List<MyOrderModel> orders = await fetchMyOrdersList();
        if (orders.isNotEmpty) {
          final MyOrderModel o = orders.first;
          final int? oid = o.orderIdParsed ?? int.tryParse(o.orderNo);
          if (oid != null && oid > 0) {
            _trackingOrderId = oid;
            _guestToken = null;
            await _loadInitial(oid);
            return;
          }
        }
      } catch (_) {}
    }

    _loading = false;
    _model = null;
    _loadError = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _loadInitial(int orderId) async {
    final String? jwt = authAccessToken.value?.trim();
    if (jwt != null && jwt.isNotEmpty) {
      try {
        final me = await fetchCustomerMe();
        final name = (me['name'] as String?)?.trim() ?? '';
        final first = (me['first_name'] as String?)?.trim() ?? '';
        final fromName = name.isNotEmpty ? name : first;
        if (fromName.isNotEmpty) {
          _customerName = fromName;
        } else {
          final email = (me['email'] as String?)?.trim() ?? '';
          if (email.isNotEmpty) {
            _customerName = email.split('@').first;
          }
        }
      } catch (_) {
        // Profile unavailable (e.g. expired token handled elsewhere).
      }
    }

    try {
      final json = await fetchOrder(orderId, guestToken: _guestToken);
      _model = trackOrderModelFromOrdersApiJson(
        json,
        customerName: _customerName,
      );
      _loadError = null;
    } on OrdersApiException catch (e) {
      _loadError =
          parseOrdersErrorMessage(e.body) ?? 'Could not load order (${e.statusCode}).';
      _model = null;
    } catch (e) {
      _loadError = e.toString();
      _model = null;
    } finally {
      _loading = false;
      if (!_disposed) {
        notifyListeners();
        if (_model != null && !isTerminalTrackPollingStatus(_model!.apiStatus)) {
          _startPolling();
        }
      }
    }
  }

  Future<void> _refreshSilently() async {
    final int? id = _trackingOrderId;
    if (id == null || _disposed || _appPaused || _refreshInFlight) return;
    if (isTerminalTrackPollingStatus(_model?.apiStatus)) {
      _stopPolling();
      return;
    }
    _refreshInFlight = true;
    try {
      final json = await fetchOrder(id, guestToken: _guestToken);
      if (_disposed) return;
      _model = trackOrderModelFromOrdersApiJson(
        json,
        customerName: _customerName,
      );
      _loadError = null;
      if (isTerminalTrackPollingStatus(_model?.apiStatus)) {
        _stopPolling();
      }
      notifyListeners();
    } on OrdersApiException catch (e) {
      if (_disposed) return;
      if (e.statusCode == 404) {
        _stopPolling();
      }
      // Keep showing last good order; do not clear UI on transient errors.
    } catch (_) {
      // Same: keep last _model.
    } finally {
      _refreshInFlight = false;
    }
  }

  /// Pull latest order JSON after server-side actions (e.g. request bill).
  Future<void> refreshOrderFromApi() async {
    final int? id = _trackingOrderId;
    if (id == null || _disposed || _refreshInFlight) return;
    _refreshInFlight = true;
    try {
      final json = await fetchOrder(id, guestToken: _guestToken);
      if (_disposed) return;
      _model = trackOrderModelFromOrdersApiJson(
        json,
        customerName: _customerName,
      );
      _loadError = null;
      if (isTerminalTrackPollingStatus(_model?.apiStatus)) {
        _stopPolling();
      }
      notifyListeners();
    } on OrdersApiException catch (e) {
      if (_disposed) return;
      if (e.statusCode == 404) {
        _stopPolling();
      }
    } catch (_) {
      // Keep last _model.
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
