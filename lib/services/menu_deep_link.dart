import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:scan2serve/api/api_config.dart';
import 'package:scan2serve/session/session_table.dart';

final AppLinks _appLinks = AppLinks();

/// Reads the table_no from the incoming QR / deep-link URL and stores it in
/// the session. Does NOT navigate — the welcome page handles that so the user
/// still goes through guest / login / sign-up before reaching the menu.
///
/// Works for:
///   • Flutter Web  – reads `window.location` via [Uri.base] on startup.
///   • Android APK  – App Links (HTTPS) and custom scheme (scan2serve://).
///   • iOS          – Universal Links and custom scheme.
///
/// Allowed URL shapes:
///   https://scan2serve-1.web.app/?table_no=2
///   https://scan2serve.online/menu?table_no=2
///   scan2serve://menu?table_no=2
///
/// Optional extra hosts via dart-define:
///   --dart-define=MENU_QR_EXTRA_HOSTS=mobile.example.com,staging.example.com
Future<void> startMenuDeepLinkListeners() async {
  // ── Flutter Web ──────────────────────────────────────────────────────────
  if (kIsWeb) {
    _handleIncomingMenuUri(Uri.base);
    return;
  }

  // ── Mobile (Android / iOS) ───────────────────────────────────────────────
  try {
    final Uri? initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleIncomingMenuUri(initial);
    }
  } catch (_) {}

  _appLinks.uriLinkStream.listen(_handleIncomingMenuUri);
}

void _handleIncomingMenuUri(Uri uri) {
  if (!_isAllowedMenuQr(uri)) return;
  final int? table = _parseTableNo(uri);
  if (table == null || table <= 0) return;

  // Just save the table — do NOT navigate.
  // The welcome page will navigate to home after the user picks guest/login/signup.
  setSessionTableId(table);
  setSessionTableCode('T$table');
}

bool _isAllowedMenuQr(Uri uri) {
  final String scheme = uri.scheme.toLowerCase();

  if (scheme == 'scan2serve') {
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    return host == 'menu' || path.contains('menu');
  }

  if (scheme != 'http' && scheme != 'https') return false;

  final String host = uri.host.toLowerCase();
  if (!_allowedHosts().contains(host)) return false;

  final String path = uri.path.toLowerCase();
  return path == '/' || path.isEmpty || path.contains('menu');
}

Set<String> _allowedHosts() {
  final Set<String> out = <String>{
    'scan2serve-1.web.app',
    'scan2serve-1.firebaseapp.com',
    'scan2serve.online',
    'www.scan2serve.online',
    '35.188.107.160',
    'localhost',
    '127.0.0.1',
  };

  try {
    final Uri api = Uri.parse(kApiBaseUrl);
    if (api.host.isNotEmpty) {
      out.add(api.host.toLowerCase());
    }
  } catch (_) {}

  const String extra =
      String.fromEnvironment('MENU_QR_EXTRA_HOSTS', defaultValue: '');
  for (final String part in extra.split(',')) {
    final String h = part.trim().toLowerCase();
    if (h.isNotEmpty) out.add(h);
  }

  return out;
}

int? _parseTableNo(Uri uri) {
  final Map<String, String> q = uri.queryParameters;
  final String? raw =
      q['table_no'] ?? q['table'] ?? q['table_id'] ?? q['tableNo'];
  if (raw == null || raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}