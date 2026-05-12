import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/app_navigator.dart';
import 'package:scan2serve/services/menu_deep_link.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/welcome/welcome_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Scan2ServeApp());
  Future<void>.microtask(() async {
    await startMenuDeepLinkListeners();
  });
}

class Scan2ServeApp extends StatelessWidget {
  const Scan2ServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Scan2Serve',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB58CE8)),
        scaffoldBackgroundColor: AppColors.screenBackground,
        useMaterial3: true,
      ),
      initialRoute: routeWelcome,
      routes: <String, WidgetBuilder>{
        routeWelcome: (_) => const WelcomePage(),
      },
    );
  }
}
