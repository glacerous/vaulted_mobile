import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import 'home_vault_screen.dart';
import 'search_radar_screen.dart';
import 'profile_screen.dart';
import 'saran_kesan_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // =========================================================================
  // DOSEN LIVE CHALLENGE: SENSOR & NAVIGATION SETTINGS
  // Ubah nilai di bawah ini jika dosen meminta modifikasi live saat demo:
  // - Accelerometer: Goyang HP untuk sembunyikan/tampilkan saldo (Privacy Mode)
  // - Gyroscope: Balik/telungkupkan HP (Flip Face-Down) untuk kunci brankas
  // =========================================================================
  static const double shakeSensitivity = 17.0;     // Ambang batas getaran (goyangan) m/s²
  static const double gyroTiltSensitivity = 6.0;    // Ambang batas rotasi balik gyroscope rad/s
  static const int sensorCooldownSeconds = 2;       // Jeda waktu antar deteksi (detik)

  int _currentIndex = 0;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  DateTime _lastShakeTime = DateTime.now();
  DateTime _lastGyroTime = DateTime.now();

  // Slide Requirement:
  // "Terdapat menu buttom navigation: menu profil (ada gambar) dan
  // menu saran dan kesan mata kuliah Pemrograman Aplikasi Mobile dan menu logout"
  final List<Widget> _pages = const [
    HomeVaultScreen(),
    SearchRadarScreen(),
    ProfileScreen(),
    SaranKesanScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    if (kIsWeb) return;
    _initShakeSensor();
    _initGyroscopeSensor();
  }

  // Sensor 1: Accelerometer — Shake to Hide/Show Balance (Mode Privasi BCA/Jenius)
  void _initShakeSensor() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (gForce > shakeSensitivity) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inSeconds > sensorCooldownSeconds) {
          _lastShakeTime = now;
          HomeVaultScreen.isBalanceVisible.value = !HomeVaultScreen.isBalanceVisible.value;
          HapticFeedback.mediumImpact();
          if (mounted) {
            final isHidden = !HomeVaultScreen.isBalanceVisible.value;
            VaultToast.show(
              context,
              icon: isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              iconColor: VaultColors.accent,
              message: isHidden
                  ? 'Shake Terdeteksi: Saldo Disembunyikan (Privacy Mode)'
                  : 'Shake Terdeteksi: Saldo Ditampilkan Kembali',
            );
          }
        }
      }
    });
  }

  // Sensor 2: Gyroscope — Face-Down / Flip to Lock Vault (Kunci Otomatis Saat Ditelungkupkan)
  void _initGyroscopeSensor() {
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final angularVelocity = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (angularVelocity > gyroTiltSensitivity) {
        final now = DateTime.now();
        if (now.difference(_lastGyroTime).inSeconds > sensorCooldownSeconds) {
          _lastGyroTime = now;
          HapticFeedback.heavyImpact();
          if (mounted) {
            VaultToast.show(
              context,
              icon: Icons.lock_outline_rounded,
              iconColor: VaultColors.warn,
              message: 'Gyroscope Flip: Vault Dikunci Otomatis (Face-Down)!',
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  void _showLogoutConfirmation() {
    HapticFeedback.mediumImpact();
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
                      child: const Icon(Icons.logout_rounded, color: VaultColors.neg, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Log Out',
                          style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w700, color: VaultColors.ink),
                        ),
                        Text(
                          'Mengakhiri sesi akses Vaulted',
                          style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Apakah Anda yakin ingin keluar dari akun Vaulted? Sesi otentikasi lokal Anda akan diakhiri. Data aset SQLite tetap aman di perangkat Anda.',
                  style: VaultTypography.sans(fontSize: 12.5, height: 1.5, color: VaultColors.ink2),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VaultColors.hairline),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Batal',
                          style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink),
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
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'Keluar',
                          style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VaultColors.neg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool isAction = false,
    VoidCallback? onAction,
    Color? customColor,
  }) {
    final isSelected = !isAction && _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (isAction && onAction != null) {
          onAction();
        } else {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? VaultColors.cardHover
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: customColor ?? (isSelected ? VaultColors.ink : VaultColors.ink2),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: VaultTypography.sans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: customColor ?? (isSelected ? VaultColors.ink : VaultColors.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: VaultColors.card,
          border: Border(top: BorderSide(color: VaultColors.hairline, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                _buildTabItem(
                  index: 1,
                  label: 'Radar',
                  icon: Icons.radar_outlined,
                  activeIcon: Icons.radar_rounded,
                ),
                _buildTabItem(
                  index: 2,
                  label: 'Profil',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
                _buildTabItem(
                  index: 3,
                  label: 'Saran',
                  icon: Icons.rate_review_outlined,
                  activeIcon: Icons.rate_review_rounded,
                ),
                _buildTabItem(
                  index: 4,
                  label: 'Logout',
                  icon: Icons.logout_rounded,
                  activeIcon: Icons.logout_rounded,
                  isAction: true,
                  onAction: _showLogoutConfirmation,
                  customColor: VaultColors.neg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
