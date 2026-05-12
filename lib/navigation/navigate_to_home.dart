import 'package:flutter/material.dart';
import 'package:scan2serve/views/home/home_page.dart';

/// Clears the navigation stack and shows [HomePage] (menu), never [WelcomePage].
void navigateToHomeAsRoot(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomePage()),
    (_) => false,
  );
}
