import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/app_navigator.dart';
import 'package:scan2serve/views/welcome/welcome_page.dart';
import 'package:scan2serve/widgets/brand_hero_tags.dart';

/// Branded intro with logo/title motion before [WelcomePage].
class WelcomeAnimationPage extends StatefulWidget {
  const WelcomeAnimationPage({super.key});

  @override
  State<WelcomeAnimationPage> createState() => _WelcomeAnimationPageState();
}

class _WelcomeAnimationPageState extends State<WelcomeAnimationPage>
    with TickerProviderStateMixin {
  static const Duration _minDisplay = Duration(milliseconds: 2200);

  static const double _largeLogo = 168;

  late final AnimationController _logoFade;
  late final AnimationController _titleSlide;

  late final Animation<Offset> _titleOffset;

  @override
  void initState() {
    super.initState();
    _logoFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _titleSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleSlide, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (mounted) await _titleSlide.forward();
    });

    _goWelcome();
  }

  Future<void> _goWelcome() async {
    await Future<void>.delayed(_minDisplay);
    if (!mounted) return;
    if (!_titleSlide.isCompleted) {
      await _titleSlide.forward();
    }
    if (!mounted) return;
    // No full-page route transition so [Hero] (logo + title) can fly to [WelcomePage].
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: routeWelcome),
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return const WelcomePage();
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return child;
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoFade.dispose();
    _titleSlide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(parent: _logoFade, curve: Curves.easeOut),
              child: Hero(
                tag: BrandHeroTags.logo,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/scan2serve_logo.png',
                      width: _largeLogo,
                      height: _largeLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant_menu_rounded,
                        size: _largeLogo * 0.55,
                        color: const Color(0xFF9B77D6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SlideTransition(
              position: _titleOffset,
              child: FadeTransition(
                opacity: _titleSlide,
                child: Hero(
                  tag: BrandHeroTags.title,
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      'Scan2Serve',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 45 * 0.9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF63468C),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
