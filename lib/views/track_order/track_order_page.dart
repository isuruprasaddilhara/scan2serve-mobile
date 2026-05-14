import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/models/track_order/order_status_mapping.dart';
import 'package:scan2serve/models/track_order/track_order_model.dart';
import 'package:scan2serve/preferences/notification_preferences_store.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/viewmodels/track_order/track_order_view_model.dart';
import 'package:scan2serve/views/chatbot/chatbot_page.dart';
import 'package:scan2serve/views/profile/profile_page.dart';
import 'package:scan2serve/widgets/dish_image.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

/// Reference UI: soft lavenders, medium purple accent, light timeline.
abstract final class _TrackPalette {
  static const Color screenBg = Color(0xFFF8F4FF);
  static const Color cardBg = Color(0xFFF0E6FF);
  static const Color cardBorder = Color(0xFFE2D4F5);
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color bodyMuted = Color(0xFF8B8499);
  static const Color bodyTextDark = Color(0xFF3D3550);
  static const Color accentPurple = Color(0xFF9B81D1);
  static const Color timelineLine = Color(0xFFD4C4EB);
  static const Color timelineRing = Color(0xFFC4B5DC);
  static const Color controlDisabled = Color(0xFF8B8499);
}

int _trackDisplayActiveIndex(TrackOrderModel data) {
  if (data.apiStatus != null && data.apiStatus!.isNotEmpty) {
    return trackActiveStepIndexFromApiStatus(data.apiStatus!);
  }
  return data.activeStepIndex;
}

/// Cancel matches backend: only while status is `pending` (DELETE allowed).
bool _canCancelTrackOrder(TrackOrderModel data) {
  if (data.apiStatus != null) {
    return canCancelOrderFromApiStatus(data.apiStatus);
  }
  final int cookingIndex = data.steps.indexWhere(
    (TrackStepModel s) => s.label.toLowerCase().trim() == 'cooking',
  );
  final int blockFromIndex = cookingIndex >= 0 ? cookingIndex : 2;
  return data.activeStepIndex < blockFromIndex;
}

bool _isTrackOrderReadyForPickupAlert(TrackOrderModel data) {
  if (data.apiStatus != null && data.apiStatus!.trim().isNotEmpty) {
    return isOrderReadyForPickupAlert(data.apiStatus);
  }
  if (data.activeStepIndex < 0 || data.activeStepIndex >= data.steps.length) {
    return false;
  }
  return data.steps[data.activeStepIndex].label.toLowerCase().trim() == 'ready';
}

String _trackOrderReadyMessage(TrackOrderModel data) {
  final String name = data.customerName.trim();
  if (name.isEmpty) {
    return 'Your order #${data.orderNumber} is ready!';
  }
  return 'Your order #${data.orderNumber} is ready, $name!';
}

/// Shown only when push notifications are enabled in Settings.
String? _trackPushFooterText(TrackOrderModel data, bool pushEnabled) {
  if (!pushEnabled) return null;
  if (data.apiStatus != null && data.apiStatus!.trim().isNotEmpty) {
    if (isOrderTrackFinished(data.apiStatus)) return null;
    if (isOrderReadyForPickupAlert(data.apiStatus)) {
      return _trackOrderReadyMessage(data);
    }
  } else if (_isTrackOrderReadyForPickupAlert(data)) {
    return _trackOrderReadyMessage(data);
  }
  return "We'll notify you when your order is ready";
}

/// Bordered card for order status / ready copy on Track Order and in the popup.
class _TrackNotifyMessageBox extends StatelessWidget {
  const _TrackNotifyMessageBox({
    required this.message,
    this.isReady = false,
  });

  final String message;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final Color bg = isReady ? const Color(0xFFE8F5E9) : _TrackPalette.cardBg;
    final Color border =
        isReady ? const Color(0xFF66BB6A) : _TrackPalette.cardBorder;
    final Color textColor =
        isReady ? const Color(0xFF1B5E20) : _TrackPalette.bodyTextDark;
    final Color shadowTint = isReady
        ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
        : const Color(0xFF6B5A8F).withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: isReady ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: shadowTint,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.45,
        ),
      ),
    );
  }
}

class TrackOrderPage extends StatefulWidget {
  const TrackOrderPage({
    super.key,
    this.model,
    this.orderId,
    this.guestToken,
  });

  final TrackOrderModel? model;
  final int? orderId;
  final String? guestToken;

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> with WidgetsBindingObserver {
  late final TrackOrderViewModel _viewModel;
  bool _requestBillSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = TrackOrderViewModel(
      model: widget.model,
      orderId: widget.orderId,
      guestToken: widget.guestToken,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _viewModel.setAppPaused(state == AppLifecycleState.paused);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return Scaffold(
            backgroundColor: _TrackPalette.screenBg,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: _TrackPalette.accentPurple),
                    const SizedBox(height: 20),
                    Text(
                      'Loading order…',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _TrackPalette.bodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (_viewModel.loadError != null) {
          return Scaffold(
            backgroundColor: _TrackPalette.screenBg,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TrackTopBar(
                      title: 'Track Order',
                      onBackTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Could not load this order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _TrackPalette.titlePurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.loadError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _TrackPalette.bodyMuted,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        }
        if (!_viewModel.hasTrackedOrder) {
          return Scaffold(
            backgroundColor: _TrackPalette.screenBg,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrackTopBar(
                    title: 'Track Order',
                    onBackTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 72,
                            color: _TrackPalette.bodyMuted.withValues(alpha: 0.65),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'No order to track',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _TrackPalette.titlePurple,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'After you check out, open Track again to follow your order. '
                            'If you have not ordered yet, add items from the menu first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                              color: _TrackPalette.bodyMuted,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: _TrackPalette.accentPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BottomNavWithChatFab(
                    activeNav: 'Track',
                    onNavTap: (nav) => _onBottomNavTap(context, nav),
                    onChatTap: () => _openChatbot(context),
                  ),
                ],
              ),
            ),
          );
        }
        final TrackOrderModel data = _viewModel.trackedOrder!;
        final bool canCancel = _canCancelTrackOrder(data);
        final bool orderFinished = data.apiStatus != null &&
            data.apiStatus!.trim().isNotEmpty &&
            isOrderTrackFinished(data.apiStatus);
        return Scaffold(
          backgroundColor: _TrackPalette.screenBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrackTopBar(
                  title: data.title,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OrderSummaryCard(
                          dishName: data.dishName,
                          etaLabel: data.etaLabel,
                          imageUrl: data.imageUrl,
                          detailLines: data.summaryDetailLines,
                        ),
                        const SizedBox(height: 36),
                        _OrderTimeline(
                          steps: data.steps,
                          activeIndex: _trackDisplayActiveIndex(data),
                        ),
                        const SizedBox(height: 28),
                        if (orderFinished) ...[
                          Text(
                            (data.apiStatus ?? '').trim().toLowerCase() ==
                                    'cancelled'
                                ? 'This order was cancelled.'
                                : 'This order is completed. Thank you! Start a new order anytime from the menu.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: _TrackPalette.bodyTextDark,
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _requestBillSubmitting
                                  ? null
                                  : () => _onRequestBillTap(context),
                              icon: _requestBillSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.receipt_long_rounded, size: 20),
                              label: Text(_requestBillSubmitting ? 'Requesting…' : 'Request Bill'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _TrackPalette.titlePurple,
                                side: BorderSide(
                                  color: _TrackPalette.accentPurple.withValues(alpha: 0.85),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: canCancel
                                  ? () => _onCancelOrderTap(context)
                                  : null,
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text('Cancel Order'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: canCancel
                                    ? const Color(0xFFC62828)
                                    : _TrackPalette.controlDisabled,
                                side: BorderSide(
                                  color: canCancel
                                      ? const Color(0xFFE57373)
                                      : _TrackPalette.cardBorder,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          if (!canCancel) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Cooking has started — this order can’t be cancelled.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: _TrackPalette.bodyTextDark,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                        ValueListenableBuilder<bool>(
                          valueListenable: pushNotificationsEnabled,
                          builder: (context, pushOn, _) {
                            final String? footer =
                                _trackPushFooterText(data, pushOn);
                            if (footer == null) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 32),
                                _TrackNotifyMessageBox(
                                  message: footer,
                                  isReady: data.apiStatus != null &&
                                          data.apiStatus!.trim().isNotEmpty
                                      ? isOrderReadyForPickupAlert(data.apiStatus)
                                      : _isTrackOrderReadyForPickupAlert(data),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                BottomNavWithChatFab(
                  activeNav: 'Track',
                  onNavTap: (nav) => _onBottomNavTap(context, nav),
                  onChatTap: () => _openChatbot(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRequestBillTap(BuildContext context) async {
    final TrackOrderModel? order = _viewModel.trackedOrder;
    final int? oid = order?.apiOrderId;
    if (oid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active order.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _requestBillSubmitting = true);
    try {
      final RequestBillResult result =
          await requestBill(oid, guestToken: widget.guestToken);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _viewModel.refreshOrderFromApi();
    } on OrdersApiException catch (e) {
      if (!context.mounted) return;
      final String msg =
          parseOrdersErrorMessage(e.body) ?? 'Could not request bill (${e.statusCode}).';
      messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _requestBillSubmitting = false);
    }
  }

  void _openChatbot(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChatbotPage(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _onCancelOrderTap(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel order'),
          content: const Text(
            'Are you sure you want to cancel this order?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFF1A1520),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TrackOrderModel? order = _viewModel.trackedOrder;
    final int? oid = order?.apiOrderId;
    if (oid == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No active order to cancel.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await deleteOrder(oid, guestToken: widget.guestToken);
    } on OrdersApiException catch (e) {
      if (!context.mounted) return;
      final String msg =
          parseOrdersErrorMessage(e.body) ?? 'Could not cancel order (${e.statusCode}).';
      messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not cancel: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (activeTrackOrderId.value == oid) {
      clearActiveTrackOrderSession();
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Order cancelled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, String nav) {
    if (nav == 'Home') {
      navigateToHomeAsRoot(context);
      return;
    }
    if (nav == 'Track') {
      return;
    }
    if (nav == 'Profile') {
      final String? token = authAccessToken.value?.trim();
      if (token == null || token.isEmpty) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
      );
    }
  }
}

class _TrackTopBar extends StatelessWidget {
  const _TrackTopBar({
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: Color(0xFFEDE4FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            style: IconButton.styleFrom(
              foregroundColor: _TrackPalette.titlePurple,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: -0.15,
                color: _TrackPalette.titlePurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.dishName,
    required this.etaLabel,
    this.imageUrl,
    this.detailLines = const <String>[],
  });

  final String dishName;
  final String etaLabel;
  final String? imageUrl;
  final List<String> detailLines;

  static const double _imageSize = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TrackPalette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _TrackPalette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B6AA3).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          DishImageBox(
            width: _imageSize,
            height: _imageSize,
            imageUrl: imageUrl,
            borderRadius: BorderRadius.circular(_imageSize / 2),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dishName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _TrackPalette.titlePurple,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  etaLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3D3550),
                    height: 1.25,
                  ),
                ),
                if (detailLines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final String line in detailLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _TrackPalette.bodyMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({
    required this.steps,
    required this.activeIndex,
  });

  final List<TrackStepModel> steps;
  final int activeIndex;

  static const double _dotColumnWidth = 24;
  static const double _connectorHeight = 34;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _dotColumnWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimelineDot(
                      filled: i <= activeIndex,
                      isCurrent: i == activeIndex,
                    ),
                    if (i < steps.length - 1)
                      Center(
                        child: Container(
                          width: 2,
                          height: _connectorHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: i < activeIndex
                                ? _TrackPalette.accentPurple.withValues(alpha: 0.45)
                                : _TrackPalette.timelineLine,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    steps[i].label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: i == activeIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: i == activeIndex
                          ? _TrackPalette.accentPurple
                          : i < activeIndex
                              ? _TrackPalette.bodyTextDark
                              : _TrackPalette.bodyMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.filled,
    required this.isCurrent,
  });

  final bool filled;
  final bool isCurrent;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent
              ? _TrackPalette.accentPurple
              : _TrackPalette.accentPurple.withValues(alpha: 0.55),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: _TrackPalette.timelineRing,
          width: 1.5,
        ),
      ),
    );
  }
}
