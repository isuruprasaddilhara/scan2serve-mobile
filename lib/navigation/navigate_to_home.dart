import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/app_navigator.dart';
import 'package:scan2serve/views/home/home_page.dart';

/// Clears the navigation stack and shows [HomePage] (menu), never [WelcomePage].
void navigateToHomeAsRoot(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomePage()),
    (_) => false,
  );
}

/// Same as [navigateToHomeAsRoot] but without a [BuildContext] (e.g. QR / app link handlers).
void navigateToHomeFromRootNavigator() {
  final NavigatorState? nav = rootNavigatorKey.currentState;
  if (nav == null || !nav.mounted) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomePage()),
    (_) => false,
  );
}
