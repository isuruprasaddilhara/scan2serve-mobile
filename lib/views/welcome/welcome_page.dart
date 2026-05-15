import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/services/cart_store.dart';
import 'package:scan2serve/models/welcome/welcome_model.dart';
import 'package:scan2serve/viewmodels/welcome/welcome_view_model.dart';
import 'package:scan2serve/views/home/home_page.dart';
import 'package:scan2serve/views/login/login_page.dart';
import 'package:scan2serve/views/signup/sign_up_page.dart';
import 'package:scan2serve/widgets/brand_hero_tags.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final WelcomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WelcomeViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final WelcomeModel data = _viewModel.viewData;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFF5F2FA),
                  Color(0xFFEEE8F7),
                  Color(0xFFE8DFF4),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 26),
                        Center(
                          child: Hero(
                            tag: BrandHeroTags.logo,
                            child: Material(
                              color: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  data.logoAssetPath,
                                  width: 94,
                                  height: 94,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 94 * 0.55,
                                    color: Color(0xFF9B77D6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Hero(
                          tag: BrandHeroTags.title,
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              data.brandName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 45 * 0.9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF63468C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48 * 0.9,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: Color(0xFF5B3E83),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 33 * 0.42,
                            color: Color(0xFF8F7AAE),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 44),
                        ..._buildActionButtons(data.actions),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActionButtons(List<WelcomeActionModel> actions) {
    final List<Widget> widgets = <Widget>[];

    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];

      widgets.add(
        _ActionButton(
          label: action.label,
          textColor: action.textColor,
          backgroundColor: action.backgroundColor,
          isPrimary: i == 0,
          onPressed: () => _handleActionTap(action.id),
        ),
      );

      if (i != actions.length - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }

    return widgets;
  }

  void _handleActionTap(String actionId) {
    _viewModel.onActionTap(actionId);
    if (actionId == 'sign_up') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SignUpPage(),
        ),
      );
    } else if (actionId == 'login') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
        ),
      );
    } else if (actionId == 'guest') {
      clearAuthTokens();
      CartStore.instance.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8064AF).withOpacity(isPrimary ? 0.34 : 0.18),
              blurRadius: isPrimary ? 14 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
