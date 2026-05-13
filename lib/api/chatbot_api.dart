import 'dart:convert';

import 'package:scan2serve/api/api_client.dart';

/// POST /chat/ — OpenAI-backed assistant (sends JWT when logged in).
Future<String> postChatMessage(String message) async {
  final res = await apiPost('/chat/', body: {'message': message});
  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final reply = decoded['reply'] as String?;
    if (reply == null || reply.isEmpty) {
      throw ChatbotApiException(res.statusCode, res.body);
    }
    return reply;
  }
  throw ChatbotApiException(res.statusCode, res.body);
}

class ChatbotApiException implements Exception {
  ChatbotApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  String? get serverError {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      return m?['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'ChatbotApiException($statusCode): $body';
}
