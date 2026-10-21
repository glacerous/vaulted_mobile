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
                    child: Text(
                      'PAM 2026',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION TITLE
              Text(
                'Saran & Kesan',
                style: VaultTypography.sans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Refleksi pembelajaran mata kuliah Pemrograman Aplikasi Mobile.',
                style: VaultTypography.sans(
                  fontSize: 13,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 20),

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
                        Text(
                          '01',
                          style: VaultTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/',
                          style: VaultTypography.mono(
                            fontSize: 12,
                            color: VaultColors.hairline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KESAN PEMBELAJARAN',
                          style: VaultTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mata kuliah Pemrograman Aplikasi Mobile memberikan pemahaman yang sangat mendalam dan aplikatif mengenai ekosistem aplikasi modern. Praktik langsung pembuatan aplikasi dengan integrasi AI (Google Gemini LLM), Web3 / Blockchain sederhana, sensor hardware (Accelerometer & Gyroscope), serta Location-Based Services (LBS) sangat menantang dan memacu kreativitas kami dalam menghasilkan arsitektur mobile berkualitas industri.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        height: 1.55,
                        color: VaultColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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
                        Text(
                          '02',
                          style: VaultTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/',
                          style: VaultTypography.mono(
                            fontSize: 12,
                            color: VaultColors.hairline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SARAN PENGEMBANGAN',
                          style: VaultTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Semoga studi kasus integrasi arsitektur cloud modern (seperti Supabase / BaaS), manajemen state skala besar (BLoC / Riverpod), serta optimasi performa dan CI/CD deployment mobile dapat terus diperkaya dalam silabus, sehingga mahasiswa semakin siap memenuhi standar tinggi di industri rekayasa perangkat lunak internasional.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        height: 1.55,
                        color: VaultColors.body,
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
