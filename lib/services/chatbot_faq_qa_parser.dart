import 'package:scan2serve/models/chatbot/chatbot_model.dart';

/// Parses assistant FAQ text into [ChatFaqQaPair] rows.
///
/// 1. Preferred: repeated `Q: ... A: ...` blocks (see chatbot prompts).
/// 2. Fallback: lines like `- Topic: answer body` (common model output).
List<ChatFaqQaPair> parseFaqQaFromAssistant(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) return <ChatFaqQaPair>[];

  final List<ChatFaqQaPair> fromQa = _parseExplicitQaBlocks(text);
  if (fromQa.isNotEmpty) return fromQa;

  return _parseBulletTopicColon(text);
}

List<ChatFaqQaPair> _parseExplicitQaBlocks(String text) {
  final RegExp block = RegExp(
    r'Q\s*:\s*([\s\S]+?)\s*A\s*:\s*([\s\S]+?)(?=(?:\n\s*)Q\s*:|\s*$)',
    caseSensitive: false,
  );
  final List<ChatFaqQaPair> out = <ChatFaqQaPair>[];
  for (final RegExpMatch m in block.allMatches(text)) {
    final String q = _clean(m.group(1) ?? '');
    final String a = _clean(m.group(2) ?? '');
    if (q.isEmpty || a.isEmpty) continue;
    out.add(ChatFaqQaPair(question: q, answer: a));
  }
  return out;
}

String _clean(String s) {
  return s
      .replaceAll(RegExp(r'\*+'), '')
      .replaceAll(RegExp(r'`+'), '')
      .replaceAll(RegExp(r'^\s*#+\s*', multiLine: true), '')
      .trim();
}

List<ChatFaqQaPair> _parseBulletTopicColon(String text) {
  final List<ChatFaqQaPair> out = <ChatFaqQaPair>[];
  for (final String rawLine in text.split('\n')) {
    final String line = rawLine.trim();
    if (line.isEmpty) continue;
    if (!RegExp(r'^[-•*]\s*').hasMatch(line)) continue;
    final String body = line.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim();
    final String cleaned = _clean(body);
    if (cleaned.isEmpty) continue;

    final int colon = cleaned.indexOf(':');
    if (colon > 1 && colon < 90) {
      final String topic = cleaned.substring(0, colon).trim();
      final String rest = cleaned.substring(colon + 1).trim();
      if (topic.isNotEmpty && rest.isNotEmpty) {
        final String q = topic.endsWith('?') ? topic : '$topic?';
        out.add(ChatFaqQaPair(question: q, answer: rest));
        continue;
      }
    }
    out.add(ChatFaqQaPair(question: 'Details', answer: cleaned));
  }
  return out;
}
