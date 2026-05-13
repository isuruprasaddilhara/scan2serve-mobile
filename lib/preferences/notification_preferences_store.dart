import 'package:flutter/foundation.dart';

/// In-memory preference synced from Settings → Push Notifications.
/// Wire to SharedPreferences or your backend when available.
final ValueNotifier<bool> pushNotificationsEnabled = ValueNotifier<bool>(true);
