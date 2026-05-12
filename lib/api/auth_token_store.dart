import 'package:flutter/foundation.dart';
import 'package:scan2serve/session/active_track_order_session.dart';

/// In-memory JWT access token. Call [setAccessToken] after login; wire
/// SharedPreferences later if you need persistence across restarts.
final ValueNotifier<String?> authAccessToken = ValueNotifier<String?>(null);

/// Optional refresh token from the same login response.
final ValueNotifier<String?> authRefreshToken = ValueNotifier<String?>(null);

void setAccessToken(String? token) {
  authAccessToken.value = token;
}

void setRefreshToken(String? token) {
  authRefreshToken.value = token;
}

void clearAuthTokens() {
  authAccessToken.value = null;
  authRefreshToken.value = null;
  clearActiveTrackOrderSession();
}
