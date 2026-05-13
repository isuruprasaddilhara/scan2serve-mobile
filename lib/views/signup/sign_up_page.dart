import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scan2serve/formatting/phone_number_input.dart';
import 'package:scan2serve/models/signup/sign_up_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/signup/sign_up_view_model.dart';
import 'package:scan2serve/views/home/home_page.dart';
import 'package:scan2serve/views/login/login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final SignUpViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SignUpViewModel();
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
        final SignUpModel data = _viewModel.viewData;
        return Scaffold(
          backgroundColor: AppColors.screenBackground,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: data.title,
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8F78B1).withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              data.heading,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 39 * 0.72,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D243A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                data.subheading,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.25,
                                  color: Color(0xFF6A6278),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ..._buildInputFields(data.fields),
                            const SizedBox(height: 16),
                            if (_viewModel.errorMessage != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  _viewModel.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _CreateButton(
                                label: _viewModel.isSubmitting
                                    ? 'Creating account…'
                                    : data.createAccountLabel,
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : () => _presentTermsBeforeSignUp(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data.footerPrefix,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF4A4357),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    _viewModel.onLoginTap();
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    data.footerActionLabel,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      color: Color(0xFF6B4AA0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _presentTermsBeforeSignUp(BuildContext context) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _SignUpTermsDialog(),
    );
    if (!context.mounted || accepted != true) return;
    final bool ok = await _viewModel.submitSignUp();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  List<Widget> _buildInputFields(List<SignUpFieldModel> fields) {
    final List<Widget> widgets = [];
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      widgets.add(
        _SignUpTextField(
          controller: _viewModel.controllerFor(field.id),
          label: field.label,
          icon: field.icon,
          obscureText: field.isObscure ? _viewModel.isObscured(field.id) : false,
          onToggleObscure: field.isObscure
              ? () => _viewModel.toggleObscure(field.id)
              : null,
          keyboardType: field.id == 'phone'
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters:
              field.id == 'phone' ? localPhoneInputFormatters : null,
        ),
      );
      if (i != fields.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }
}

class _SignUpTermsDialog extends StatefulWidget {
  const _SignUpTermsDialog();

  @override
  State<_SignUpTermsDialog> createState() => _SignUpTermsDialogState();
}

class _SignUpTermsDialogState extends State<_SignUpTermsDialog> {
  bool _hasReadAndAgreed = false;

  static const List<({String title, String body})> _sections = [
    (
      title: '1. Acceptance of Terms',
      body:
          'By accessing and using Scan2Serve, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use our services.',
    ),
    (
      title: '2. Use of Service',
      body:
          'You agree to use Scan2Serve for lawful purposes only. You must not misuse our services in any way.',
    ),
    (
      title: '3. Orders & Payments',
      body:
          'All orders are subject to availability. Prices are inclusive of applicable taxes. Payment must be made as per the selected method.',
    ),
    (
      title: '4. Cancellation & Refunds',
      body:
          'Orders can be cancelled before they are confirmed. Refunds (if applicable) will be processed as per our policy.',
    ),
  ];

  void _onDisagree() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Terms & Conditions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D243A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please read and accept before creating your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A6278),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F4FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD9D3E6)),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        for (final s in _sections) ...[
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D243A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.body,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(0xFF4A4357),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _hasReadAndAgreed,
                onChanged: (bool? v) {
                  setState(() => _hasReadAndAgreed = v ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF6B4AA0),
                title: const Text(
                  'I have read and agree to the Terms & Conditions',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D243A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onDisagree,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB71C1C),
                        side: const BorderSide(color: Color(0xFFE57373)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Disagree'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _hasReadAndAgreed
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9A7DDE),
                        foregroundColor: const Color(0xFF1A1520),
                        disabledBackgroundColor: const Color(0xFFE0DCE8),
                        disabledForegroundColor: const Color(0xFF8A8499),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBackTap,
  });

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF4B4360),
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32 * 0.78,
                color: Color(0xFF3A314A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9D3E6), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 19 * 0.7,
          color: Color(0xFF4F465F),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF706684), size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: label,
          hintStyle: const TextStyle(
            color: Color(0xFF706684),
            fontSize: 19 * 0.7,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF706684),
                    size: 19,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A1520),
          elevation: 1,
          shadowColor: const Color(0xFF8F73BE).withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFC29BEF),
                Color(0xFF9A7DDE),
              ],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1520),
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
