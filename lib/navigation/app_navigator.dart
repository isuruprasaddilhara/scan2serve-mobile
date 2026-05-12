import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';

/// Assign to [MaterialApp.navigatorKey]. Session expiry uses [routeWelcome] only (no import cycle).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Must match [MaterialApp.routes] entry used after forced logout.
const String routeWelcome = '/';

bool _logoutInProgress = false;

/// Clears JWT state and replaces the stack with the welcome/login route.
Future<void> forceLogoutAndNavigateToWelcome() async {
  if (_logoutInProgress) return;
  _logoutInProgress = true;
  try {
    clearAuthTokens();
    final NavigatorState? nav = rootNavigatorKey.currentState;
    if (nav != null && nav.mounted) {
      nav.pushNamedAndRemoveUntil(routeWelcome, (_) => false);
    }
  } finally {
    _logoutInProgress = false;
  }
}
