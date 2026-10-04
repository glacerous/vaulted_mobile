import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController(text: 'azzaky');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.instance.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Password or username incorrect.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await AuthService.instance.authenticateWithBiometrics();
    if (authenticated) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Biometric authentication cancelled or not configured.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Logo & Brand Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: VaultColors.badgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: VaultColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.brightness_low_rounded,
                      color: VaultColors.accent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'VAULTED',
                    style: VaultTypography.sans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: VaultColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Account for everything you own.',
                    style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink2),
                  ),
                ),
                const SizedBox(height: 36),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Access Your Vault', style: VaultTypography.sectionTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Encrypted local auth with SHA-256 session integrity.',
                        style: VaultTypography.cardDescription,
                      ),
                      const SizedBox(height: 20),

                      // Username Field
                      Text('USERNAME', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: VaultColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VaultColors.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VaultColors.hairline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      Text('PASSWORD', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: VaultColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VaultColors.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: VaultColors.hairline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.neg),
                          ),
                        ),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.ink,
                            foregroundColor: VaultColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.background))
                              : Text('Unlock Vault', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: VaultColors.background)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Biometric Login Button (Slide 1 Requirement)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint_rounded, size: 20, color: VaultColors.accent),
                          label: Text(
                            'Biometric Unlock',
                            style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w500, color: VaultColors.ink),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: VaultColors.hairline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Default Demo: azzaky / admin123',
                    style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
