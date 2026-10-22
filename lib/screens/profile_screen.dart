import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// DAFTAR ANGGOTA KELOMPOK PENGEMBANG (Ubah / tambah di sini jika diminta dosen)
  static const List<Map<String, String?>> developers = [
    {
      'name': 'Pindo Dinarman Situngkir',
      'nim': '124240031',
      'initials': 'PS',
      'image': 'assets/images/pindo.jpeg',
    },
    {
      'name': 'Azzaky Raihan',
      'nim': '124240018',
      'initials': 'AR',
      'image': 'assets/images/azzaky.png',
    },
    {
      'name': 'Ariel Saputra',
      'nim': '124240010',
      'initials': 'AS',
      'image': 'assets/images/ariel.jpeg',
    },
  ];

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                  'Apakah Anda yakin ingin keluar dari akun Vaulted? Sesi otentikasi lokal Anda akan diakhiri.',
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
                          if (!context.mounted) return;
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BRAND HEADER
              Text(
                'VAULTED',
                style: VaultTypography.mono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // 2. SECTION TITLE
              Text(
                'Developers',
                style: VaultTypography.sans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // 3. MEMBER CARDS (Mudah ditambah / diubah saat presentasi)
              ...developers.map((dev) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildMemberCard(
                  name: dev['name']!,
                  nim: dev['nim']!,
                  initials: dev['initials']!,
                  imagePath: dev['image'],
                ),
              )),
              const SizedBox(height: 28),

              // 4. LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(context),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required String name,
    required String nim,
    required String initials,
    required String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Row(
        children: [
          // Avatar with photo or initials
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VaultColors.cardHover,
              border: Border.all(color: VaultColors.accent, width: 1.5),
              image: imagePath != null
                  ? DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: imagePath == null
                ? Text(
                    initials,
                    style: VaultTypography.mono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: VaultTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$nim  Sistem Informasi',
                  style: VaultTypography.mono(
                    fontSize: 11,
                    color: VaultColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
