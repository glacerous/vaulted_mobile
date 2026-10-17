import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import 'home_vault_screen.dart';
import 'search_radar_screen.dart';
import 'warranty_lbs_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();

  final List<Widget> _pages = const [
    HomeVaultScreen(),
    SearchRadarScreen(),
    WarrantyLbsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShakeSensor();
  }

  // Sensor 1: Accelerometer Shake Detection (Slide 1 Requirement)
  void _initShakeSensor() {
    if (kIsWeb) return;
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final gX = event.x;
      final gY = event.y;
      final gZ = event.z;

      final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      // Threshold for device shake (> 18 m/s^2)
      if (gForce > 18.0) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inSeconds > 2) {
          _lastShakeTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: VaultColors.card,
                behavior: SnackBarBehavior.floating,
                content: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: VaultColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Accelerometer Sensor: Shake detected! Stealth mode active.',
                      style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
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

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBE4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                activeIcon,
                size: 20,
                color: const Color(0xFF141413),
              ),
            )
          else ...[
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF73716A),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: VaultTypography.sans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF73716A),
              ),
            ),
          ],
        ],
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
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEBE8E0), width: 1)),
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
                  label: 'Vault',
                  icon: Icons.shield_outlined,
                  activeIcon: Icons.shield_rounded,
                ),
                _buildTabItem(
                  index: 1,
                  label: 'Radar',
                  icon: Icons.radar_outlined,
                  activeIcon: Icons.radar_rounded,
                ),
                _buildTabItem(
                  index: 2,
                  label: 'LBS Care',
                  icon: Icons.near_me_outlined,
                  activeIcon: Icons.near_me_rounded,
                ),
                _buildTabItem(
                  index: 3,
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
