/// Chrome / copy for the chatbot screen.
class ChatbotScreenModel {
  const ChatbotScreenModel({
    required this.title,
    required this.inputHint,
    required this.avatarAsset,
    required this.logoAsset,
  });

  final String title;
  final String inputHint;
  final String avatarAsset;
  final String logoAsset;
}

class ChatProductItem {
  const ChatProductItem({
    required this.name,
    required this.priceLabel,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String priceLabel;
  final String description;
  final String? imageUrl;
}

sealed class ChatListEntry {}

final class ChatTextBubble extends ChatListEntry {
  ChatTextBubble({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

final class ChatQuickReplies extends ChatListEntry {
  ChatQuickReplies({required this.labels});

  final List<String> labels;
}

/// Single tall card (legacy / simple replies).
final class ChatProductCardEntry extends ChatListEntry {
  ChatProductCardEntry({
    required this.name,
    required this.priceLabel,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String priceLabel;
  final String description;
  final String? imageUrl;
}

/// Horizontal carousel of dish cards (dots below).
final class ChatProductCarouselEntry extends ChatListEntry {
  ChatProductCarouselEntry({required this.items});

  final List<ChatProductItem> items;
}
