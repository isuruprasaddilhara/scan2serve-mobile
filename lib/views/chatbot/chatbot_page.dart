import 'package:flutter/material.dart';
import 'package:scan2serve/models/chatbot/chatbot_model.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/session/active_track_order_session.dart';
import 'package:scan2serve/viewmodels/chatbot/chatbot_view_model.dart';
import 'package:scan2serve/views/food/food_details_page.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/dish_image.dart';

/// Reference: soft lavender chat, white quick actions, carousel + dots, capsule input.
abstract final class _ChatUi {
  static const Color screenBg = Color(0xFFF3EDFA);
  static const Color botText = Color(0xFF3D3550);
  static const Color userBubble = Color(0xFFC9B6E8);
  static const Color bubbleTextDark = Color(0xFF1A1520);
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color quickBorder = Color(0xFFE8E0F0);
  static const Color sendPurple = Color(0xFF9B77D6);
  static const Color dishCardBg = Color(0xFFF7F2FC);
  static const Color dishCardBorder = Color(0xFFE8E0F0);
  static const Color closeGrey = Color(0xFF8A8099);
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final ChatbotViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatbotViewModel();
    _viewModel.addListener(_onVm);
  }

  void _onVm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _openTrackOrderPage(BuildContext context) {
    final int? oid = activeTrackOrderId.value;
    final String? guest = activeTrackGuestToken.value;
    final Widget page = oid != null
        ? TrackOrderPage(orderId: oid, guestToken: guest)
        : const TrackOrderPage();
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openFoodDetailsFromChatItem(ChatProductItem item) {
    final MenuItemModel m = MenuItemModel(
      name: item.name,
      priceLabel: item.priceLabel,
      description: item.description,
      menuItemId: item.menuItemId,
      imageUrl: item.imageUrl,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FoodDetailsPage(item: m),
      ),
    );
  }

  void _showDishMoreActions(BuildContext context, ChatProductItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8F4FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant_menu_rounded,
                    color: Color(0xFF3D2F5C)),
                title: const Text('View details'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openFoodDetailsFromChatItem(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onVm);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final data = _viewModel.screen;
        return Scaffold(
          backgroundColor: _ChatUi.screenBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChatHeader(
                  title: data.title,
                  logoAsset: data.logoAsset,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    itemCount: _viewModel.entries.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ChatEntryWidget(
                          entry: _viewModel.entries[index],
                          avatarAsset: data.avatarAsset,
                          quickRepliesEnabled: !_viewModel.isSending,
                          onFoodItemTap: _openFoodDetailsFromChatItem,
                          onFoodItemMore: (item) =>
                              _showDishMoreActions(context, item),
                          onFaqTopic: (display, prompt) {
                            final f = _viewModel.submitFaqTopicAnswer(
                                display, prompt);
                            f.ignore();
                          },
                          onQuickReply: (label) {
                            if (label ==
                                ChatbotViewModel.quickReplyTrackOrder) {
                              _openTrackOrderPage(context);
                              return;
                            }
                            final f = _viewModel.onQuickReply(label);
                            f.ignore();
                          },
                        ),
                      );
                    },
                  ),
                ),
                _ChatInputBar(
                  controller: _viewModel.inputController,
                  hint: data.inputHint,
                  canSend: _viewModel.canSend,
                  isSending: _viewModel.isSending,
                  onSend: () {
                    final f = _viewModel.sendMessage();
                    f.ignore();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.logoAsset,
    required this.onClose,
  });

  final String title;
  final String logoAsset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFEDE4FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD4C4F0),
                  Color(0xFF9B77D6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B6AA3).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                logoAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child:
                      const Icon(Icons.restaurant_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ChatUi.titlePurple,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: _ChatUi.closeGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntryWidget extends StatelessWidget {
  const _ChatEntryWidget({
    required this.entry,
    required this.avatarAsset,
    required this.quickRepliesEnabled,
    required this.onQuickReply,
    required this.onFoodItemTap,
    required this.onFoodItemMore,
    required this.onFaqTopic,
  });

  final ChatListEntry entry;
  final String avatarAsset;
  final bool quickRepliesEnabled;
  final void Function(String) onQuickReply;
  final void Function(ChatProductItem item) onFoodItemTap;
  final void Function(ChatProductItem item) onFoodItemMore;
  final void Function(String displayLabel, String apiPrompt) onFaqTopic;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      ChatTextBubble(:final isUser, :final text) =>
        _TextBubbleRow(isUser: isUser, text: text, avatarAsset: avatarAsset),
      ChatQuickReplies(:final labels) => _QuickReplyColumn(
          labels: labels,
          enabled: quickRepliesEnabled,
          onTap: onQuickReply,
        ),
      ChatProductCardEntry(
        :final name,
        :final priceLabel,
        :final description,
        :final imageUrl,
      ) =>
        _ProductChatCard(
          name: name,
          priceLabel: priceLabel,
          description: description,
          imageUrl: imageUrl,
        ),
      ChatProductCarouselEntry(:final items) => _ProductCarousel(
          items: items,
          onOpenItem: onFoodItemTap,
          onMoreItem: onFoodItemMore,
        ),
      ChatFaqTabsEntry() => _ChatFaqTabsRow(
          avatarAsset: avatarAsset,
          enabled: quickRepliesEnabled,
          onTopic: onFaqTopic,
        ),
      ChatFaqAnswerEntry(:final pairs) =>
        _ChatFaqAnswerRow(avatarAsset: avatarAsset, pairs: pairs),
    };
  }
}

class _ChatFaqTabsRow extends StatelessWidget {
  const _ChatFaqTabsRow({
    required this.avatarAsset,
    required this.enabled,
    required this.onTopic,
  });

  final String avatarAsset;
  final bool enabled;
  final void Function(String displayLabel, String apiPrompt) onTopic;

  static const String _tab0Display =
      'Using Scan2Serve\n(app, orders & service)';
  static const String _tab1Display = 'Food, allergens &\ndietary needs';

  static const String _tab0Prompt =
      'You are helping a Scan2Serve food-ordering app customer. '
      'Topic: Using Scan2Serve — the mobile app, menu, cart & checkout, tracking orders, '
      'pickup, payments, accounts, and guest checkout.\n\n'
      'Reply ONLY using 6–10 blocks in this exact pattern (plain text, no markdown headings, '
      'no text before the first Q:). Each question must be a full sentence ending with ?\n\n'
      'Q: First clear customer question here?\n'
      'A: Short helpful answer. You may use 1–3 sentences.\n\n'
      'Q: Second question?\n'
      'A: Answer here.\n\n'
      '(repeat Q:/A: pairs only. Do not use bullet lists instead of Q:/A:.)';

  static const String _tab1Prompt =
      'You are helping a Scan2Serve food-ordering app customer. '
      'Topic: Food information, allergens, and dietary needs (vegetarian, vegan, halal, etc.). '
      'Remind the user to confirm serious allergies with restaurant staff.\n\n'
      'Reply ONLY using 6–10 blocks in this exact pattern (plain text, no markdown headings, '
      'no text before the first Q:). Each question must be a full sentence ending with ?\n\n'
      'Q: First clear customer question here?\n'
      'A: Short helpful answer. You may use 1–3 sentences.\n\n'
      'Q: Second question?\n'
      'A: Answer here.\n\n'
      '(repeat Q:/A: pairs only. Do not use bullet lists instead of Q:/A:.)';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 42,
                height: 42,
                color: const Color(0xFFD8CDF3),
                alignment: Alignment.center,
                child: const Icon(Icons.support_agent_rounded, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _FaqTopicButton(
                  label: _tab0Display,
                  enabled: enabled,
                  onPressed: () => onTopic(_tab0Display, _tab0Prompt),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FaqTopicButton(
                  label: _tab1Display,
                  enabled: enabled,
                  onPressed: () => onTopic(_tab1Display, _tab1Prompt),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTopicButton extends StatelessWidget {
  const _FaqTopicButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _ChatUi.quickBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: enabled ? _ChatUi.titlePurple : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatFaqAnswerRow extends StatelessWidget {
  const _ChatFaqAnswerRow({
    required this.avatarAsset,
    required this.pairs,
  });

  final String avatarAsset;
  final List<ChatFaqQaPair> pairs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 42,
                height: 42,
                color: const Color(0xFFD8CDF3),
                alignment: Alignment.center,
                child: const Icon(Icons.support_agent_rounded, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < pairs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _FaqQaCard(pair: pairs[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqQaCard extends StatelessWidget {
  const _FaqQaCard({required this.pair});

  final ChatFaqQaPair pair;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ChatUi.dishCardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ChatUi.dishCardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pair.question,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: _ChatUi.titlePurple,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: _ChatUi.quickBorder.withValues(alpha: 0.85),
              ),
            ),
            Text(
              'Answer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pair.answer,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: _ChatUi.botText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBubbleRow extends StatelessWidget {
  const _TextBubbleRow({
    required this.isUser,
    required this.text,
    required this.avatarAsset,
  });

  final bool isUser;
  final String text;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: _ChatUi.userBubble,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B7AB8).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: _ChatUi.bubbleTextDark,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 42,
                height: 42,
                color: const Color(0xFFD8CDF3),
                alignment: Alignment.center,
                child: const Icon(Icons.support_agent_rounded, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _ChatUi.userBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B7AB8).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: _ChatUi.bubbleTextDark,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickReplyColumn extends StatelessWidget {
  const _QuickReplyColumn({
    required this.labels,
    required this.enabled,
    required this.onTap,
  });

  final List<String> labels;
  final bool enabled;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final String label in labels)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.transparent,
              child: InkWell(
                onTap: enabled ? () => onTap(label) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ChatUi.quickBorder),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D3550),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCarousel extends StatefulWidget {
  const _ProductCarousel({
    required this.items,
    required this.onOpenItem,
    required this.onMoreItem,
  });

  final List<ChatProductItem> items;
  final void Function(ChatProductItem item) onOpenItem;
  final void Function(ChatProductItem item) onMoreItem;

  @override
  State<_ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<_ProductCarousel> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.48);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatProductItem> items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 268,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            padEnds: false,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final ChatProductItem p = items[index];
              return Padding(
                padding:
                    const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 4),
                child: _CarouselProductCard(
                  item: p,
                  onOpenDetails: () => widget.onOpenItem(p),
                  onMore: () => widget.onMoreItem(p),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            items.length,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color:
                      i == _page ? _ChatUi.sendPurple : const Color(0xFFCFC6DC),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarouselProductCard extends StatelessWidget {
  const _CarouselProductCard({
    required this.item,
    required this.onOpenDetails,
    required this.onMore,
  });

  final ChatProductItem item;
  final VoidCallback onOpenDetails;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ChatUi.dishCardBg,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetails,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ChatUi.dishCardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5A8F).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: DishImageCover(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    backgroundColor: const Color(0xFFECE4F5),
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E2440),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.priceLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D2F5C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.description.trim().isEmpty
                              ? ' '
                              : item.description,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _ChatUi.botText,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onMore,
                          icon: Icon(Icons.more_horiz_rounded,
                              color: Colors.grey.shade600),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(36, 32),
                            padding: EdgeInsets.zero,
                          ),
                          tooltip: 'More',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductChatCard extends StatelessWidget {
  const _ProductChatCard({
    required this.name,
    required this.priceLabel,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String priceLabel;
  final String description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1520),
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: DishImageCover(
              imageUrl: imageUrl,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            priceLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1520),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D3550),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.hint,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        6,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 6, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B5A8F).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Colors.grey.shade500,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      readOnly: isSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (canSend) onSend();
                      },
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF3D3550),
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: (canSend || isSending)
                ? _ChatUi.sendPurple
                : const Color(0xFFD0C4E0),
            shape: const CircleBorder(),
            elevation: (canSend || isSending) ? 3 : 0,
            shadowColor: _ChatUi.sendPurple.withValues(alpha: 0.45),
            child: InkWell(
              onTap: (canSend && !isSending) ? onSend : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 52,
                height: 52,
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1A1520),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF1A1520),
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
