import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';
import 'package:scan2serve/models/profile/profile_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel() : viewData = ProfileViewModel.defaultViewData;

  /// Labels and menu structure only — no placeholder user or dish names.
  static const ProfileModel defaultViewData = ProfileModel(
    title: 'Profile',
    userName: '',
    email: '',
    ordersCount: 0,
    favouriteFood: '',
    editProfileLabel: 'Edit Profile',
    logoutLabel: 'Log out',
    menuRows: [
      ProfileMenuRowModel(
        id: 'my_orders',
        label: 'My Orders',
        icon: Icons.shopping_bag_outlined,
      ),
      ProfileMenuRowModel(
        id: 'track_order',
        label: 'Track Current Order',
        icon: Icons.location_on_outlined,
      ),
      ProfileMenuRowModel(
        id: 'favourite_foods',
        label: 'Favourite Foods',
        icon: Icons.favorite_outline,
      ),
      ProfileMenuRowModel(
        id: 'feedback',
        label: 'Feedback & Ratings',
        icon: Icons.star_outline_rounded,
      ),
      ProfileMenuRowModel(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
      ),
    ],
  );

  final ProfileModel viewData;

  void onEditProfileTap() {
    debugPrint('Edit profile');
  }

  void onMenuRowTap(String id) {
    debugPrint('Profile menu: $id');
  }

  void onLogoutTap() {
    clearAuthTokens();
  }
}
