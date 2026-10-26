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
// ProfileScreen — Halaman Profil Aplikasi VAULTED (Mobile Native UI/UX)
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        'Konfirmasi Keluar',
                        style: VaultTypography.sans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.ink,
                        ),
                      ),
                      Text(
                        'Mengakhiri sesi akun',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Vaulted? Anda perlu masuk kembali untuk mengakses vault Anda.',
                style: VaultTypography.sans(
                  fontSize: 13,
                  height: 1.45,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (_profile?['full_name'] as String?) ?? 'Pengguna Vaulted';
    final username = (_profile?['username'] as String?) ?? 'azzaky';
    final bio = (_profile?['bio'] as String?) ?? '';
    final createdAt = _formatDate(_profile?['created_at'] as String?);
    final photoPath = _profile?['photo_path'] as String?;

    ImageProvider? avatarImage;
    if (photoPath != null && photoPath.isNotEmpty && !kIsWeb) {
      final file = File(photoPath);
      if (file.existsSync()) avatarImage = FileImage(file);
    }

    final initials = fullName.trim().isNotEmpty
        ? () {
            final parts = fullName.trim().split(RegExp(r'\s+'));
            return parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : fullName.trim()[0].toUpperCase();
          }()
        : 'V';

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profil',
          style: VaultTypography.sans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: VaultColors.ink,
          ),
        ),
      ),
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
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // ── 1. Hero Avatar (Mobile Native Header) ─────────────
                      GestureDetector(
                        onTap: _openEditProfile,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: VaultColors.cardHover,
                                border: Border.all(
                                  color: VaultColors.accent,
                                  width: 2.5,
                                ),
                                image: avatarImage != null
                                    ? DecorationImage(
                                        image: avatarImage,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF141413)
                                        .withValues(alpha: 0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: avatarImage == null
                                  ? Text(
                                      initials,
                                      style: VaultTypography.mono(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: VaultColors.accent,
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: VaultColors.primaryButton,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: VaultColors.card,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Nama & Handle ──────────────────────────────────
                      Text(
                        fullName,
                        style: VaultTypography.sans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: VaultColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        style: VaultTypography.mono(
                          fontSize: 13,
                          color: VaultColors.ink2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Bio (jika diisi)
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            bio,
                            style: VaultTypography.sans(
                              fontSize: 13,
                              height: 1.4,
                              color: VaultColors.ink2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── 3. Tombol "Edit Profil" Terlihat Jelas (Thumb Zone)
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: VaultColors.ink,
                          ),
                          label: Text(
                            'Edit Profil',
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: VaultColors.card,
                            side: const BorderSide(color: VaultColors.hairline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── 4. Informasi Akun (Grouped Mobile List) ────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'INFORMASI AKUN',
                          style: VaultTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: VaultColors.ink2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VaultColors.hairline),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF141413)
                                  .withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Nama Lengkap',
                              value: fullName,
                              onTap: _openEditProfile,
                            ),
                            const Divider(
                                color: VaultColors.hairline,
                                height: 1,
                                indent: 52),
                            _InfoTile(
                              icon: Icons.alternate_email_rounded,
                              label: 'Username',
                              value: username,
                            ),
                            const Divider(
                                color: VaultColors.hairline,
                                height: 1,
                                indent: 52),
                            _InfoTile(
                              icon: Icons.inventory_2_outlined,
                              label: 'Total Aset di Vault',
                              value: '$_itemCount Item',
                            ),
                            const Divider(
                                color: VaultColors.hairline,
                                height: 1,
                                indent: 52),
                            _InfoTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Bergabung Sejak',
                              value: createdAt,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── 5. Tombol Keluar dari Akun ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton.icon(
                          onPressed: _showLogoutConfirmation,
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 17,
                            color: VaultColors.neg,
                          ),
                          label: Text(
                            'Keluar dari Akun',
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.neg,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                VaultColors.neg.withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
// _InfoTile — Baris Informasi Mobile Native
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: VaultColors.ink2),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: VaultTypography.sans(
                fontSize: 13,
                color: VaultColors.ink2,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: VaultTypography.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VaultColors.ink,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: VaultColors.ink3,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditProfileScreen — Form edit profil simpel & modern
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
        'Profil berhasil diperbarui',
        icon: Icons.check_circle_rounded,
        iconColor: VaultColors.pos,
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      _toast(
        'Gagal menyimpan perubahan.',
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

  @override
  Widget build(BuildContext context) {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? () {
            final parts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
            return parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : _nameCtrl.text.trim()[0].toUpperCase();
          }()
        : 'V';

    ImageProvider? provider;
    if (_photoPath != null && _photoPath!.isNotEmpty && !kIsWeb) {
      final file = File(_photoPath!);
      if (file.existsSync()) provider = FileImage(file);
    }

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
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
                  borderRadius: BorderRadius.circular(18),
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
                      'Simpan',
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
              const SizedBox(height: 12),
              // Avatar dengan tombol kamera
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VaultColors.cardHover,
                        border: Border.all(color: VaultColors.accent, width: 2),
                        image: provider != null
                            ? DecorationImage(
                                image: provider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: provider == null
                          ? Text(
                              initials,
                              style: VaultTypography.mono(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: VaultColors.accent,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
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
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickPhoto,
                child: Text(
                  'Ubah Foto Profil',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form fields card
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
                            'NAMA LENGKAP *',
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
                              hintText: 'Masukkan nama lengkap',
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
                            'BIO',
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
                              hintText: 'Tulis bio singkat...',
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
