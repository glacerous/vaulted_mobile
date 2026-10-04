import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
          color: VaultColors.background,
          border: Border(top: BorderSide(color: VaultColors.hairline, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: VaultColors.background,
          selectedItemColor: VaultColors.accent,
          unselectedItemColor: VaultColors.ink3,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: VaultTypography.mono(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined, size: 20),
              activeIcon: Icon(Icons.shield, size: 20),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_outlined, size: 20),
              activeIcon: Icon(Icons.radar, size: 20),
              label: 'Radar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me_outlined, size: 20),
              activeIcon: Icon(Icons.near_me, size: 20),
              label: 'LBS Care',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 20),
              activeIcon: Icon(Icons.person, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
