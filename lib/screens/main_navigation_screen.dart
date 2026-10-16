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

  void _showAddModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VaultColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'QUICK VAULT ACTION',
                style: VaultTypography.mono(fontSize: 11, letterSpacing: 1.2, color: VaultColors.ink2),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: VaultColors.cardHover, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_rounded, color: VaultColors.ink, size: 20),
                ),
                title: Text('Scan Physical Receipt', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('OCR auto-extract items & warranty', style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink2)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: VaultColors.cardHover, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_shopping_cart_rounded, color: VaultColors.ink, size: 20),
                ),
                title: Text('Manual Asset Entry', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Log serial number, brand & purchase value', style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink2)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 3);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddModal(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF141413),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Add',
            style: VaultTypography.sans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF141413),
            ),
          ),
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
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                _buildTabItem(
                  index: 1,
                  label: 'History',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                ),
                _buildTabItem(
                  index: 2,
                  label: 'Reports',
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                ),
                _buildTabItem(
                  index: 3,
                  label: 'Wealth',
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                ),
                _buildAddButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
