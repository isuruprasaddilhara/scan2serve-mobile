import 'package:flutter/material.dart';
import 'package:scan2serve/api/chatbot_api.dart';
import 'package:scan2serve/models/chatbot/chatbot_model.dart';
import 'package:scan2serve/models/home/home_model.dart';
import 'package:scan2serve/services/chatbot_menu_catalog.dart';
import 'package:scan2serve/services/chatbot_faq_qa_parser.dart';

class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel() {
    _entries.addAll(_initialEntries);
    inputController.addListener(_onInputChanged);
  }

  final ChatbotScreenModel screen = const ChatbotScreenModel(
    title: 'Scan2Serve',
    inputHint: 'Type your message...',
    avatarAsset: 'assets/images/chatbot_avatar.png',
    logoAsset: 'assets/images/scan2serve_logo.png',
  );

  final TextEditingController inputController = TextEditingController();

  final List<ChatListEntry> _entries = [];

  List<ChatListEntry> get entries => List<ChatListEntry>.unmodifiable(_entries);

  bool _sending = false;
  bool get isSending => _sending;

  bool get canSend =>
      inputController.text.trim().isNotEmpty && !_sending;

  /// Opens [TrackOrderPage] when tapped as a quick reply (same label string).
  static const String quickReplyTrackOrder = 'Track My Order';

  /// Opens in-chat FAQ topic buttons (same label as quick reply).
  static const String quickReplyFaq = 'Frequently Asked Questions';

  static final List<ChatListEntry> _initialEntries = [
    ChatTextBubble(
      isUser: false,
      text:
          "Hello! Welcome to Scan2Serve. I'm here to help you order and answer questions.",
    ),
    ChatQuickReplies(
      labels: [
        'View Menu',
        quickReplyTrackOrder,
        quickReplyFaq,
      ],
    ),
  ];

  void _onInputChanged() {
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final String t = inputController.text.trim();
    if (t.isEmpty || _sending) return;
    inputController.clear();
    notifyListeners();
    await _submitUserMessage(t);
  }

  Future<void> onQuickReply(String label) async {
    if (_sending) return;
    await _submitUserMessage(label);
  }

  /// FAQ topic chip: shows [displayLabel] as the user line, sends [apiPrompt] to `/chat/`.
  Future<void> submitFaqTopicAnswer(String displayLabel, String apiPrompt) async {
    if (_sending) return;
    final String userLine =
        displayLabel.replaceAll('\n', ' ').replaceAll(RegExp(r' +'), ' ').trim();
    _entries.add(ChatTextBubble(isUser: true, text: userLine));
    _sending = true;
    notifyListeners();
    try {
      final String reply = await postChatMessage(apiPrompt);
      final List<ChatFaqQaPair> pairs = parseFaqQaFromAssistant(reply);
      if (pairs.isNotEmpty) {
        const int maxPairs = 16;
        final List<ChatFaqQaPair> clipped =
            pairs.length > maxPairs ? pairs.sublist(0, maxPairs) : pairs;
        _entries.add(ChatFaqAnswerEntry(pairs: clipped));
      } else {
        _entries.add(ChatTextBubble(isUser: false, text: reply));
      }
    } on ChatbotApiException catch (e) {
      _entries.add(
        ChatTextBubble(
          isUser: false,
          text: _messageForChatbotError(e),
        ),
      );
    } catch (_) {
      _entries.add(
        ChatTextBubble(
          isUser: false,
          text: 'Something went wrong. Check your connection and try again.',
        ),
      );
    }
    _sending = false;
    notifyListeners();
  }

  Future<void> _submitUserMessage(String text) async {
    final String t = text.trim();
    if (t.isEmpty) return;

    _entries.add(ChatTextBubble(isUser: true, text: t));
    _sending = true;
    notifyListeners();

    if (_tryAppendFaqTabs(t)) {
      _sending = false;
      notifyListeners();
      return;
    }

    if (await _tryAppendMenuCatalog(t)) {
      _sending = false;
      notifyListeners();
      return;
    }

    try {
      final reply = await postChatMessage(t);
      _entries.add(ChatTextBubble(isUser: false, text: reply));
      if (_isViewMenuMessage(t)) {
        await _appendViewMenuCarouselIfPossible();
      }
    } on ChatbotApiException catch (e) {
      _entries.add(
        ChatTextBubble(
          isUser: false,
          text: _messageForChatbotError(e),
        ),
      );
      if (_isViewMenuMessage(t)) {
        await _appendViewMenuCarouselIfPossible();
      }
    } catch (_) {
      _entries.add(
        ChatTextBubble(
          isUser: false,
          text: 'Something went wrong. Check your connection and try again.',
        ),
      );
      if (_isViewMenuMessage(t)) {
        await _appendViewMenuCarouselIfPossible();
      }
    }

    _sending = false;
    notifyListeners();
  }

  /// Local FAQ tabs; returns true when the chat API is skipped.
  bool _tryAppendFaqTabs(String userText) {
    if (userText.trim().toLowerCase() != quickReplyFaq.toLowerCase()) {
      return false;
    }
    _entries.add(ChatFaqTabsEntry());
    return true;
  }

  bool _isViewMenuMessage(String trimmed) => trimmed.toLowerCase() == 'view menu';

  /// After the assistant text for **View Menu**, shows live dish cards from `/menu/items/`.
  Future<void> _appendViewMenuCarouselIfPossible() async {
    try {
      const MenuCatalogMatch match = MenuCatalogMatch(
        tags: {MenuCatalogTag.all},
        botIntro: '',
      );
      final List<MenuItemModel> dishes = await loadMenuItemsForCatalog(match);
      if (dishes.isEmpty) return;
      _entries.add(_carouselEntryFromDishes(dishes));
    } catch (_) {}
  }

  ChatProductCarouselEntry _carouselEntryFromDishes(List<MenuItemModel> dishes) {
    return ChatProductCarouselEntry(
      items: dishes
          .map(
            (MenuItemModel m) => ChatProductItem(
              name: m.name,
              priceLabel: m.priceLabel,
              description: m.description,
              imageUrl: m.imageUrl,
              menuItemId: m.menuItemId,
            ),
          )
          .toList(growable: false),
    );
  }

  /// Local menu carousel (API + filters); returns true when the chat API must be skipped.
  Future<bool> _tryAppendMenuCatalog(String userText) async {
    final MenuCatalogMatch? match = parseMenuCatalogRequest(userText);
    if (match == null) return false;
    try {
      final List<MenuItemModel> dishes = await loadMenuItemsForCatalog(match);
      if (dishes.isEmpty) {
        _entries.add(
          ChatTextBubble(
            isUser: false,
            text:
                'No dishes matched that just now. Try another word (e.g. chicken, veg) or open the Home tab for the full menu.',
          ),
        );
        return true;
      }
      _entries.add(ChatTextBubble(isUser: false, text: match.botIntro));
      _entries.add(_carouselEntryFromDishes(dishes));
      return true;
    } catch (_) {
      _entries.add(
        ChatTextBubble(
          isUser: false,
          text:
              'Could not load the menu right now. Use the Home tab to browse dishes, or try again in a moment.',
        ),
      );
      return true;
    }
  }

  String _messageForChatbotError(ChatbotApiException e) {
    final fromServer = e.serverError;
    if (fromServer != null && fromServer.isNotEmpty) {
      return fromServer;
    }
    if (e.statusCode == 400) {
      return 'Invalid message. Please try a shorter question.';
    }
    if (e.statusCode == 401 || e.statusCode == 403) {
      return 'Please log in to use personalized answers about your orders.';
    }
    if (e.statusCode >= 500) {
      return 'The assistant is temporarily unavailable. Please try again later.';
    }
    return 'Could not reach the assistant (${e.statusCode}).';
  }

  @override
  void dispose() {
    inputController.removeListener(_onInputChanged);
    inputController.dispose();
    super.dispose();
  }
}
