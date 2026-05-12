import 'package:flutter/material.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/models/login/login_model.dart';
import 'package:scan2serve/theme/app_colors.dart';
import 'package:scan2serve/viewmodels/login/login_view_model.dart';
import 'package:scan2serve/views/home/home_page.dart';
import 'package:scan2serve/views/signup/sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
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
        final LoginModel data = _viewModel.viewData;
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
                            const SizedBox(height: 16),
                            ..._buildInputFields(data.fields),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _showForgotPasswordDialog(context),
                                child: Text(
                                  data.forgotPasswordLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF9A78D0),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_viewModel.errorMessage != null) ...[
                              Text(
                                _viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _LoginButton(
                                label: _viewModel.isSubmitting ? 'Signing in…' : data.loginButtonLabel,
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : () async {
                                        final ok = await _viewModel.submitLogin();
                                        if (!context.mounted) return;
                                        if (ok) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute<void>(
                                              builder: (_) => const HomePage(),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _OrDivider(label: data.orLabel),
                            const SizedBox(height: 14),
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
                                    _viewModel.onCreateAccountTap();
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SignUpPage(),
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

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final String? message = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext _) {
        return _ForgotPasswordDialog(
          initialEmail: _viewModel.controllerFor('email').text.trim(),
        );
      },
    );
    if (!context.mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<Widget> _buildInputFields(List<LoginFieldModel> fields) {
    final List<Widget> widgets = [];
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      widgets.add(
        _LoginTextField(
          controller: _viewModel.controllerFor(field.id),
          label: field.label,
          icon: field.icon,
          obscureText: field.isObscure ? _viewModel.isObscured(field.id) : false,
          onToggleObscure: field.isObscure
              ? () => _viewModel.toggleObscure(field.id)
              : null,
        ),
      );
      if (i != fields.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'Please enter your email address.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final String message = await requestPasswordReset(email: email);
      if (!mounted) return;
      Navigator.of(context).pop(message);
    } on UsersApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText =
            parseForgotPasswordErrorMessage(e.body) ??
            'Could not send reset email. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot password?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email for your account. If it exists, we will send a password reset link.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF5C5468),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_loading) {
                  _submit();
                }
              },
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send link'),
        ),
      ],
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

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

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

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.onPressed,
  });

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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            thickness: 1.5,
            color: Color(0xFFAFA7BE),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF4A4357),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 1.5,
            color: Color(0xFFAFA7BE),
          ),
        ),
      ],
    );
  }
}
