import 'package:flutter/material.dart';
import 'package:scan2serve/models/welcome/welcome_model.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel();

  final WelcomeModel viewData = const WelcomeModel(
    logoAssetPath: 'assets/images/scan2serve_logo.png',
    brandName: 'Scan2Serve',
    title: 'Welcome!',
    subtitle: 'Sign Up or Login to continue',
    actions: [
      WelcomeActionModel(
        id: 'sign_up',
        label: 'Sign Up',
        textColor: Color(0xFF1A1520),
        backgroundColor: Color(0xFFB488E7),
      ),
      WelcomeActionModel(
        id: 'login',
        label: 'Login',
        textColor: Color(0xFF685487),
        backgroundColor: Color(0xFFFFFFFF),
      ),
      WelcomeActionModel(
        id: 'guest',
        label: 'Order as a Guest',
        textColor: Color(0xFF685487),
        backgroundColor: Color(0xFFFFFFFF),
      ),
    ],
  );

  void onActionTap(String actionId) {}
}
