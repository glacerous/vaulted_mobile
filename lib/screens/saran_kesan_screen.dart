import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

/// Screen dedicated to: "Saran dan Kesan mata kuliah Pemrograman Aplikasi Mobile"
/// Fulfills the explicit Bottom Navigation requirement in the final project syllabus.
class SaranKesanScreen extends StatelessWidget {
  const SaranKesanScreen({super.key});

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: VaultColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          'PAM 2026',
                          style: VaultTypography.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION TAG
              Text(
                'EVALUASI AKADEMIK',
                style: VaultTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saran & Kesan Kuliah',
                style: VaultTypography.sans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pemrograman Aplikasi Mobile · Sistem Informasi UPNYK',
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 24),

              // CARD KESAN
              Container(
                width: double.infinity,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VaultColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: VaultColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kesan Pembelajaran',
                              style: VaultTypography.sans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: VaultColors.ink,
                              ),
                            ),
                            Text(
                              'Pengalaman Praktis & Eksplorasi Mobile',
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
                      'Mata kuliah Pemrograman Aplikasi Mobile memberikan pemahaman yang sangat mendalam dan aplikatif mengenai ekosistem aplikasi modern. Praktik langsung pembuatan aplikasi dengan integrasi AI (Google Gemini LLM), Web3 / Blockchain sederhana, sensor hardware (Accelerometer & Gyroscope), serta Location-Based Services (LBS) sangat menantang dan memacu kreativitas kami dalam menghasilkan arsitektur mobile berkualitas industri.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        height: 1.55,
                        color: VaultColors.ink.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CARD SARAN
              Container(
                width: double.infinity,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VaultColors.pos.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: VaultColors.pos,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saran Pengembangan',
                              style: VaultTypography.sans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: VaultColors.ink,
                              ),
                            ),
                            Text(
                              'Untuk Masa Depan Kurikulum',
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
                      'Semoga studi kasus integrasi arsitektur cloud modern (seperti Supabase / BaaS), manajemen state skala besar (BLoC / Riverpod), serta optimasi performa dan CI/CD deployment mobile dapat terus diperkaya dalam silabus, sehingga mahasiswa semakin siap memenuhi standar tinggi di industri rekayasa perangkat lunak internasional.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        height: 1.55,
                        color: VaultColors.ink.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KELOMPOK PENGEMBANG
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
                    Text(
                      'TIM PENGEMBANG PROYEK',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: VaultColors.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMemberRow('124240010', 'Pindo Dinarman Situngkir'),
                    _buildMemberRow('124240018', 'Azzaky Raihan'),
                    _buildMemberRow('124240031', 'Ariel Saputra'),
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
