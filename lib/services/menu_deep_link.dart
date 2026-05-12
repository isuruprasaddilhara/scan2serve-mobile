import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/scheduler.dart';
import 'package:scan2serve/api/api_config.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/session/session_table.dart';

final AppLinks _appLinks = AppLinks();

/// Subscribes to menu QR / App Links and applies [table_no] + optional [token] to the session.
///
/// **Install vs store:** Flutter only runs when the app is installed. To send users without the app
/// to Play Store / App Store, the **HTTPS URL printed on the QR** must point to a small web page
/// or **Firebase Dynamic Links / Branch** that detects the platform and opens the store, while
/// **App Links** (with `assetlinks.json` / Apple hosted association) open this app when installed.
///
/// Optional hosts: `--dart-define=MENU_QR_EXTRA_HOSTS=mobile.example.com,staging.example.com`
Future<void> startMenuDeepLinkListeners() async {
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
  // Custom scheme from manifest: scan2serve://menu?table_no=…
  if (scheme == 'scan2serve') {
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    return host == 'menu' || path.contains('menu');
  }
  if (scheme != 'http' && scheme != 'https') return false;

  final String host = uri.host.toLowerCase();
  if (!_allowedHosts().contains(host)) return false;

  // Accept if the URL has a table_no/table/tableNo query param (QR links like
  // https://scan2serve-1.web.app/?table_no=2&token=…) OR contains /menu in path.
  final Map<String, String> q = uri.queryParameters;
  final bool hasTableParam =
      q.containsKey('table_no') || q.containsKey('table') ||
      q.containsKey('table_id') || q.containsKey('tableNo');
  final String path = uri.path.toLowerCase();
  return hasTableParam || path.contains('menu');
}

Set<String> _allowedHosts() {
  final Set<String> out = <String>{
    'scan2serve.online',
    'www.scan2serve.online',
    'scan2serve-1.web.app',
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
    if (h.isNotEmpty) {
      out.add(h);
    }
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
