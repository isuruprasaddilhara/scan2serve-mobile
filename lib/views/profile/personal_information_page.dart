import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/formatting/phone_number_input.dart';
import 'package:scan2serve/navigation/navigate_to_home.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/views/track_order/track_order_page.dart';
import 'package:scan2serve/widgets/scan_bottom_nav_bar.dart';

abstract final class _PersonalInfoUi {
  static const Color titlePurple = Color(0xFF3D2F5C);
  static const Color muted = Color(0xFF8B8499);
  static const Color fieldBorder = Color(0xFFE5DDEF);
  static const Color accent = Color(0xFF9B77D6);
  static const Color avatarBg = Color(0xFFEDE4FA);
  static const LinearGradient saveGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFC9B6EC), Color(0xFF8E6FD0)],
  );
}

/// Loads the signed-in customer from [fetchCustomerMe] and saves with [patchCustomerMe].
class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadProfile()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final String? token = authAccessToken.value?.trim();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Please sign in to view your profile.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final Map<String, dynamic> me = await fetchCustomerMe();
      if (!mounted) return;
      _nameController.text = customerMeDisplayName(me);
      _emailController.text = (me['email'] as String?)?.trim() ?? '';
      _phoneController.text =
          normalizePhoneForTenDigitField(customerMePhone(me));
      setState(() => _loading = false);
    } on UsersApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = parseCustomerMePatchErrorMessage(e.body) ??
            'Could not load profile (${e.statusCode}).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _saveChanges() async {
    final String? token = authAccessToken.value?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in to save.');
      return;
    }
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    if (name.isEmpty) {
      _toast('Please enter your full name.');
      return;
    }
    if (email.isEmpty) {
      _toast('Please enter your email.');
      return;
    }
    if (!isValidLocalPhoneNumber(phone)) {
      _toast('Phone number must be exactly 10 digits.');
      return;
    }

    setState(() => _saving = true);
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'name': name,
        'email': email,
        'phone_no': phone,
      };
      await patchCustomerMe(body);
      if (!mounted) return;
      _toast('Profile saved.');
    } on UsersApiException catch (e) {
      if (!mounted) return;
      _toast(
        parseCustomerMePatchErrorMessage(e.body) ??
            'Could not save changes. Please try again.',
      );
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PersonalInfoTopBar(
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8F62E8),
                      ),
                    )
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _loadError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: _PersonalInfoUi.muted,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => unawaited(_loadProfile()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8F62E8),
                                    foregroundColor: const Color(0xFF1A1520),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: _AvatarSection(
                                  onChangePhoto: _onChangePhoto,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _LabeledField(
                                label: 'Full Name',
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                enabled: !_saving,
                                suffix: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey.shade400,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_saving,
                              ),
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Phone Number',
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                inputFormatters: localPhoneInputFormatters,
                                enabled: !_saving,
                              ),
                              const SizedBox(height: 32),
                              _SaveButton(
                                submitting: _saving,
                                onPressed:
                                    _saving ? null : () => unawaited(_saveChanges()),
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

  void _onChangePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo update isn’t available yet.'),
        behavior: SnackBarBehavior.floating,
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

class _PersonalInfoTopBar extends StatelessWidget {
  const _PersonalInfoTopBar({required this.onBackTap});

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
              'Personal Information',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _PersonalInfoUi.titlePurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.onChangePhoto});

  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    const double size = 108;
    return Column(
      children: [
        SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: _PersonalInfoUi.avatarBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: _PersonalInfoUi.accent,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onChangePhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 20,
                        color: _PersonalInfoUi.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onChangePhoto,
          child: const Text(
            'Change Photo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _PersonalInfoUi.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final bool enabled;

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
            color: _PersonalInfoUi.muted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _PersonalInfoUi.titlePurple,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _PersonalInfoUi.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _PersonalInfoUi.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _PersonalInfoUi.accent,
                width: 1.5,
              ),
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onPressed,
    required this.submitting,
  });

  final VoidCallback? onPressed;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: _PersonalInfoUi.saveGradient,
          ),
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
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1520),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
