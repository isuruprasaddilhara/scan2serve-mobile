import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:scan2serve/api/api_config.dart';
import 'package:scan2serve/api/auth_token_store.dart';

/// Paths that must not trigger a refresh retry (avoid loops).
bool _isNoRefreshRetryPath(String path) {
  final String p = path.startsWith('/') ? path : '/$path';
  return p.contains('/users/auth/refresh/') ||
      p.contains('/users/auth/login/') ||
      p.contains('/users/auth/register/') ||
      p.contains('/users/auth/forgot-password/');
}

/// Applies access (and refresh when rotated) from login / refresh JSON bodies.
void applyAuthTokensFromJsonMap(Map<String, dynamic> decoded) {
  final Map<String, dynamic>? user = decoded['user'] as Map<String, dynamic>?;
  String? access = user?['access'] as String?;
  String? refresh = user?['refresh'] as String?;
  access ??= decoded['access'] as String?;
  refresh ??= decoded['refresh'] as String?;
  if (access != null && access.trim().isNotEmpty) {
    setAccessToken(access.trim());
  }
  final String? newRefresh = refresh?.trim();
  if (newRefresh != null && newRefresh.isNotEmpty) {
    setRefreshToken(newRefresh);
  }
}

Future<bool> _doRefreshPost(String refreshToken) async {
  final Uri uri = Uri.parse('$kApiBaseUrl/users/auth/refresh/');
  final http.Response res = await http.post(
    uri,
    headers: const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(<String, String>{'refresh': refreshToken}),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    return false;
  }
  try {
    final dynamic decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      applyAuthTokensFromJsonMap(decoded);
      return authAccessToken.value != null &&
          authAccessToken.value!.trim().isNotEmpty;
    }
  } catch (_) {}
  return false;
}

Future<bool>? _refreshInFlight;

/// Uses [authRefreshToken] to obtain a new access token via
/// `POST /users/auth/refresh/` with body `{"refresh": "..."}`.
///
/// Concurrent callers share one in-flight refresh. Returns true when a new
/// access token was stored.
Future<bool> refreshAccessTokenIfPossible() async {
  if (_refreshInFlight != null) {
    return _refreshInFlight!;
  }
  final String? refresh = authRefreshToken.value?.trim();
  if (refresh == null || refresh.isEmpty) {
    return false;
  }
  _refreshInFlight = _doRefreshPost(refresh).whenComplete(() {
    _refreshInFlight = null;
  });
  return _refreshInFlight!;
}

/// True when a 401 may mean an expired access token (retry refresh + request).
bool shouldAttemptSessionRecoveryForPath(String path) {
  return !_isNoRefreshRetryPath(path);
}
