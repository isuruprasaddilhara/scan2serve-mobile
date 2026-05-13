import 'package:flutter/foundation.dart';

/// After checkout, the app remembers the latest order so **Track** can load it.
/// Logged-in users: [activeTrackGuestToken] is null (JWT used by [fetchOrder]).
/// Guests: set [activeTrackGuestToken] for `X-Guest-Token`.
final ValueNotifier<int?> activeTrackOrderId = ValueNotifier<int?>(null);
final ValueNotifier<String?> activeTrackGuestToken = ValueNotifier<String?>(null);

void setActiveTrackOrderSession(int orderId, {String? guestToken}) {
  activeTrackOrderId.value = orderId;
  final String? t = guestToken?.trim();
  activeTrackGuestToken.value = (t == null || t.isEmpty) ? null : t;
}

void clearActiveTrackOrderSession() {
  activeTrackOrderId.value = null;
  activeTrackGuestToken.value = null;
}
