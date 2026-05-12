import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:scan2serve/api/api_config.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/token_refresh.dart';
import 'package:scan2serve/navigation/app_navigator.dart';

Map<String, String> _headers({
  Map<String, String>? extra,
  bool includeBearer = true,
}) {
  final h = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?extra,
  };
  if (includeBearer) {
    final t = authAccessToken.value;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
  }
  return h;
}

Uri _u(String path) {
  final p = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$kApiBaseUrl$p');
}

/// On 401 for protected routes: refresh once; if refresh fails, log out and go to welcome.
Future<http.Response> _withRefreshRecovery(
  String path,
  Future<http.Response> Function() send,
) async {
  http.Response res = await send();
  if (res.statusCode != 401 || !shouldAttemptSessionRecoveryForPath(path)) {
    return res;
  }
  final bool recovered = await refreshAccessTokenIfPossible();
  if (!recovered) {
    final bool hadCredentialSession =
        authAccessToken.value?.trim().isNotEmpty == true ||
            authRefreshToken.value?.trim().isNotEmpty == true;
    if (hadCredentialSession) {
      await forceLogoutAndNavigateToWelcome();
    }
    return res;
  }
  return send();
}

Future<http.Response> apiGet(
  String path, {
  Map<String, String>? headers,
  bool includeBearer = true,
}) {
  return _withRefreshRecovery(path, () async {
    return http.get(_u(path), headers: _headers(extra: headers, includeBearer: includeBearer));
  });
}

Future<http.Response> apiDelete(
  String path, {
  Map<String, String>? headers,
  bool includeBearer = true,
}) {
  return _withRefreshRecovery(path, () async {
    return http.delete(
      _u(path),
      headers: _headers(extra: headers, includeBearer: includeBearer),
    );
  });
}

Future<http.Response> apiPost(
  String path, {
  Object? body,
  Map<String, String>? headers,
  bool includeBearer = true,
}) {
  final String? encoded = body == null ? null : jsonEncode(body);
  return _withRefreshRecovery(path, () async {
    return http.post(
      _u(path),
      headers: _headers(extra: headers, includeBearer: includeBearer),
      body: encoded,
    );
  });
}

Future<http.Response> apiPatch(
  String path, {
  Object? body,
  Map<String, String>? headers,
  bool includeBearer = true,
}) {
  final String? encoded = body == null ? null : jsonEncode(body);
  return _withRefreshRecovery(path, () async {
    return http.patch(
      _u(path),
      headers: _headers(extra: headers, includeBearer: includeBearer),
      body: encoded,
    );
  });
}
