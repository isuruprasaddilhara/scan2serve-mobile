import 'package:flutter/material.dart';
import 'package:scan2serve/models/feedback/past_order_feedback_model.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/models/orders/my_order_model.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/feedback/feedback_ratings_view_model.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

/// Matches [SettingsPage] / profile styling (cards, labels, purple accents).
abstract final class _FeedbackUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF8B8499);
  static const Color sectionLabel = Color(0xFF8B6FC4);
  static const Color cardBorder = Color(0xFFE5DDEF);
  static const Color iconTileBg = Color(0xFFEDE4FA);
  static const Color accentPurple = Color(0xFF9B77D6);
  static const Color segmentTrack = Color(0xFFEDE4FA);
  static const Color segmentActive = Color(0xFF9B77D6);
  static const Color starPurple = Color(0xFF9B77D6);
  static const Color starEmpty = Color(0xFFD7D0E0);
}

class _FeedbackSectionLabel extends StatelessWidget {
  const _FeedbackSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _FeedbackUi.sectionLabel,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FeedbackUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class FeedbackRatingsPage extends StatefulWidget {
  const FeedbackRatingsPage({super.key});

  @override
  State<FeedbackRatingsPage> createState() => _FeedbackRatingsPageState();
}

class _FeedbackRatingsPageState extends State<FeedbackRatingsPage> {
  late final FeedbackRatingsViewModel _viewModel;
  late final TextEditingController _writeCommentController;
  int _writeRating = 5;

  void _onTrackSessionChanged() {
    if (_viewModel.tab == FeedbackTab.writeFeedback) {
      _viewModel.refreshGuestOrderFromSession();
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = FeedbackRatingsViewModel();
    _writeCommentController = TextEditingController();
    activeTrackOrderId.addListener(_onTrackSessionChanged);
    activeTrackGuestToken.addListener(_onTrackSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadPastFeedbacks();
    });
  }

  @override
  void dispose() {
    activeTrackOrderId.removeListener(_onTrackSessionChanged);
    activeTrackGuestToken.removeListener(_onTrackSessionChanged);
    _writeCommentController.dispose();
    _viewModel.dispose();
    super.dispose();
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
                _FeedbackTopBar(
                  title: FeedbackRatingsViewModel.screenTitle,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: _FeedbackCard(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _FeedbackSegmentedControl(
                        tab: _viewModel.tab,
                        onChanged: _viewModel.setTab,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _viewModel.tab == FeedbackTab.pastOrders
                      ? _PastOrdersList(
                          loading: _viewModel.pastFeedbacksLoading,
                          error: _viewModel.pastFeedbacksError,
                          loggedIn: _viewModel.isLoggedIn,
                          orders: _viewModel.pastOrders,
                          onDeleteFeedback: _viewModel.deletePastFeedback,
                          onRetry: _viewModel.loadPastFeedbacks,
                        )
                      : _WriteFeedbackPanel(
                          rating: _writeRating,
                          onRatingChanged: (v) => setState(() => _writeRating = v),
                          commentController: _writeCommentController,
                          submitting: _viewModel.submitting,
                          orderSection: _FeedbackOrderContextSection(
                            viewModel: _viewModel,
                          ),
                          onSubmit: () => _submitWriteFeedback(context),
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

  Future<void> _submitWriteFeedback(BuildContext context) async {
    final ({String? error, String thanks}) result =
        await _viewModel.submitWriteFeedback(
      rating: _writeRating,
      comment: _writeCommentController.text,
    );
    if (!context.mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.thanks),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _writeCommentController.clear();
    setState(() => _writeRating = 5);
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

class _FeedbackOrderContextSection extends StatelessWidget {
  const _FeedbackOrderContextSection({required this.viewModel});

  final FeedbackRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final FeedbackRatingsViewModel vm = viewModel;
    if (vm.isLoggedIn) {
      if (vm.ordersLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _FeedbackUi.accentPurple,
              ),
            ),
          ),
        );
      }
      if (vm.ordersError != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            vm.ordersError!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
              height: 1.35,
            ),
          ),
        );
      }
      final List<MyOrderModel> eligible = vm.ordersEligibleForNewFeedback;
      final List<MyOrderModel> allOrders = vm.myOrdersForFeedback;
      if (allOrders.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'No orders yet. Place an order, then leave feedback here.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        );
      }
      if (eligible.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'You’ve already submitted feedback for your orders. Delete a review under Past Orders if you need to change it.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        );
      }

      final List<MyOrderModel> orders = eligible;

      final List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
      for (final MyOrderModel o in orders) {
        final int? id = o.orderIdParsed ?? int.tryParse(o.orderNo);
        if (id == null || id <= 0) continue;
        items.add(
          DropdownMenuItem<int>(
            value: id,
            child: Text(
              '#${o.orderNo} · ${o.dateLabel} · ${o.amountLabel}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Could not read order numbers.',
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
          ),
        );
      }

      int? value = vm.selectedOrderId;
      if (value == null ||
          !items.any((DropdownMenuItem<int> e) => e.value == value)) {
        value = items.first.value;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (value != null) vm.setSelectedOrderId(value);
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedbackSectionLabel(text: 'Order'),
          _FeedbackCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _FeedbackUi.iconTileBg.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: value,
                    items: items,
                    onChanged: vm.submitting
                        ? null
                        : (int? v) {
                            if (v != null) vm.setSelectedOrderId(v);
                          },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    }

    final int? oid = vm.guestOrderId;
    if (oid != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedbackSectionLabel(text: 'Order'),
          _FeedbackCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _FeedbackUi.iconTileBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: _FeedbackUi.accentPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Feedback will be sent for Order #$oid',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _FeedbackUi.titlePurple,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeedbackSectionLabel(text: 'Order'),
        _FeedbackCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _FeedbackUi.iconTileBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _FeedbackUi.accentPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'After you order as a guest, open Track Order once so we can tie feedback to that order. Or log in to pick any past order.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _FeedbackTopBar extends StatelessWidget {
  const _FeedbackTopBar({
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
                color: _FeedbackUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FeedbackSegmentedControl extends StatelessWidget {
  const _FeedbackSegmentedControl({
    required this.tab,
    required this.onChanged,
  });

  final FeedbackTab tab;
  final ValueChanged<FeedbackTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _FeedbackUi.segmentTrack,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentChip(
              label: 'Past Orders',
              selected: tab == FeedbackTab.pastOrders,
              onTap: () => onChanged(FeedbackTab.pastOrders),
            ),
          ),
          Expanded(
            child: _SegmentChip(
              label: 'Write Feedback',
              selected: tab == FeedbackTab.writeFeedback,
              onTap: () => onChanged(FeedbackTab.writeFeedback),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _FeedbackUi.segmentActive : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF1A1520) : _FeedbackUi.titlePurple,
            ),
          ),
        ),
      ),
    );
  }
}

class _PastOrdersList extends StatelessWidget {
  const _PastOrdersList({
    required this.loading,
    required this.error,
    required this.loggedIn,
    required this.orders,
    required this.onDeleteFeedback,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final bool loggedIn;
  final List<PastOrderFeedbackModel> orders;
  final Future<String?> Function(PastOrderFeedbackModel order) onDeleteFeedback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _FeedbackUi.accentPurple,
          ),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: _FeedbackUi.accentPurple,
                  foregroundColor: const Color(0xFF1A1520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (orders.isEmpty) {
      if (!loggedIn) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _FeedbackCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Text(
                  'Log in for full feedback history. As a guest, open Track Order after checkout — feedback for your current order appears here when loaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _FeedbackCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Text(
                'No past feedback yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final PastOrderFeedbackModel order = orders[index];
        return _PastOrderFeedbackCard(
          order: order,
          onDelete: order.showDelete
              ? () => _confirmDeletePastFeedback(
                    context,
                    order,
                    onDeleteFeedback,
                  )
              : null,
        );
      },
    );
  }

  static Future<void> _confirmDeletePastFeedback(
    BuildContext context,
    PastOrderFeedbackModel order,
    Future<String?> Function(PastOrderFeedbackModel order) onDeleteFeedback,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feedback?'),
        content: Text(
          'Remove feedback for Order #${order.orderNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final String? err = await onDeleteFeedback(order);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback for Order #${order.orderNumber} removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PastOrderFeedbackCard extends StatelessWidget {
  const _PastOrderFeedbackCard({
    required this.order,
    required this.onDelete,
  });

  final PastOrderFeedbackModel order;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, onDelete != null ? 8 : 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _FeedbackUi.cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _FeedbackUi.titlePurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        order.dateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _FeedbackUi.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete feedback',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFE53935),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.itemsLine,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _FeedbackUi.titlePurple,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _StarRowDisplay(rating: order.ratingOutOf5),
          const SizedBox(height: 10),
          Text(
            '"${order.comment}"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5C5470),
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _StarRowDisplay extends StatelessWidget {
  const _StarRowDisplay({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final bool filled = i < rating;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
          child: Icon(
            Icons.star_rounded,
            size: 26,
            color: filled ? _FeedbackUi.starPurple : _FeedbackUi.starEmpty,
          ),
        );
      }),
    );
  }
}

class _WriteFeedbackPanel extends StatelessWidget {
  const _WriteFeedbackPanel({
    required this.rating,
    required this.onRatingChanged,
    required this.commentController,
    required this.onSubmit,
    required this.submitting,
    required this.orderSection,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController commentController;
  final VoidCallback onSubmit;
  final bool submitting;
  final Widget orderSection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        orderSection,
        const _FeedbackSectionLabel(text: 'Rating'),
        _FeedbackCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (int i) {
                final int star = i + 1;
                final bool filled = star <= rating;
                return IconButton(
                  onPressed: submitting
                      ? null
                      : () => onRatingChanged(star),
                  icon: Icon(
                    Icons.star_rounded,
                    size: 36,
                    color:
                        filled ? _FeedbackUi.starPurple : _FeedbackUi.starEmpty,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const _FeedbackSectionLabel(text: 'Comments'),
        _FeedbackCard(
          child: TextField(
            controller: commentController,
            readOnly: submitting,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Share your feedback…',
              hintStyle: TextStyle(
                color: _FeedbackUi.muted.withValues(alpha: 0.85),
                fontSize: 14,
              ),
              filled: true,
              fillColor: _FeedbackUi.iconTileBg.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _FeedbackUi.accentPurple,
              foregroundColor: const Color(0xFF1A1520),
              disabledBackgroundColor:
                  _FeedbackUi.accentPurple.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A1520),
                    ),
                  )
                : const Text('Submit Feedback'),
          ),
        ),
      ],
    );
  }
}
