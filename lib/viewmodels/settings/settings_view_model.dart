import 'package:flutter/material.dart';
import 'package:scan2serve/preferences/notification_preferences_store.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String screenTitle = 'Settings';

  SettingsViewModel() {
    pushNotifications = pushNotificationsEnabled.value;
  }

  bool pushNotifications = true;

  void setPushNotifications(bool value) {
    if (pushNotifications == value) return;
    pushNotifications = value;
    pushNotificationsEnabled.value = value;
    notifyListeners();
  }

  void onNavigationRowTap(String id) {
    debugPrint('Settings row: $id');
  }
}
