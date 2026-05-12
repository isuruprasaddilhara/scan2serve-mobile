import 'package:flutter/material.dart';

class ProfileMenuRowModel {
  const ProfileMenuRowModel({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class ProfileModel {
  const ProfileModel({
    required this.title,
    required this.userName,
    required this.email,
    required this.ordersCount,
    required this.favouriteFood,
    required this.menuRows,
    required this.editProfileLabel,
    required this.logoutLabel,
  });

  final String title;
  final String userName;
  final String email;
  final int ordersCount;
  final String favouriteFood;
  final List<ProfileMenuRowModel> menuRows;
  final String editProfileLabel;
  final String logoutLabel;
}
