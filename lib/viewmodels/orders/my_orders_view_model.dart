import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';

class MyOrdersViewModel extends ChangeNotifier {
  MyOrdersViewModel() {
    authAccessToken.addListener(_onAuthTokenChanged);
    unawaited(loadOrders());
  }

  static const String screenTitle = 'My Orders';
  static const Duration _pollInterval = Duration(seconds: 10);

  List<MyOrderModel> _orders = <MyOrderModel>[];
  bool _loading = true;
  String? _errorMessage;
  bool _notSignedIn = false;
  String? _lastLoadedToken;
  bool _loadInFlight = false;
  Timer? _pollTimer;
  bool _disposed = false;
  bool _appPaused = false;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get notSignedIn => _notSignedIn;

  List<MyOrderModel> get visibleOrders => _orders;

  /// Shown when [visibleOrders] is empty but the user is signed in and there was no load error.
  String get emptyListHint => 'No orders here yet';

  void _onAuthTokenChanged() {
    final String? t = authAccessToken.value?.trim();
    if (t != null && t.isNotEmpty && t != _lastLoadedToken && !_loadInFlight) {
      unawaited(loadOrders());
    }
  }

  void _stopLivePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// While the My Orders screen is open, refreshes order list and statuses on an interval.
  void startLivePolling() {
    if (_disposed || _appPaused || _notSignedIn) return;
    final String? t = authAccessToken.value?.trim();
    if (t == null || t.isEmpty) return;
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (_disposed || _appPaused || _notSignedIn || _loadInFlight) return;
      unawaited(loadOrders(silent: true));
    });
  }

  /// Pause background polling (e.g. app backgrounded). Matches [TrackOrderViewModel] lifecycle.
  void setAppPaused(bool paused) {
    if (_appPaused == paused) return;
    _appPaused = paused;
    if (paused) {
      _stopLivePolling();
    } else {
      if (!_notSignedIn && !_loadInFlight) {
        unawaited(loadOrders(silent: true));
      }
      startLivePolling();
    }
  }

  /// [silent] avoids full-screen loading and keeps the current list on transient errors.
  Future<void> loadOrders({bool silent = false}) async {
    final String? token = authAccessToken.value?.trim();
    if (token == null || token.isEmpty) {
      _stopLivePolling();
      _notSignedIn = true;
      _loading = false;
      _orders = <MyOrderModel>[];
      _errorMessage = null;
      _lastLoadedToken = null;
      _loadInFlight = false;
      if (!_disposed) notifyListeners();
      return;
    }
    if (_loadInFlight) return;
    _loadInFlight = true;
    _notSignedIn = false;
    if (!silent) {
      _loading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final List<MyOrderModel> next = await fetchMyOrdersList();
      _orders = next;
      _lastLoadedToken = token;
      _errorMessage = null;
    } on OrdersApiException catch (e) {
      if (!silent) {
        _orders = <MyOrderModel>[];
        _errorMessage =
            parseOrdersErrorMessage(e.body) ?? 'Could not load orders (${e.statusCode}).';
      }
    } catch (e) {
      if (!silent) {
        _orders = <MyOrderModel>[];
        _errorMessage = e.toString();
      }
    } finally {
      _loading = false;
      _loadInFlight = false;
      final String? stillSigned = authAccessToken.value?.trim();
      if (stillSigned != null && stillSigned.isNotEmpty) {
        startLivePolling();
      }
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopLivePolling();
    authAccessToken.removeListener(_onAuthTokenChanged);
    super.dispose();
  }

}
