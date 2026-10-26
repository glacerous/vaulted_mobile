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

// ─────────────────────────────────────────────────────────────────────────────
// Static developer directory (for the "Team" section below the user profile)
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, String?>> _kDevelopers = [
  {
    'name': 'Pindo Dinarman Situngkir',
    'nim': '124240031',
    'prodi': 'Sistem Informasi',
    'initials': 'PS',
    'image': 'assets/images/pindo.jpeg',
  },
  {
    'name': 'Azzaky Raihan',
    'nim': '124240018',
    'prodi': 'Sistem Informasi',
    'initials': 'AR',
    'image': 'assets/images/azzaky.png',
  },
  {
    'name': 'Ariel Saputra',
    'nim': '124240010',
    'prodi': 'Sistem Informasi',
    'initials': 'AS',
    'image': 'assets/images/ariel.jpeg',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — main widget
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await AuthService.instance.getCurrentUser();
    final profile = await DatabaseHelper.instance.getUserProfile(username);
    if (mounted) {
      setState(() {
        _profile = profile;
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
    if (updated == true) _loadProfile();
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
                      color: VaultColors.neg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: VaultColors.neg, size: 22),
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
                            color: VaultColors.ink),
                      ),
                      Text(
                        'Mengakhiri sesi akses Vaulted',
                        style: VaultTypography.mono(
                            fontSize: 10, color: VaultColors.ink2),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Vaulted? Sesi otentikasi lokal Anda akan diakhiri.',
                style: VaultTypography.sans(
                    fontSize: 12.5, height: 1.5, color: VaultColors.ink2),
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Batal',
                          style: VaultTypography.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink2)),
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
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: Colors.white),
                      label: Text('Keluar',
                          style: VaultTypography.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.neg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                    strokeWidth: 2, color: VaultColors.accent))
            : RefreshIndicator(
                color: VaultColors.accent,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand header ────────────────────────────────────
                      Text(
                        'VAULTED',
                        style: VaultTypography.mono(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: VaultColors.ink),
                      ),
                      const SizedBox(height: 20),

                      // ── Section label ───────────────────────────────────
                      Text(
                        'MY PROFILE',
                        style: VaultTypography.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: VaultColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account Overview',
                        style: VaultTypography.sans(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: VaultColors.ink),
                      ),
                      const SizedBox(height: 20),

                      // ── User profile card ───────────────────────────────
                      _UserProfileCard(
                        profile: _profile ?? {},
                        onEdit: _openEditProfile,
                      ),
                      const SizedBox(height: 28),

                      // ── Divider ─────────────────────────────────────────
                      Row(children: [
                        const Expanded(
                            child: Divider(color: VaultColors.hairline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'DEVELOPMENT TEAM',
                            style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                                color: VaultColors.ink2),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: VaultColors.hairline)),
                      ]),
                      const SizedBox(height: 16),

                      // ── Developer cards ─────────────────────────────────
                      ..._kDevelopers.map((dev) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DevCard(dev: dev),
                          )),
                      const SizedBox(height: 28),

                      // ── Log out ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutConfirmation,
                          icon: const Icon(Icons.logout_rounded,
                              size: 16, color: VaultColors.neg),
                          label: Text('Log Out of Vault',
                              style: VaultTypography.sans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: VaultColors.neg)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: VaultColors.hairline),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
// _UserProfileCard
// ─────────────────────────────────────────────────────────────────────────────
class _UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  const _UserProfileCard({required this.profile, required this.onEdit});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _avatar(double size) {
    final photoPath = profile['photo_path'] as String?;
    final fullName = (profile['full_name'] as String?) ?? 'User';
    final initials = _initials(fullName);

    ImageProvider? provider;
    if (photoPath != null && photoPath.isNotEmpty) {
      if (kIsWeb) {
        // On web, photo_path might be a data URI or asset path — skip for simplicity
      } else {
        final file = File(photoPath);
        if (file.existsSync()) provider = FileImage(file);
      }
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
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                  color: VaultColors.accent),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (profile['full_name'] as String?) ?? 'User';
    final username = (profile['username'] as String?) ?? '';
    final nim = (profile['nim'] as String?) ?? '—';
    final prodi = (profile['prodi'] as String?) ?? 'Sistem Informasi';
    final bio = (profile['bio'] as String?) ?? '';
    final createdAt = (profile['created_at'] as String?) ?? '';

    String memberSince = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        memberSince =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
            color: const Color(0xFF141413).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Edit button row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(78),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 14, color: VaultColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        'Edit Profile',
                        style: VaultTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            fullName,
            style: VaultTypography.sans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: VaultColors.ink),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$username',
              style: VaultTypography.mono(
                  fontSize: 11.5, color: VaultColors.ink2),
            ),
          ],

          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio,
              style: VaultTypography.sans(
                  fontSize: 12.5, height: 1.5, color: VaultColors.body),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: VaultColors.hairline, height: 1),
          const SizedBox(height: 14),

          // Info rows
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: nim,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.school_outlined,
            label: 'Prodi',
            value: prodi,
          ),
          if (memberSince.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: memberSince,
            ),
          ],

          const SizedBox(height: 14),

          // Vault badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: VaultColors.badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: VaultColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Vaulted Verified Member',
                  style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: VaultColors.ink2),
        const SizedBox(width: 8),
        Text(
          label,
          style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: VaultTypography.sans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: VaultColors.ink),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DevCard — static team member card
// ─────────────────────────────────────────────────────────────────────────────
class _DevCard extends StatelessWidget {
  final Map<String, String?> dev;
  const _DevCard({required this.dev});

  @override
  Widget build(BuildContext context) {
    final imagePath = dev['image'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VaultColors.cardHover,
              border: Border.all(color: VaultColors.accent, width: 1.5),
              image: imagePath != null
                  ? DecorationImage(
                      image: AssetImage(imagePath), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: imagePath == null
                ? Text(
                    dev['initials'] ?? '?',
                    style: VaultTypography.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dev['name'] ?? '',
                  style: VaultTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${dev['nim'] ?? ''}  ·  ${dev['prodi'] ?? 'Sistem Informasi'}',
                  style: VaultTypography.mono(
                      fontSize: 10.5, color: VaultColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const _EditProfileScreen({required this.profile});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nimCtrl;
  late final TextEditingController _prodiCtrl;
  late final TextEditingController _bioCtrl;

  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: (widget.profile['full_name'] as String?) ?? '');
    _nimCtrl = TextEditingController(
        text: (widget.profile['nim'] as String?) ?? '');
    _prodiCtrl = TextEditingController(
        text: (widget.profile['prodi'] as String?) ?? 'Sistem Informasi');
    _bioCtrl = TextEditingController(
        text: (widget.profile['bio'] as String?) ?? '');
    _photoPath = widget.profile['photo_path'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nimCtrl.dispose();
    _prodiCtrl.dispose();
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
        source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<ImageSource?> _showSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: VaultColors.hairline,
                      borderRadius: BorderRadius.circular(2))),
              Text('Pilih Sumber Foto',
                  style: VaultTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: VaultColors.accent),
                title: Text('Kamera',
                    style: VaultTypography.sans(
                        fontSize: 14, color: VaultColors.ink)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: VaultColors.accent),
                title: Text('Galeri',
                    style: VaultTypography.sans(
                        fontSize: 14, color: VaultColors.ink)),
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
      'nim': _nimCtrl.text.trim(),
      'prodi': _prodiCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      if (_photoPath != null) 'photo_path': _photoPath,
    };

    final ok = await AuthService.instance.updateProfile(updates);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      _toast('Profil berhasil diperbarui!',
          icon: Icons.check_circle_rounded,
          iconColor: VaultColors.pos);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      _toast('Gagal menyimpan perubahan. Coba lagi.',
          icon: Icons.error_outline_rounded, iconColor: VaultColors.neg);
    }
  }

  void _toast(String msg,
      {IconData icon = Icons.info_outline,
      Color iconColor = VaultColors.accent}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1D1D1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2A2A28))),
        content: Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFFF2F2EF)))),
        ]),
      ),
    );
  }

  Widget _avatarPreview() {
    final size = 80.0;
    final name = _nameCtrl.text.trim();
    final initials = name.isNotEmpty
        ? () {
            final parts = name.split(RegExp(r'\s+'));
            return parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : name[0].toUpperCase();
          }()
        : '?';

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
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent),
                  )
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: VaultColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: VaultColors.card, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                size: 12, color: Colors.white),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: VaultColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: VaultTypography.sans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: VaultColors.ink),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: VaultColors.primaryButton,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Save',
                      style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
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
              // Avatar picker
              Center(child: _avatarPreview()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap untuk ganti foto',
                    style: VaultTypography.mono(
                        fontSize: 11, color: VaultColors.ink2),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Form fields
              _buildLabel('Nama Lengkap *'),
              const SizedBox(height: 6),
              _buildField(
                controller: _nameCtrl,
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
                inputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),

              _buildLabel('NIM'),
              const SizedBox(height: 6),
              _buildField(
                controller: _nimCtrl,
                hint: 'Nomor Induk Mahasiswa',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),

              _buildLabel('Program Studi'),
              const SizedBox(height: 6),
              _buildField(
                controller: _prodiCtrl,
                hint: 'Program studi / jurusan',
                icon: Icons.school_outlined,
                inputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),

              _buildLabel('Bio'),
              const SizedBox(height: 6),
              _buildField(
                controller: _bioCtrl,
                hint: 'Ceritakan sedikit tentang dirimu...',
                icon: Icons.notes_rounded,
                maxLines: 3,
                inputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Save button (bottom)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.primaryButton,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Simpan Perubahan',
                          style: VaultTypography.sans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: VaultColors.ink2),
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
              fontSize: 13.5, color: VaultColors.ink3),
          prefixIcon: Icon(icon, size: 18, color: VaultColors.ink2),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 14 : 0, horizontal: 4),
        ),
      ),
    );
  }
}
