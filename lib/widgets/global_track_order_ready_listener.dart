import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/models/track_order/order_status_mapping.dart';
import 'package:scan2serve/models/track_order/track_order_factory.dart';
import 'package:scan2serve/models/track_order/track_order_model.dart';
import 'package:scan2serve/navigation/app_navigator.dart';
import 'package:scan2serve/preferences/notification_preferences_store.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/services/track_order_notify_sound.dart';

/// Polls the post-checkout order ([activeTrackOrderId]) from any screen and
/// plays the ready tone + dialog when status becomes pickup-ready.
class GlobalTrackOrderReadyListener extends StatefulWidget {
  const GlobalTrackOrderReadyListener({super.key});

  @override
  State<GlobalTrackOrderReadyListener> createState() =>
      _GlobalTrackOrderReadyListenerState();
}

class _GlobalTrackOrderReadyListenerState extends State<GlobalTrackOrderReadyListener>
    with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 18);

  Timer? _pollTimer;
  bool _tickInFlight = false;
  bool _appPaused = false;
  int? _boundOrderId;
  String? _priorStatusRaw;
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    activeTrackOrderId.addListener(_onSessionOrGuestChanged);
    activeTrackGuestToken.addListener(_onSessionOrGuestChanged);
    authAccessToken.addListener(_onAuthChanged);
    pushNotificationsEnabled.addListener(_onNotifyPrefChanged);
    unawaited(_refreshCustomerName());
    _onSessionOrGuestChanged();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    activeTrackOrderId.removeListener(_onSessionOrGuestChanged);
    activeTrackGuestToken.removeListener(_onSessionOrGuestChanged);
    authAccessToken.removeListener(_onAuthChanged);
    pushNotificationsEnabled.removeListener(_onNotifyPrefChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appPaused = true;
      _pollTimer?.cancel();
      _pollTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _appPaused = false;
      _restartPoller();
      unawaited(_pollOnce());
    }
  }

  void _onSessionOrGuestChanged() {
    final int? id = activeTrackOrderId.value;
    if (id != _boundOrderId) {
      _boundOrderId = id;
      _priorStatusRaw = null;
    }
    _restartPoller();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pollOnce());
    });
  }

  void _onAuthChanged() {
    unawaited(_refreshCustomerName());
  }

  void _onNotifyPrefChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pollOnce());
    });
  }

  void _restartPoller() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_appPaused) return;
    final int? id = activeTrackOrderId.value;
    if (id == null || id <= 0) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_pollOnce()));
  }

  Future<void> _refreshCustomerName() async {
    final String? jwt = authAccessToken.value?.trim();
    if (jwt == null || jwt.isEmpty) {
      if (mounted) setState(() => _customerName = '');
      return;
    }
    try {
      final Map<String, dynamic> me = await fetchCustomerMe();
      String n = (me['name'] as String?)?.trim() ?? '';
      if (n.isEmpty) {
        n = (me['first_name'] as String?)?.trim() ?? '';
      }
      if (n.isEmpty) {
        final String email = (me['email'] as String?)?.trim() ?? '';
        if (email.contains('@')) {
          n = email.split('@').first;
        }
      }
      if (mounted) setState(() => _customerName = n);
    } catch (_) {
      if (mounted) setState(() => _customerName = '');
    }
  }

  Future<void> _pollOnce() async {
    if (!mounted || _appPaused || _tickInFlight) return;
    final int? id = activeTrackOrderId.value;
    if (id == null || id <= 0) return;

    _tickInFlight = true;
    try {
      final String? guestRaw = activeTrackGuestToken.value?.trim();
      final Map<String, dynamic> json = await fetchOrder(
        id,
        guestToken:
            (guestRaw == null || guestRaw.isEmpty) ? null : guestRaw,
      );
      if (!mounted) return;

      final String? statusRaw = json['status'] is String
          ? (json['status'] as String).trim()
          : (json['status'] != null ? '${json['status']}'.trim() : null);

      if (isOrderTrackFinished(statusRaw)) {
        _priorStatusRaw = null;
        _pollTimer?.cancel();
        _pollTimer = null;
        if (activeTrackOrderId.value == id) {
          clearActiveTrackOrderSession();
        }
        return;
      }

      final bool pushOn = pushNotificationsEnabled.value;
      final bool nowReady = isOrderReadyForPickupAlert(statusRaw);
      final bool wasReady = _priorStatusRaw != null &&
          isOrderReadyForPickupAlert(_priorStatusRaw);
      _priorStatusRaw = statusRaw;

      if (!pushOn || !nowReady || wasReady) return;

      final TrackOrderModel model = trackOrderModelFromOrdersApiJson(
        json,
        customerName: _customerName,
      );
      unawaited(TrackOrderNotifySound.play());
      _showReadyDialog(model);
    } on OrdersApiException {
      // Offline / 404 — try again on next tick.
    } catch (_) {
      // Ignore transient failures.
    } finally {
      _tickInFlight = false;
    }
  }

  void _showReadyDialog(TrackOrderModel order) {
    final BuildContext? navCtx = rootNavigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;

    final String name = order.customerName.trim();
    final String message = name.isEmpty
        ? 'Your order #${order.orderNumber} is ready!'
        : 'Your order #${order.orderNumber} is ready, $name!';

    showDialog<void>(
      context: navCtx,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.notifications_active_rounded,
            size: 40,
            color: Color(0xFF9B81D1),
          ),
          title: const Text(
            'Order ready',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D2F5C),
            ),
          ),
          content: _ReadyMessageCard(message: message),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9B81D1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ReadyMessageCard extends StatelessWidget {
  const _ReadyMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
          height: 1.45,
        ),
      ),
    );
  }
}
