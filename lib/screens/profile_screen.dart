import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              Text(
                'ACCOUNT & SYSTEM',
                style: VaultTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'User Profile & Course Info',
                style: VaultTypography.sans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card with Picture (Slide 1 Requirement: menu profil ada gambar)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VaultColors.cardHover,
                        border: Border.all(color: VaultColors.accent, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Azzaky Raihan', style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('124240018 · Sistem Informasi', style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink2)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: VaultColors.badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VAULT MASTER PRO',
                              style: VaultTypography.mono(fontSize: 9, fontWeight: FontWeight.w600, color: VaultColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Team Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelompok Pengembang (SI UPNYK)', style: VaultTypography.sectionTitle),
                    const SizedBox(height: 10),
                    _buildMemberRow('124240010', 'Pindo Dinarman Situngkir'),
                    _buildMemberRow('124240018', 'Azzaky Raihan'),
                    _buildMemberRow('124240031', 'Ariel Saputra'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION: Saran dan Kesan MK Pemrograman Aplikasi Mobile (Slide 1 Requirement)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 18, color: VaultColors.accent),
                        const SizedBox(width: 8),
                        Text('Saran & Kesan Mata Kuliah', style: VaultTypography.sectionTitle),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kesan:',
                      style: VaultTypography.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: VaultColors.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mata kuliah Pemrograman Aplikasi Mobile memberikan wawasan yang sangat aplikatif mengenai ekosistem aplikasi modern. Praktik langsung pembuatan aplikasi dengan integrasi AI, Web3, sensor hardware, dan LBS sangat menantang dan memacu kreativitas mahasiswa.',
                      style: VaultTypography.cardDescription,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Saran:',
                      style: VaultTypography.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: VaultColors.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semoga studi kasus integrasi arsitektur cloud, manajemen state, dan optimasi performa mobile dapat terus diperbanyak sehingga mahasiswa semakin siap menghadapi standar industri profesional.',
                      style: VaultTypography.cardDescription,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button (Slide 1 Requirement: menu logout)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.instance.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16, color: VaultColors.neg),
                  label: Text('Log Out of Vault', style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: VaultColors.neg)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: VaultColors.hairline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String nim, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink)),
          Text(nim, style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink2)),
        ],
      ),
    );
  }
}
