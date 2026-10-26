import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import '../core/services/notification_service.dart';
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
  // SENSOR & NAVIGATION SETTINGS
  // - Accelerometer: Emergency Shake to Auto Lock
  // - Gyroscope: 3D Hologram Tilt on Collection Cards (GyroTilt)
  // =========================================================================
  static const double shakeSensitivity = 17.0;     // Accelerometer shake threshold m/s²
  static const int sensorCooldownSeconds = 2;       // Cooldown seconds between detections

  int _currentIndex = 0;
  StreamSubscription? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();

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
    if (!kIsWeb) {
      NotificationService.instance.requestPermission();
    }
  }

  void _initSensors() {
    if (kIsWeb) return;
    _initAccelerometerLock();
  }

  // Sensor: Accelerometer — Emergency Shake to Auto Lock Vault
  void _initAccelerometerLock() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (gForce > shakeSensitivity) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inSeconds > sensorCooldownSeconds) {
          _lastShakeTime = now;
          HapticFeedback.heavyImpact();
          if (mounted) {
            VaultToast.show(
              context,
              icon: Icons.lock_outline_rounded,
              iconColor: VaultColors.warn,
              message: 'Accelerometer: Emergency Shake Detected! Vault Locked.',
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
                          'Confirm Sign Out',
                          style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w700, color: VaultColors.ink),
                        ),
                        Text(
                          'End authenticated vault session',
                          style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to sign out of Vaulted? Your local authentication session will end safely.',
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
                          'Cancel',
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
                          'Sign Out',
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
                  label: 'Profile',
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
