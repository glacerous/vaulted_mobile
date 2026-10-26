import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/security/auth_service.dart';
import '../core/services/vault_settings.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Native Luxury Mobile Profile & Settings for VAULTED
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  int _itemCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await VaultSettings.instance.init();
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await AuthService.instance.getCurrentUser();
    final profile = await DatabaseHelper.instance.getUserProfile(username);
    final items = await DatabaseHelper.instance.getItems(username);
    if (mounted) {
      setState(() {
        _profile = profile;
        _itemCount = items.length;
        _loading = false;
      });
    }
  }

  void _openEditProfile() async {
    if (VaultSettings.instance.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(profile: _profile ?? {}),
      ),
    );
    if (updated == true) {
      _loadProfile();
    }
  }

  void _clearCache() {
    if (VaultSettings.instance.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1D1D1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A2A28)),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: VaultColors.pos, size: 18),
            const SizedBox(width: 10),
            Text(
              'Local image & thumbnail cache cleared',
              style: VaultTypography.sans(
                fontSize: 12.5,
                color: const Color(0xFFF2F2EF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    if (VaultSettings.instance.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VaultColors.neg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: VaultColors.neg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Log Out',
                        style: VaultTypography.sans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.ink,
                        ),
                      ),
                      Text(
                        'Mengakhiri sesi akses Vaulted',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Vaulted? Sesi otentikasi lokal Anda akan diakhiri secara aman.',
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  height: 1.5,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: VaultColors.hairline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AuthService.instance.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Keluar',
                        style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.neg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VaultColors.accent,
                ),
              )
            : RefreshIndicator(
                color: VaultColors.accent,
                onRefresh: _loadProfile,
                child: ValueListenableBuilder<int>(
                  valueListenable: VaultSettings.instance.changeNotifier,
                  builder: (context, _, _) {
                    final settings = VaultSettings.instance;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Mobile Header ─────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VAULTED',
                                    style: VaultTypography.mono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: VaultColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Profile & Settings',
                                    style: VaultTypography.sans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: VaultColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _openEditProfile,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VaultColors.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: VaultColors.hairline),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF141413)
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: VaultColors.ink,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: VaultTypography.sans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: VaultColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ── Hero Profile Identity Card ────────────────────
                          _HeroProfileCard(
                            profile: _profile ?? {},
                            itemCount: _itemCount,
                            onEdit: _openEditProfile,
                          ),
                          const SizedBox(height: 24),

                          // ── Settings Group 1: Vault Security ──────────────
                          _SectionTitle(title: 'VAULT SECURITY & ACCESS'),
                          const SizedBox(height: 8),
                          _SettingsGroup(
                            children: [
                              _SettingsToggleTile(
                                icon: Icons.fingerprint_rounded,
                                iconColor: VaultColors.accent,
                                title: 'Biometric Passkey',
                                subtitle:
                                    'Require Face ID / Touch ID on vault unlock',
                                value: settings.biometricsEnabled,
                                onChanged: (val) {
                                  if (settings.hapticsEnabled) {
                                    HapticFeedback.selectionClick();
                                  }
                                  settings.setBiometrics(val);
                                },
                              ),
                              _SettingsToggleTile(
                                icon: Icons.screen_rotation_rounded,
                                iconColor: VaultColors.ink,
                                title: 'Emergency Shake Lock',
                                subtitle:
                                    'Auto-lock vault when device is shaken',
                                value: settings.shakeLockEnabled,
                                onChanged: (val) {
                                  if (settings.hapticsEnabled) {
                                    HapticFeedback.selectionClick();
                                  }
                                  settings.setShakeLock(val);
                                },
                              ),
                              _SettingsToggleTile(
                                icon: Icons.visibility_off_outlined,
                                iconColor: VaultColors.ink,
                                title: 'Privacy Balance Mask',
                                subtitle:
                                    'Mask financial balances with bullet points',
                                value: settings.privacyMaskEnabled,
                                onChanged: (val) {
                                  if (settings.hapticsEnabled) {
                                    HapticFeedback.selectionClick();
                                  }
                                  settings.setPrivacyMask(val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // ── Settings Group 2: App Preferences ─────────────
                          _SectionTitle(title: 'PREFERENCES'),
                          const SizedBox(height: 8),
                          _SettingsGroup(
                            children: [
                              _SettingsToggleTile(
                                icon: Icons.vibration_rounded,
                                iconColor: VaultColors.accent,
                                title: 'Haptic Tactile Feedback',
                                subtitle:
                                    'Tactile vibrations on interactions & taps',
                                value: settings.hapticsEnabled,
                                onChanged: (val) {
                                  if (val) HapticFeedback.mediumImpact();
                                  settings.setHaptics(val);
                                },
                              ),
                              _SettingsToggleTile(
                                icon: Icons.notifications_none_rounded,
                                iconColor: VaultColors.ink,
                                title: 'Security Alerts & Notifications',
                                subtitle:
                                    'Push notifications for critical sessions',
                                value: settings.notificationsEnabled,
                                onChanged: (val) {
                                  if (settings.hapticsEnabled) {
                                    HapticFeedback.selectionClick();
                                  }
                                  settings.setNotifications(val);
                                },
                              ),
                              _SettingsActionTile(
                                icon: Icons.monetization_on_outlined,
                                iconColor: VaultColors.accent,
                                title: 'Default Currency',
                                subtitle:
                                    'Primary denomination across portfolio',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VaultColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: VaultColors.hairline),
                                  ),
                                  child: Text(
                                    settings.currency == 'IDR'
                                        ? 'IDR (Rp)'
                                        : 'USD (\$)',
                                    style: VaultTypography.mono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: VaultColors.ink,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  if (settings.hapticsEnabled) {
                                    HapticFeedback.lightImpact();
                                  }
                                  final next =
                                      settings.currency == 'USD' ? 'IDR' : 'USD';
                                  settings.setCurrency(next);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // ── Settings Group 3: Storage & Session ───────────
                          _SectionTitle(title: 'SYSTEM & SESSION'),
                          const SizedBox(height: 8),
                          _SettingsGroup(
                            children: [
                              _SettingsActionTile(
                                icon: Icons.cleaning_services_outlined,
                                iconColor: VaultColors.ink,
                                title: 'Clear Local Cache',
                                subtitle:
                                    'Release cached asset thumbnails & radar memory',
                                trailing: Text(
                                  'Clear',
                                  style: VaultTypography.sans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: VaultColors.accent,
                                  ),
                                ),
                                onTap: _clearCache,
                              ),
                              _SettingsActionTile(
                                icon: Icons.logout_rounded,
                                iconColor: VaultColors.neg,
                                title: 'Log Out of Vault',
                                titleColor: VaultColors.neg,
                                subtitle:
                                    'End authenticated session on this device',
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: VaultColors.neg,
                                ),
                                onTap: _showLogoutConfirmation,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Mobile App Footer ─────────────────────────────
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'VAULTED · VERSION 1.4.2 (BUILD 48)',
                                  style: VaultTypography.mono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: VaultColors.ink3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Hardware Enclave Encrypted Sovereign Custody',
                                  style: VaultTypography.sans(
                                    fontSize: 11,
                                    color: VaultColors.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroProfileCard — Clean, focused profile overview
// ─────────────────────────────────────────────────────────────────────────────
class _HeroProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final int itemCount;
  final VoidCallback onEdit;

  const _HeroProfileCard({
    required this.profile,
    required this.itemCount,
    required this.onEdit,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'V';
  }

  Widget _avatar(double size) {
    final photoPath = profile['photo_path'] as String?;
    final fullName = (profile['full_name'] as String?) ?? 'Sovereign Client';
    final initials = _initials(fullName);

    ImageProvider? provider;
    if (photoPath != null && photoPath.isNotEmpty && !kIsWeb) {
      final file = File(photoPath);
      if (file.existsSync()) provider = FileImage(file);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VaultColors.cardHover,
        border: Border.all(color: VaultColors.accent, width: 2),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: provider == null
          ? Text(
              initials,
              style: VaultTypography.mono(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: VaultColors.accent,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (profile['full_name'] as String?) ?? 'Vaulted User';
    final username = (profile['username'] as String?) ?? 'client';
    final bio = (profile['bio'] as String?) ?? '';
    final createdAt = (profile['created_at'] as String?) ?? '';

    String memberSince = 'Active';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        memberSince = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VaultColors.hairline),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141413).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top User Row ──────────────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: _avatar(66),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: VaultTypography.sans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: VaultTypography.mono(
                        fontSize: 12,
                        color: VaultColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: VaultColors.badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: VaultColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: VaultColors.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SOVEREIGN CLIENT',
                            style: VaultTypography.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: VaultColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Bio (if set) ──────────────────────────────────────────────────
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VaultColors.hairline),
              ),
              child: Text(
                bio,
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  height: 1.4,
                  color: VaultColors.ink,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: VaultColors.hairline, height: 1),
          const SizedBox(height: 14),

          // ── 3-Column Metrics ──────────────────────────────────────────────
          Row(
            children: [
              _MetricItem(
                label: 'CUSTODIED',
                value: '$itemCount Items',
              ),
              Container(width: 1, height: 28, color: VaultColors.hairline),
              const _MetricItem(
                label: 'SECURITY',
                value: 'Enclave',
              ),
              Container(width: 1, height: 28, color: VaultColors.hairline),
              _MetricItem(
                label: 'MEMBER SINCE',
                value: memberSince,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: VaultTypography.mono(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: VaultColors.ink2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: VaultTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VaultColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Components
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: VaultTypography.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: VaultColors.ink2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(color: VaultColors.hairline, height: 1, indent: 54),
          ],
        ],
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VaultColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VaultTypography.sans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: VaultTypography.mono(
                    fontSize: 9.5,
                    color: VaultColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: VaultColors.accent,
            activeTrackColor: VaultColors.accent.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VaultColors.hairline),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditProfileScreen — Mobile-first Profile Editor
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const _EditProfileScreen({required this.profile});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;

  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: (widget.profile['full_name'] as String?) ?? '',
    );
    _bioCtrl = TextEditingController(
      text: (widget.profile['bio'] as String?) ?? '',
    );
    _photoPath = widget.profile['photo_path'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (kIsWeb) {
      _toast('Ganti foto tidak tersedia di versi web.', icon: Icons.info_outline);
      return;
    }
    final picker = ImagePicker();
    final source = await _showSourceSheet();
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<ImageSource?> _showSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: VaultColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Pilih Sumber Foto',
                style: VaultTypography.sans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: VaultColors.accent,
                ),
                title: Text(
                  'Kamera',
                  style: VaultTypography.sans(
                    fontSize: 14,
                    color: VaultColors.ink,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: VaultColors.accent,
                ),
                title: Text(
                  'Galeri',
                  style: VaultTypography.sans(
                    fontSize: 14,
                    color: VaultColors.ink,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Nama lengkap tidak boleh kosong.', icon: Icons.warning_rounded);
      return;
    }
    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'full_name': name,
      'bio': _bioCtrl.text.trim(),
      if (_photoPath != null) 'photo_path': _photoPath,
    };

    final ok = await AuthService.instance.updateProfile(updates);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      if (VaultSettings.instance.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      if (!mounted) return;
      _toast(
        'Profil berhasil diperbarui',
        icon: Icons.check_circle_rounded,
        iconColor: VaultColors.pos,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      _toast(
        'Gagal menyimpan perubahan. Coba lagi.',
        icon: Icons.error_outline_rounded,
        iconColor: VaultColors.neg,
      );
    }
  }

  void _toast(
    String msg, {
    IconData icon = Icons.info_outline,
    Color iconColor = VaultColors.accent,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1D1D1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A2A28)),
        ),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFFF2F2EF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPreview() {
    const size = 88.0;
    final name = _nameCtrl.text.trim();
    final initials = name.isNotEmpty
        ? () {
            final parts = name.split(RegExp(r'\s+'));
            return parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : name[0].toUpperCase();
          }()
        : 'V';

    ImageProvider? provider;
    if (_photoPath != null && _photoPath!.isNotEmpty && !kIsWeb) {
      final file = File(_photoPath!);
      if (file.existsSync()) provider = FileImage(file);
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VaultColors.cardHover,
              border: Border.all(color: VaultColors.accent, width: 2),
              image: provider != null
                  ? DecorationImage(image: provider, fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: provider == null
                ? Text(
                    initials,
                    style: VaultTypography.mono(
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  )
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: VaultColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: VaultColors.card, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: VaultTypography.sans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: VaultColors.ink2,
            ),
          ),
        ),
        leadingWidth: 70,
        title: Text(
          'Edit Profile',
          style: VaultTypography.sans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: VaultColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: VaultColors.primaryButton,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: VaultTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              _avatarPreview(),
              const SizedBox(height: 8),
              Text(
                'Tap avatar untuk ganti foto',
                style: VaultTypography.mono(
                  fontSize: 11,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 28),

              // Grouped Form Card
              Container(
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FULL NAME *',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: VaultColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _nameCtrl,
                            style: VaultTypography.sans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Azzaky Raihan',
                              hintStyle: VaultTypography.sans(
                                fontSize: 13.5,
                                color: VaultColors.ink3,
                              ),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: VaultColors.hairline, height: 1, indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VAULT BIO',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: VaultColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _bioCtrl,
                            maxLines: 3,
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              color: VaultColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Personal motto, collector note, or profile tagline...',
                              hintStyle: VaultTypography.sans(
                                fontSize: 13,
                                color: VaultColors.ink3,
                              ),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
