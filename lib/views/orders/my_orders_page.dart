import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scan2serve/api/orders_api.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/models/orders/order_detail_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/orders/order_details_page.dart';
import 'package:scan2serve/viewmodels/orders/my_orders_view_model.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _MyOrdersUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF8B8499);
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> with WidgetsBindingObserver {
  late final MyOrdersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = MyOrdersViewModel();
    _viewModel.startLivePolling();
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
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrdersTopBar(
                  title: MyOrdersViewModel.screenTitle,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _MyOrdersBody(
                    viewModel: _viewModel,
                    onViewDetails: (order) async {
                      final int? id = order.orderIdParsed;
                      OrderDetailModel detail =
                          OrderDetailModel.fromMyOrder(order);
                      if (id != null && id > 0) {
                        try {
                          final Map<String, dynamic> full =
                              await fetchOrder(id);
                          detail = OrderDetailModel.fromMyOrder(
                            MyOrderModel.fromOrdersApiMap(full),
                          );
                        } catch (_) {}
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderDetailsPage(detail: detail),
                        ),
                      );
                    },
                  ),
                ),
                ScanBottomNavBar(
                  activeNav: 'Profile',
                  onNavTap: (nav) => _onBottomNav(context, nav),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBottomNav(BuildContext context, String nav) {
    if (nav == 'Profile') {
      Navigator.of(context).pop();
      return;
    }
    if (nav == 'Home') {
      navigateToHomeAsRoot(context);
      return;
    }
    if (nav == 'Track') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TrackOrderPage()),
      );
    }
  }
}

class _MyOrdersBody extends StatelessWidget {
  const _MyOrdersBody({
    required this.viewModel,
    required this.onViewDetails,
  });

  final MyOrdersViewModel viewModel;
  final Future<void> Function(MyOrderModel order) onViewDetails;

  @override
  Widget build(BuildContext context) {
    if (viewModel.notSignedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 18),
              const Text(
                'Sign in to see your orders',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _MyOrdersUi.titlePurple,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your past orders from this account will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.isLoading &&
        viewModel.visibleOrders.isEmpty &&
        viewModel.errorMessage == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8F62E8)),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.visibleOrders.isEmpty &&
        !viewModel.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: _MyOrdersUi.muted,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => viewModel.loadOrders(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8F62E8),
                  foregroundColor: const Color(0xFF1A1520),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final List<MyOrderModel> orders = viewModel.visibleOrders;

    return RefreshIndicator(
      color: const Color(0xFF8F62E8),
      onRefresh: () => viewModel.loadOrders(silent: true),
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                Center(
                  child: Text(
                    viewModel.emptyListHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) {
                final MyOrderModel order = orders[i];
                return _OrderCard(
                  order: order,
                  onViewDetails: () => unawaited(onViewDetails(order)),
                );
              },
            ),
    );
  }
}

class _OrdersTopBar extends StatelessWidget {
  const _OrdersTopBar({required this.title, required this.onBackTap});

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: const Color(0xFF4B4360),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _MyOrdersUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onViewDetails,
  });

  final MyOrderModel order;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '#${order.orderNo}',
                style: const TextStyle(
                  fontSize: 35 * 0.58,
                  fontWeight: FontWeight.w800,
                  color: _MyOrdersUi.titlePurple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                order.tableNo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _MyOrdersUi.titlePurple,
                ),
              ),
              const Spacer(),
              _OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${order.itemCountLabel}  •  ${order.dateLabel}  •  ${order.amountLabel}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _MyOrdersUi.muted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD7C8F2)),
                foregroundColor: const Color(0xFF8F62E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final MyOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (String text, Color bg, Color fg) = switch (status) {
      MyOrderStatus.completed => (
          'Completed',
          const Color(0xFFE7F7EC),
          const Color(0xFF69AB80),
        ),
      MyOrderStatus.preparing => (
          'Preparing',
          const Color(0xFFFFF1E2),
          const Color(0xFFE59A43),
        ),
      MyOrderStatus.cancelled => (
          'Cancelled',
          const Color(0xFFFFECEF),
          const Color(0xFFD95C6E),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
