import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/security/auth_service.dart';
import 'login_screen.dart';
import 'saran_kesan_screen.dart';
import 'vault_converter_screen.dart';
import 'warranty_lbs_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Ultra-luxury Sovereign Account Profile for VAULTED
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
    _loadProfile();
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

  void _showLogoutConfirmation() {
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand Header ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VAULTED',
                            style: VaultTypography.mono(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: VaultColors.ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: VaultColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: VaultColors.hairline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: VaultColors.pos,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'KEYSTORE ACTIVE',
                                  style: VaultTypography.mono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: VaultColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Section Label ─────────────────────────────────────
                      Text(
                        'VAULT IDENTITY',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: VaultColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account Profile',
                        style: VaultTypography.sans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── User Profile Card ─────────────────────────────────
                      _UserProfileCard(
                        profile: _profile ?? {},
                        itemCount: _itemCount,
                        onEdit: _openEditProfile,
                      ),
                      const SizedBox(height: 24),

                      // ── Section: Security & Protocol ──────────────────────
                      Text(
                        'SECURITY & PROTOCOL',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: VaultColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SettingsGroupCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.shield_outlined,
                            iconColor: VaultColors.accent,
                            title: 'Hardware Keystore & Biometrics',
                            subtitle: 'Enclave-backed AES-256 local authentication',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: VaultColors.pos.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: VaultTypography.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: VaultColors.pos,
                                ),
                              ),
                            ),
                          ),
                          _SettingsItem(
                            icon: Icons.screen_rotation_rounded,
                            iconColor: VaultColors.ink,
                            title: 'Emergency Shake Lock',
                            subtitle: 'Accelerometer auto-lock threshold 17.0 m/s²',
                            trailing: Text(
                              'ENABLED',
                              style: VaultTypography.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: VaultColors.ink2,
                              ),
                            ),
                          ),
                          _SettingsItem(
                            icon: Icons.hub_outlined,
                            iconColor: VaultColors.ink,
                            title: 'Network Synchronization',
                            subtitle: 'Polygon Amoy Testnet (Chain ID 80002)',
                            trailing: const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: VaultColors.pos,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Section: Vault Tools & Preferences ────────────────
                      Text(
                        'VAULT SERVICES & TOOLS',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: VaultColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SettingsGroupCard(
                        items: [
                          _SettingsItem(
                            icon: Icons.currency_exchange_rounded,
                            iconColor: VaultColors.accent,
                            title: 'Currency Conversion Desk',
                            subtitle: 'Real-time multi-currency valuation (USD/IDR)',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VaultConverterScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsItem(
                            icon: Icons.storefront_outlined,
                            iconColor: VaultColors.ink,
                            title: 'Official Safehouses & Centers',
                            subtitle: 'LBS warranty centers and authorized vaults',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WarrantyLbsScreen(),
                                ),
                              );
                            },
                          ),
                          _SettingsItem(
                            icon: Icons.rate_review_outlined,
                            iconColor: VaultColors.ink,
                            title: 'Experience Notes & Feedback',
                            subtitle: 'System impressions and feedback log',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SaranKesanScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Log Out Button ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutConfirmation,
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: VaultColors.neg,
                          ),
                          label: Text(
                            'Log Out of Vault',
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.neg,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: VaultColors.hairline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── System Footer ─────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'VAULTED PROTOCOL · VERSION 1.4.2',
                              style: VaultTypography.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: VaultColors.ink3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Zero-Knowledge Sovereign Asset Custody',
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
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserProfileCard — Clean luxury user card
// ─────────────────────────────────────────────────────────────────────────────
class _UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final int itemCount;
  final VoidCallback onEdit;

  const _UserProfileCard({
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
                fontSize: size * 0.35,
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

    String memberSince = 'Active Member';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VaultColors.hairline),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141413).withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Avatar & Edit Profile ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: VaultTypography.sans(
                        fontSize: 19,
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                            size: 13,
                            color: VaultColors.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SOVEREIGN CLIENT',
                            style: VaultTypography.mono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: VaultColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: VaultColors.ink,
                  ),
                ),
              ),
            ],
          ),

          // ── Bio (if present) ─────────────────────────────────────────────
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VaultColors.hairline),
              ),
              child: Text(
                bio,
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  height: 1.45,
                  color: VaultColors.ink,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),
          const Divider(color: VaultColors.hairline, height: 1),
          const SizedBox(height: 16),

          // ── Metrics Row ──────────────────────────────────────────────────
          Row(
            children: [
              _StatItem(
                label: 'CUSTODIED ASSETS',
                value: '$itemCount Items',
              ),
              Container(
                width: 1,
                height: 32,
                color: VaultColors.hairline,
              ),
              _StatItem(
                label: 'ENCRYPTION',
                value: 'Hardware',
              ),
              Container(
                width: 1,
                height: 32,
                color: VaultColors.hairline,
              ),
              _StatItem(
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

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
          const SizedBox(height: 4),
          Text(
            value,
            style: VaultTypography.sans(
              fontSize: 12.5,
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
// _SettingsGroupCard & _SettingsItem — Clean luxury settings list
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    this.iconColor = VaultColors.ink,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
}

class _SettingsGroupCard extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsGroupCard({required this.items});

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
          for (int i = 0; i < items.length; i++) ...[
            _buildRow(items[i]),
            if (i < items.length - 1)
              const Divider(color: VaultColors.hairline, height: 1, indent: 52),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(_SettingsItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: VaultTypography.mono(
                      fontSize: 10,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else if (item.onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: VaultColors.ink2,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditProfileScreen — Simple luxury profile editor (Name, Bio, Photo)
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
      HapticFeedback.lightImpact();
      if (!mounted) return;
      _toast(
        'Profil Vaulted berhasil diperbarui!',
        icon: Icons.check_circle_rounded,
        iconColor: VaultColors.pos,
      );
      await Future.delayed(const Duration(milliseconds: 600));
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
    const size = 84.0;
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
                      fontSize: size * 0.32,
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: VaultColors.primaryButton,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Picker
              Center(child: _avatarPreview()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Tap avatar to update photo',
                    style: VaultTypography.mono(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Form Fields (Full Name & Bio only — clean luxury profile)
              _buildLabel('FULL NAME *'),
              const SizedBox(height: 8),
              _buildField(
                controller: _nameCtrl,
                hint: 'e.g. Azzaky Raihan',
                icon: Icons.person_outline_rounded,
                inputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              _buildLabel('VAULT BIO'),
              const SizedBox(height: 8),
              _buildField(
                controller: _bioCtrl,
                hint: 'Personal motto, collector note, or profile tagline...',
                icon: Icons.notes_rounded,
                maxLines: 3,
                inputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Save Button (Bottom)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.primaryButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: VaultTypography.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: VaultTypography.mono(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: VaultColors.ink2,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction inputAction = TextInputAction.next,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: inputAction,
        maxLines: maxLines,
        style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: VaultTypography.sans(
            fontSize: 13.5,
            color: VaultColors.ink3,
          ),
          prefixIcon: Icon(icon, size: 18, color: VaultColors.ink2),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: maxLines > 1 ? 14 : 0,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}
