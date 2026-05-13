import 'package:flutter/material.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _AboutUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF7E7790);
  static const Color iconBg = Color(0xFFEDE4FA);
  static const Color accent = Color(0xFF9B77D6);
  static const Color cardBorder = Color(0xFFE5DDEF);
}

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AboutBaseScaffold(
      title: 'Terms & Conditions',
      body: [
        _CardHeader(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          subtitle: 'Last updated: 30 April 2026',
        ),
        SizedBox(height: 18),
        _SectionText(
          title: '1. Acceptance of Terms',
          body:
              'By accessing and using Scan2Serve, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our services.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '2. Use of Service',
          body:
              'You agree to use Scan2Serve for lawful purposes only. You must not misuse our services in any way.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '3. Orders & Payments',
          body:
              'All orders are subject to availability. Prices are inclusive of applicable taxes. Payment must be made as per the selected method.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '4. Cancellation & Refunds',
          body:
              'Orders can be cancelled before they are confirmed. Refunds (if applicable) will be processed as per our policy.',
        ),
        SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_box_rounded, size: 18, color: _AboutUi.accent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'I have read and agree to the Terms & Conditions',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _AboutUi.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AboutBaseScaffold(
      title: 'Privacy Policy',
      body: [
        _CardHeader(
          icon: Icons.shield_outlined,
          title: 'Privacy Policy',
          subtitle: 'Last updated: 30 April 2026',
        ),
        SizedBox(height: 18),
        _SectionText(
          title: 'At Scan2Serve, we value your privacy',
          body:
              'We are committed to protecting your personal information and using it responsibly.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '1. Information We Collect',
          body:
              'We collect information you provide to us such as name, email, phone number, and order details.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '2. How We Use Information',
          body:
              'We use your information to process orders, improve our services, send notifications, and provide support.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '3. Information Sharing',
          body:
              'We do not sell or rent your personal information to third parties. We may share information with trusted service providers only to operate our services.',
        ),
        SizedBox(height: 12),
        _SectionText(
          title: '4. Your Choices',
          body:
              'You can update your information or communication preferences at any time in the app settings.',
        ),
      ],
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AboutBaseScaffold(
      title: 'About Us',
      body: [
        _CardHeader(
          icon: Icons.qr_code_2_rounded,
          title: 'Scan2Serve',
          subtitle: 'Version 1.0.0',
        ),
        SizedBox(height: 16),
        Text(
          'Scan2Serve is a smart restaurant ordering system that allows you to scan, order, and enjoy your food seamlessly.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: _AboutUi.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.menu_book_rounded,
          title: 'Easy Ordering',
          body: 'Scan QR, browse menu and order in seconds.',
        ),
        SizedBox(height: 12),
        _FeatureRow(
          icon: Icons.wifi_tethering_rounded,
          title: 'Real-time Updates',
          body: 'Track your order status in real-time.',
        ),
        SizedBox(height: 12),
        _FeatureRow(
          icon: Icons.verified_user_outlined,
          title: 'Secure & Reliable',
          body: 'Your data and payments are always protected.',
        ),
        SizedBox(height: 18),
        Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _AboutUi.titlePurple,
          ),
        ),
        SizedBox(height: 10),
        _ContactRow(icon: Icons.phone_outlined, text: '+92 300 1234567'),
        SizedBox(height: 8),
        _ContactRow(icon: Icons.mail_outline_rounded, text: 'support@scan2serve.com'),
        SizedBox(height: 8),
        _ContactRow(icon: Icons.language_rounded, text: 'www.scan2serve.online'),
      ],
    );
  }
}

class _AboutBaseScaffold extends StatelessWidget {
  const _AboutBaseScaffold({required this.title, required this.body});

  final String title;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(title: title, onBackTap: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _AboutUi.cardBorder),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: body,
                  ),
                ),
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
  }

  void _onBottomNav(BuildContext context, String nav) {
    if (nav == 'Profile') return;
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBackTap});

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
                color: _AboutUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _AboutUi.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _AboutUi.accent, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _AboutUi.titlePurple,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _AboutUi.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionText extends StatelessWidget {
  const _SectionText({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _AboutUi.titlePurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: _AboutUi.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _AboutUi.iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: _AboutUi.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _AboutUi.titlePurple,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.8,
                  height: 1.35,
                  color: _AboutUi.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _AboutUi.accent),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.2,
            color: _AboutUi.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
