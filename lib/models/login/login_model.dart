import 'package:flutter/material.dart';

class LoginModel {
  const LoginModel({
    required this.title,
    required this.heading,
    required this.subheading,
    required this.fields,
    required this.forgotPasswordLabel,
    required this.loginButtonLabel,
    required this.orLabel,
    required this.footerPrefix,
    required this.footerActionLabel,
  });

  final String title;
  final String heading;
  final String subheading;
  final List<LoginFieldModel> fields;
  final String forgotPasswordLabel;
  final String loginButtonLabel;
  final String orLabel;
  final String footerPrefix;
  final String footerActionLabel;
}

class LoginFieldModel {
  const LoginFieldModel({
    required this.id,
    required this.label,
    required this.icon,
    this.isObscure = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isObscure;
}
