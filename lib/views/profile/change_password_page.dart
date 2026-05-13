import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _ChangePasswordUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF8B8499);
  static const Color fieldBorder = Color(0xFFE5DDEF);
  static const Color accent = Color(0xFF9B77D6);
  static const Color iconBg = Color(0xFFEDE4FA);
  static const Color buttonPurple = Color(0xFF8E6FD0);
  static const Color requirementMet = Color(0xFF2E7D32);
  static const Color requirementPending = Color(0xFFBDBDBD);
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _newValue => _newController.text;

  bool get _hasMinLength => _newValue.length >= 8;

  bool get _hasLettersAndNumbers {
    final String s = _newValue;
    return RegExp('[A-Za-z]').hasMatch(s) && RegExp('[0-9]').hasMatch(s);
  }

  bool get _hasSpecialChar =>
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(_newValue);

  bool get _allRequirementsMet =>
      _hasMinLength && _hasLettersAndNumbers && _hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChangePasswordTopBar(
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _LockHero()),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose a strong password that keeps your account safe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: _ChangePasswordUi.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PasswordField(
                      label: 'Current Password',
                      hint: 'Enter current password',
                      controller: _currentController,
                      obscure: _obscureCurrent,
                      onToggleObscure: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PasswordField(
                      label: 'New Password',
                      hint: 'Enter new password',
                      controller: _newController,
                      obscure: _obscureNew,
                      onToggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 14),
                    _RequirementRow(
                      met: _hasMinLength,
                      text: 'At least 8 characters',
                    ),
                    const SizedBox(height: 8),
                    _RequirementRow(
                      met: _hasLettersAndNumbers,
                      text: 'Contains letters and numbers',
                    ),
                    const SizedBox(height: 8),
                    _RequirementRow(
                      met: _hasSpecialChar,
                      text: 'Contains special character',
                    ),
                    const SizedBox(height: 18),
                    _PasswordField(
                      label: 'Confirm New Password',
                      hint: 'Confirm new password',
                      controller: _confirmController,
                      obscure: _obscureConfirm,
                      onToggleObscure: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _UpdatePasswordButton(
                      submitting: _submitting,
                      onPressed: _submitting
                          ? null
                          : () => _onUpdatePassword(context),
                    ),
                  ],
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

  Future<void> _onUpdatePassword(BuildContext context) async {
    final String? token = authAccessToken.value?.trim();
    if (token == null || token.isEmpty) {
      _toast(context, 'Please sign in to change your password.');
      return;
    }

    final String current = _currentController.text;
    final String newP = _newController.text;
    final String confirm = _confirmController.text;

    if (current.trim().isEmpty) {
      _toast(context, 'Enter your current password');
      return;
    }
    if (!_allRequirementsMet) {
      _toast(context, 'New password does not meet all requirements');
      return;
    }
    if (newP != confirm) {
      _toast(context, 'New password and confirmation do not match');
      return;
    }

    setState(() => _submitting = true);
    try {
      final String message = await changePassword(
        oldPassword: current,
        newPassword: newP,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } on UsersApiException catch (e) {
      if (!context.mounted) return;
      final String? parsed = parseChangePasswordErrorMessage(e.body);
      _toast(
        context,
        parsed ??
            (e.statusCode == 401
                ? 'Session expired. Please sign in again.'
                : e.statusCode == 400 || e.statusCode == 403
                    ? 'Could not update password. Check your current password.'
                    : 'Could not update password. Please try again.'),
      );
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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

class _ChangePasswordTopBar extends StatelessWidget {
  const _ChangePasswordTopBar({required this.onBackTap});

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
          const Expanded(
            child: Text(
              'Change Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ChangePasswordUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _LockHero extends StatelessWidget {
  const _LockHero();

  @override
  Widget build(BuildContext context) {
    const double size = 120;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _ChangePasswordUi.iconBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 56,
        color: _ChangePasswordUi.accent,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _ChangePasswordUi.muted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _ChangePasswordUi.titlePurple,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _ChangePasswordUi.muted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _ChangePasswordUi.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _ChangePasswordUi.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _ChangePasswordUi.accent,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _ChangePasswordUi.muted,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color c =
        met ? _ChangePasswordUi.requirementMet : _ChangePasswordUi.requirementPending;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: met ? c.withValues(alpha: 0.15) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: c, width: met ? 0 : 1.5),
          ),
          child: met
              ? Icon(Icons.check_rounded, size: 16, color: c)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: met ? c : _ChangePasswordUi.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdatePasswordButton extends StatelessWidget {
  const _UpdatePasswordButton({
    required this.onPressed,
    required this.submitting,
  });

  final VoidCallback? onPressed;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ChangePasswordUi.buttonPurple,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 54,
          child: Center(
            child: submitting
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1A1520),
                    ),
                  )
                : const Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1520),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
