import 'package:flutter/material.dart';

class WelcomeModel {
  const WelcomeModel({
    required this.logoAssetPath,
    required this.brandName,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String logoAssetPath;
  final String brandName;
  final String title;
  final String subtitle;
  final List<WelcomeActionModel> actions;
}

class WelcomeActionModel {
  const WelcomeActionModel({
    required this.id,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String id;
  final String label;
  final Color textColor;
  final Color backgroundColor;
}
