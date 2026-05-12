import 'package:flutter/material.dart';
import 'package:scan2serve/api/users_api.dart';
import 'package:scan2serve/models/signup/sign_up_model.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel();

  final SignUpModel viewData = const SignUpModel(
    title: 'Sign Up',
    heading: 'Create your account',
    subheading: 'Join Scan2Serve and start ordering your favorite food!',
    fields: [
      SignUpFieldModel(
        id: 'name',
        label: 'Name',
        icon: Icons.person_outline_rounded,
      ),
      SignUpFieldModel(
        id: 'email',
        label: 'Email',
        icon: Icons.email_outlined,
      ),
      SignUpFieldModel(
        id: 'phone',
        label: 'Phone Number',
        icon: Icons.phone_outlined,
      ),
      SignUpFieldModel(
        id: 'password',
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        isObscure: true,
      ),
      SignUpFieldModel(
        id: 'confirm_password',
        label: 'Confirm Password',
        icon: Icons.lock_outline_rounded,
        isObscure: true,
      ),
    ],
    createAccountLabel: 'Create Account',
    footerPrefix: 'Already have an account?',
    footerActionLabel: 'Login',
  );

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
    'confirm_password': TextEditingController(),
  };

  final Map<String, bool> _obscureMap = {
    'password': true,
    'confirm_password': true,
  };

  bool _submitting = false;
  String? _errorMessage;

  bool get isSubmitting => _submitting;
  String? get errorMessage => _errorMessage;

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

  /// Registers via `/users/auth/register/customer/` then logs in. Returns true on success.
  Future<bool> submitSignUp() async {
    _errorMessage = null;
    final name = controllers['name']!.text.trim();
    final email = controllers['email']!.text.trim();
    final phone = controllers['phone']!.text.trim();
    final password = controllers['password']!.text;
    final confirm = controllers['confirm_password']!.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }
    if (password != confirm) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _submitting = true;
    notifyListeners();
    try {
      try {
        await registerCustomer(
          email: email,
          name: name,
          password: password,
          phoneNo: phone,
        );
      } on UsersApiException catch (e) {
        _errorMessage = _registerErrorMessage(e);
        return false;
      } catch (e) {
        _errorMessage = e.toString();
        return false;
      }

      try {
        await loginWithEmailPassword(email: email, password: password);
      } on UsersApiException {
        _errorMessage =
            'Account created. Please sign in with your email and password.';
        return false;
      } catch (e) {
        _errorMessage = e.toString();
        return false;
      }
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  String _registerErrorMessage(UsersApiException e) {
    final fromBody = parseRegisterErrorBody(e.body);
    if (fromBody != null && fromBody.isNotEmpty) {
      return fromBody;
    }
    if (e.statusCode == 429) {
      return 'Too many sign-up attempts. Please try again later.';
    }
    return 'Could not create account. Please try again.';
  }

  void onLoginTap() {
    debugPrint('Login tapped from Sign Up page');
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
