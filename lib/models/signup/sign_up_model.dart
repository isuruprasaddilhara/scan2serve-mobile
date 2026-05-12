import 'package:flutter/material.dart';

class SignUpModel {
  const SignUpModel({
    required this.title,
    required this.heading,
    required this.subheading,
    required this.fields,
    required this.createAccountLabel,
    required this.footerPrefix,
    required this.footerActionLabel,
  });

  final String title;
  final String heading;
  final String subheading;
  final List<SignUpFieldModel> fields;
  final String createAccountLabel;
  final String footerPrefix;
  final String footerActionLabel;
}

class SignUpFieldModel {
  const SignUpFieldModel({
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
