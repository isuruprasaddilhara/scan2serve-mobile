import 'package:flutter/material.dart';
import 'package:scan2serve/models/login/login_model.dart';
import 'package:scan2serve/api/users_api.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel();

  final LoginModel viewData = const LoginModel(
    title: 'Login',
    heading: 'Welcome Back!',
    subheading: 'Login to continue to scan2serve',
    fields: [
      LoginFieldModel(
        id: 'email',
        label: 'Email',
        icon: Icons.email_outlined,
      ),
      LoginFieldModel(
        id: 'password',
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        isObscure: true,
      ),
    ],
    forgotPasswordLabel: 'Forgot Password?',
    loginButtonLabel: 'Login',
    orLabel: 'Or',
    footerPrefix: 'Don’t have an account?',
    footerActionLabel: 'Create Account',
  );

  final Map<String, TextEditingController> controllers = {
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  final Map<String, bool> _obscureMap = {
    'password': true,
  };

  TextEditingController controllerFor(String fieldId) {
    return controllers[fieldId]!;
  }

  bool isObscured(String fieldId) {
    return _obscureMap[fieldId] ?? false;
  }

  void toggleObscure(String fieldId) {
    if (!_obscureMap.containsKey(fieldId)) return;
    _obscureMap[fieldId] = !_obscureMap[fieldId]!;
    notifyListeners();
  }

  bool _submitting = false;
  String? _errorMessage;

  bool get isSubmitting => _submitting;
  String? get errorMessage => _errorMessage;

  /// Returns true when login succeeded and tokens were stored.
  Future<bool> submitLogin() async {
    _errorMessage = null;
    final email = controllers['email']!.text.trim();
    final password = controllers['password']!.text;
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter email and password.';
      notifyListeners();
      return false;
    }
    _submitting = true;
    notifyListeners();
    try {
      await loginWithEmailPassword(email: email, password: password);
      return true;
    } on UsersApiException catch (e) {
      _errorMessage = _loginErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  String _loginErrorMessage(UsersApiException e) {
    if (e.statusCode == 401 || e.statusCode == 400) {
      return 'Invalid email or password.';
    }
    return 'Could not sign in. Please try again.';
  }

  void onCreateAccountTap() {
    debugPrint('Create account tapped from Login page');
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
