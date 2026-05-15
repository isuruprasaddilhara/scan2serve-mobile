/// Holds the latest menu categories + dish count for the chatbot assistant.
///
/// [HomeViewModel] updates this after each successful menu load. [ChatbotViewModel]
/// prefixes outbound `/chat/` messages so the model knows current categories, and
/// can show a short "menu synced" line when the user opens chat after an update.
class MenuContextSnapshot {
  const MenuContextSnapshot({
    required this.categories,
    required this.totalItems,
    required this.revision,
  });

  final List<String> categories;
  final int totalItems;
  final int revision;
}

class ChatbotMenuContextStore {
  ChatbotMenuContextStore._();
  static final ChatbotMenuContextStore instance = ChatbotMenuContextStore._();

  MenuContextSnapshot? _snapshot;
  int _lastAnnouncedRevision = -1;

  MenuContextSnapshot? get snapshot => _snapshot;

  void clear() {
    _snapshot = null;
    _lastAnnouncedRevision = -1;
  }

  /// Records menu layout after a successful API load. Bumps [MenuContextSnapshot.revision]
  /// only when categories or totals change.
  void updateFromMenu({
    required List<String> categories,
    required int totalItems,
  }) {
    if (categories.isEmpty && totalItems == 0) {
      clear();
      return;
    }
    final List<String> next = List<String>.from(categories);
    if (_snapshot != null &&
        _listEq(_snapshot!.categories, next) &&
        _snapshot!.totalItems == totalItems) {
      return;
    }
    final int nextRev = (_snapshot?.revision ?? 0) + 1;
    _snapshot = MenuContextSnapshot(
      categories: next,
      totalItems: totalItems,
      revision: nextRev,
    );
  }

  bool shouldAnnounceMenuRefresh() {
    final MenuContextSnapshot? s = _snapshot;
    if (s == null || s.categories.isEmpty) return false;
    return s.revision > _lastAnnouncedRevision;
  }

  void markMenuAnnouncedToUser() {
    final MenuContextSnapshot? s = _snapshot;
    if (s != null) {
      _lastAnnouncedRevision = s.revision;
    }
  }

  /// Shown once in chat when [shouldAnnounceMenuRefresh] is true.
  String buildAssistantMenuSyncLine() {
    final MenuContextSnapshot s = _snapshot!;
    final String preview = _formatCategories(s.categories, maxChars: 200);
    return 'Menu is up to date (${s.totalItems} dishes). Categories include '
        '$preview — ask me for ideas or tap Home to browse.';
  }

  /// Prepended to each user/FAQ message sent to `/chat/` (compact for tokens).
  String buildPromptPrefix() {
    final MenuContextSnapshot? s = _snapshot;
    if (s == null || s.categories.isEmpty) return '';
    final String cats = _formatCategories(s.categories, maxChars: 400);
    return '[Venue menu snapshot: ${s.totalItems} dishes; categories: $cats. '
        'When recommending food, only refer to categories and dishes that fit this list.]\n\n';
  }
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _formatCategories(List<String> cats, {required int maxChars}) {
  if (cats.isEmpty) return '';
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < cats.length; i++) {
    final String part = i == 0 ? cats[i] : ', ${cats[i]}';
    if (buf.length + part.length > maxChars) {
      buf.write(', …');
      break;
    }
    buf.write(part);
  }
  return buf.toString();
}
