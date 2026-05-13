import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:scan2serve/api/api_config.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/session/session_table.dart';

final AppLinks _appLinks = AppLinks();

/// Subscribes to menu QR / App Links and applies [table_no] + optional [token]
/// to the session.
///
/// Works for:
///   • Flutter Web  – reads `window.location` via [Uri.base] on startup.
///   • Android APK  – App Links (HTTPS) and custom scheme (scan2serve://).
///   • iOS          – Universal Links and custom scheme.
///
/// Allowed URL shapes:
///   https://scan2serve-1.web.app/?table_no=2&token=…      (web app, root path)
///   https://scan2serve.online/menu?table_no=2&token=…     (HTTPS deep link)
///   scan2serve://menu?table_no=2&token=…                  (custom scheme)
///
/// Optional extra hosts via dart-define:
///   --dart-define=MENU_QR_EXTRA_HOSTS=mobile.example.com,staging.example.com
Future<void> startMenuDeepLinkListeners() async {
  // ── Flutter Web ──────────────────────────────────────────────────────────
  // app_links does not read window.location on web. We do it ourselves.
  if (kIsWeb) {
    _handleIncomingMenuUri(Uri.base);
    return; // No stream to listen to on web – the page reloads for each link.
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

  setSessionTableId(table);
  setSessionTableCode('T$table');
  final String? tok = uri.queryParameters['token']?.trim();
  setSessionVisitToken((tok != null && tok.isNotEmpty) ? tok : null);

  SchedulerBinding.instance.addPostFrameCallback((_) {
    navigateToHomeFromRootNavigator();
  });
}

bool _isAllowedMenuQr(Uri uri) {
  final String scheme = uri.scheme.toLowerCase();

  // Custom scheme: scan2serve://menu?table_no=…
  if (scheme == 'scan2serve') {
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    return host == 'menu' || path.contains('menu');
  }

  if (scheme != 'http' && scheme != 'https') return false;

  final String host = uri.host.toLowerCase();
  if (!_allowedHosts().contains(host)) return false;

  // Accept root path (web app) OR any path that contains "menu".
  final String path = uri.path.toLowerCase();
  return path == '/' || path.isEmpty || path.contains('menu');
}

Set<String> _allowedHosts() {
  final Set<String> out = <String>{
    // Production web app (Firebase Hosting)
    'scan2serve-1.web.app',
    'scan2serve-1.firebaseapp.com',
    // Backend / landing domain
    'scan2serve.online',
    'www.scan2serve.online',
    // Backend IP (dev/staging)
    '35.188.107.160',
    // Local development
    'localhost',
    '127.0.0.1',
  };

  // Also add whatever host kApiBaseUrl resolves to.
  try {
    final Uri api = Uri.parse(kApiBaseUrl);
    if (api.host.isNotEmpty) {
      out.add(api.host.toLowerCase());
    }
  } catch (_) {}

  // Extra hosts via --dart-define=MENU_QR_EXTRA_HOSTS=a.com,b.com
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
