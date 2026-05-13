import 'package:flutter/material.dart';
import 'package:scan2serve/api/auth_token_store.dart';

/// Bottom navigation: Home, Track, Profile — matches home / track screens.
class ScanBottomNavBar extends StatelessWidget {
  const ScanBottomNavBar({
    super.key,
    required this.activeNav,
    required this.onNavTap,
    this.profileEnabled,
  });

  /// One of `'Home'`, `'Track'`, `'Profile'`.
  final String activeNav;
  final ValueChanged<String> onNavTap;

  /// When `null`, uses [authAccessToken] (guest = no JWT → Profile disabled).
  final bool? profileEnabled;

  bool get _profileOn =>
      profileEnabled ??
      (authAccessToken.value != null &&
          authAccessToken.value!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (profileEnabled == null) {
      return ValueListenableBuilder<String?>(
        valueListenable: authAccessToken,
        builder: (context, _, __) {
          return _ScanBottomNavBarBody(
            activeNav: activeNav,
            onNavTap: onNavTap,
            profileEnabled: authAccessToken.value != null &&
                authAccessToken.value!.trim().isNotEmpty,
          );
        },
      );
    }
    return _ScanBottomNavBarBody(
      activeNav: activeNav,
      onNavTap: onNavTap,
      profileEnabled: _profileOn,
    );
  }
}

class _ScanBottomNavBarBody extends StatelessWidget {
  const _ScanBottomNavBarBody({
    required this.activeNav,
    required this.onNavTap,
    required this.profileEnabled,
  });

  final String activeNav;
  final ValueChanged<String> onNavTap;
  final bool profileEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDF8),
        border: Border(
          top: BorderSide(color: Color(0xFFE5DDEF), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isActive: activeNav == 'Home',
              enabled: true,
              onTap: () => onNavTap('Home'),
            ),
            _NavItem(
              icon: Icons.track_changes_outlined,
              label: 'Track',
              isActive: activeNav == 'Track',
              enabled: true,
              onTap: () => onNavTap('Track'),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isActive: activeNav == 'Profile' && profileEnabled,
              enabled: profileEnabled,
              onTap: () => onNavTap('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.enabled = true,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  static const Color _active = Color(0xFF3F3254);
  static const Color _inactive = Color(0xFF8A8099);
  static const Color _disabled = Color(0xFFC4B8D4);

  @override
  Widget build(BuildContext context) {
    final Color color =
        !enabled ? _disabled : (isActive ? _active : _inactive);
    final Widget child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (!enabled) {
      return Opacity(
        opacity: 0.55,
        child: IgnorePointer(child: child),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}

/// Bottom nav with a circular chat button floated above the bar (Profile side).
class BottomNavWithChatFab extends StatefulWidget {
  const BottomNavWithChatFab({
    super.key,
    required this.activeNav,
    required this.onNavTap,
    required this.onChatTap,
    this.profileEnabled,
  });

  final String activeNav;
  final ValueChanged<String> onNavTap;
  final VoidCallback onChatTap;

  /// When `null`, guest vs signed-in follows [authAccessToken] inside [ScanBottomNavBar].
  final bool? profileEnabled;

  static const double _navHeight = 64;
  /// Space above the nav bar reserved for the FAB + close badge hit targets.
  static const double _fabHitHeight = 66;

  @override
  State<BottomNavWithChatFab> createState() => _BottomNavWithChatFabState();
}

class _BottomNavWithChatFabState extends State<BottomNavWithChatFab> {
  bool _chatFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final double fabSlot = _chatFabVisible ? BottomNavWithChatFab._fabHitHeight : 0;
    return SizedBox(
      height: BottomNavWithChatFab._navHeight + fabSlot,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScanBottomNavBar(
              activeNav: widget.activeNav,
              onNavTap: widget.onNavTap,
              profileEnabled: widget.profileEnabled,
            ),
          ),
          if (_chatFabVisible)
            Positioned(
              right: 10,
              bottom: BottomNavWithChatFab._navHeight,
              child: _ChatFabWithCloseBadge(
                onOpenChat: widget.onChatTap,
                onDismiss: () => setState(() => _chatFabVisible = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatFabWithCloseBadge extends StatelessWidget {
  const _ChatFabWithCloseBadge({
    required this.onOpenChat,
    required this.onDismiss,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onDismiss;

  static const Color _fill = Color(0xFF9B77D6);
  static const String _avatarAsset = 'assets/images/chatbot_avatar.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenChat,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4A7A).withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    _avatarAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: _fill,
                      child: Center(
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDismiss,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Color(0xFF1A1520),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
