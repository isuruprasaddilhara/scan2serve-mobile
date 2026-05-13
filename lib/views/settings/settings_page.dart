import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/settings/settings_view_model.dart';
import 'package:scan2serve/views/login/login_page.dart';
import 'package:scan2serve/views/profile/change_password_page.dart';
import 'package:scan2serve/views/profile/personal_information_page.dart';
import 'package:scan2serve/views/settings/about_info_pages.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _SettingsUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color sectionLabel = Color(0xFF8B6FC4);
  static const Color iconTileBg = Color(0xFFEDE4FA);
  static const Color cardBorder = Color(0xFFE5DDEF);
  static const Color switchPurple = Color(0xFF9B77D6);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
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
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsTopBar(
                  title: SettingsViewModel.screenTitle,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: authAccessToken,
                        builder: (context, token, _) {
                          final signedIn =
                              token != null && token.trim().isNotEmpty;
                          if (!signedIn) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionLabel(text: 'Account'),
                                const SizedBox(height: 10),
                                _GuestAccountCard(
                                  onLogin: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel(text: 'Account'),
                              const SizedBox(height: 10),
                              _SettingsCard(
                                children: [
                                  _ChevronTile(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Personal Information',
                                    onTap: () => _navRow(context, 'personal_info'),
                                  ),
                                  _divider,
                                  _ChevronTile(
                                    icon: Icons.lock_outline_rounded,
                                    label: 'Change Password',
                                    onTap: () =>
                                        _navRow(context, 'change_password'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                            ],
                          );
                        },
                      ),
                      const _SectionLabel(text: 'Preferences'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        children: [
                          _SwitchTile(
                            label: 'Push Notifications',
                            value: _viewModel.pushNotifications,
                            onChanged: _viewModel.setPushNotifications,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel(text: 'About'),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        children: [
                          _ChevronTile(
                            icon: Icons.description_outlined,
                            label: 'Terms & Conditions',
                            onTap: () => _navRow(context, 'terms'),
                          ),
                          _divider,
                          _ChevronTile(
                            icon: Icons.shield_outlined,
                            label: 'Privacy Policy',
                            onTap: () => _navRow(context, 'privacy'),
                          ),
                          _divider,
                          _ChevronTile(
                            icon: Icons.info_outline_rounded,
                            label: 'About Us',
                            onTap: () => _navRow(context, 'about_us'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ScanBottomNavBar(
                  activeNav: 'Profile',
                  onNavTap: (nav) => _onBottomNav(context, nav),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const Widget _divider = Divider(height: 1, thickness: 1, color: Color(0xFFEFE8F5));

  void _navRow(BuildContext context, String id) {
    _viewModel.onNavigationRowTap(id);
    final token = authAccessToken.value;
    final signedIn = token != null && token.trim().isNotEmpty;
    if ((id == 'personal_info' || id == 'change_password') && !signedIn) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (id == 'personal_info') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PersonalInformationPage(),
        ),
      );
      return;
    }
    if (id == 'change_password') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
      );
      return;
    }
    if (id == 'terms') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TermsConditionsPage()),
      );
      return;
    }
    if (id == 'privacy') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
      );
      return;
    }
    if (id == 'about_us') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AboutUsPage()),
      );
      return;
    }
  }

  void _onBottomNav(BuildContext context, String nav) {
    if (nav == 'Profile') {
      Navigator.of(context).pop();
      return;
    }
    if (nav == 'Home') {
      navigateToHomeAsRoot(context);
      return;
    }
    if (nav == 'Track') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TrackOrderPage()),
      );
    }
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar({
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: const Color(0xFF4B4360),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _SettingsUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SettingsUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _SettingsUi.iconTileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 26,
                  color: _SettingsUi.switchPurple,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Guest',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _SettingsUi.titlePurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Hey, guest user Make sure to log in for full access to your account, '
            'including personal information and password changes.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: _SettingsUi.switchPurple,
              foregroundColor: const Color(0xFF1A1520),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _SettingsUi.sectionLabel,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SettingsUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A8F).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ChevronTile extends StatelessWidget {
  const _ChevronTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _SettingsUi.iconTileBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: _SettingsUi.switchPurple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _SettingsUi.titlePurple,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _SettingsUi.titlePurple,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _SettingsUi.switchPurple.withValues(alpha: 0.5),
            activeThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}
