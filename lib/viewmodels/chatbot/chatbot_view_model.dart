import 'package:flutter/material.dart';
import 'package:scan2serve/api/chatbot_api.dart';
import 'package:scan2serve/models/chatbot/chatbot_model.dart';

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

  static final List<ChatListEntry> _initialEntries = [
    ChatTextBubble(
      isUser: false,
      text:
          "Hello! Welcome to Scan2Serve. I'm here to help you order and answer questions.",
    ),
    ChatQuickReplies(
      labels: [
        'View Menu',
        'Track My Order',
        'Frequently Asked Questions',
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

  Future<void> _submitUserMessage(String text) async {
    final String t = text.trim();
    if (t.isEmpty) return;

    _entries.add(ChatTextBubble(isUser: true, text: t));
    _sending = true;
    notifyListeners();

    try {
      final reply = await postChatMessage(t);
      _entries.add(ChatTextBubble(isUser: false, text: reply));
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
