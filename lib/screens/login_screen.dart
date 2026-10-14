import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import '../core/widgets/hairline_vault.dart';
import 'main_navigation_screen.dart';

/// Clean luxury onboarding and login screen for VAULTED.
/// Features the isometric Anatomy Desk Computer workstation paired with Valto the 2D pixel cat.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _signInUsernameController = TextEditingController(text: 'azzaky');
  final TextEditingController _signInPasswordController = TextEditingController(text: 'admin123');

  final TextEditingController _signUpUsernameController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isUnlocking = false;

  @override
  void dispose() {
    _signInUsernameController.dispose();
    _signInPasswordController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim, anim2, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _handleQuickUnlock() {
    if (_isUnlocking) return;
    HapticFeedback.heavyImpact();
    setState(() => _isUnlocking = true);
  }

  Future<void> _handleSignIn(StateSetter setModalState) async {
    final user = _signInUsernameController.text.trim();
    final pass = _signInPasswordController.text.trim();

    if (user.isEmpty || pass.isEmpty) return;

    setModalState(() => _isLoading = true);
    final success = await AuthService.instance.login(user, pass);

    if (!mounted) return;
    setModalState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context); // Close sheet
      setState(() => _isUnlocking = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Incorrect username or password.',
            style: VaultTypography.sans(fontSize: 12, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF141413),
        ),
      );
    }
  }

  Future<void> _handleSignUp(StateSetter setModalState) async {
    final user = _signUpUsernameController.text.trim();
    final pass = _signUpPasswordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter both username and password.',
            style: VaultTypography.sans(fontSize: 12, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF141413),
        ),
      );
      return;
    }

    setModalState(() => _isLoading = true);
    final success = await AuthService.instance.register(user, pass);

    if (!mounted) return;
    setModalState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context); // Close sheet
      setState(() => _isUnlocking = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create vault. Please try another username.',
            style: VaultTypography.sans(fontSize: 12, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF141413),
        ),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    HapticFeedback.selectionClick();
    final authenticated = await AuthService.instance.authenticateWithBiometrics();
    if (authenticated) {
      if (!mounted) return;
      setState(() => _isUnlocking = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Biometric authentication unavailable or cancelled.',
              style: VaultTypography.sans(fontSize: 12, color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF141413),
          ),
        );
      }
    }
  }

  void _showSignUpSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: const BoxDecoration(
                color: VaultColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: VaultColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create Your Vault',
                      style: VaultTypography.sans(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set up your private, locally encrypted asset vault.',
                      style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink2),
                    ),
                    const SizedBox(height: 20),

                    // Username Input
                    Text('DESIRED USERNAME', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _signUpUsernameController,
                      style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. azzaky',
                        hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
                        filled: true,
                        fillColor: VaultColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Input
                    Text('MASTER PASSWORD / PIN', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _signUpPasswordController,
                      obscureText: true,
                      style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Minimum 6 characters',
                        hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
                        filled: true,
                        fillColor: VaultColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleSignUp(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141413),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Create Vault', style: VaultTypography.sans(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSignInSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: const BoxDecoration(
                color: VaultColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: VaultColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome Back',
                      style: VaultTypography.sans(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Access your encrypted vault with your credentials.',
                      style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink2),
                    ),
                    const SizedBox(height: 18),

                    // Username
                    Text('USERNAME', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _signInUsernameController,
                      style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: VaultColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    Text('PASSWORD', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _signInPasswordController,
                      obscureText: true,
                      style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: VaultColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: VaultColors.hairline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Unlock Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleSignIn(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141413),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Unlock Vault', style: VaultTypography.sans(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Biometric Unlock
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleBiometricLogin();
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 20, color: VaultColors.accent),
                        label: Text(
                          'Biometric Unlock',
                          style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: VaultColors.ink),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VaultColors.hairline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        'Default Demo: azzaky / admin123',
                        style: VaultTypography.mono(fontSize: 10.5, color: VaultColors.ink3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background, // Warm porcelain
      body: Stack(
        children: [
          // 1. SUBTLE AMBIENT SURFACE GLOW (Anchoring the safe to the luxury floor)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.05),
                  radius: 0.75,
                  colors: [
                    Color(0x0C000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // TOP BRAND EMBLEM (Precision tactile vault lock emblem)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: VaultColors.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141413).withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Subtle warm gold folded corner
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6DEC9),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                topRight: Radius.circular(17),
                              ),
                            ),
                          ),
                        ),
                        // Center precision vault lock
                        const Center(
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 22,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // BRAND NAME (Clean authoritative serif typography, zero sparkles)
                  Text(
                    'VAULTED',
                    style: GoogleFonts.newsreader(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ELEGANT SUBTITLE
                  Text(
                    'Account for everything you own.',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: VaultColors.ink2,
                    ),
                  ),

                  // 3. CENTER HERO: AUTHENTIC 3D ISOMETRIC BANK VAULT WITH SLEEPING / WAKING VALTO
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!_isUnlocking) _handleQuickUnlock();
                        },
                        child: HairlineVault(
                          size: 200,
                          isUnlocking: _isUnlocking,
                          onUnlocked: _navigateToApp,
                          showGuardian: true,
                        ),
                      ),
                    ),
                  ),

                  // 4. BOTTOM ACTION ZONE (Thumb-zone luxury actions)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Unlock Vault" Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isUnlocking ? null : _handleQuickUnlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF141413), // Obsidian Jet
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF141413).withValues(alpha: 0.20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isUnlocking ? 'Opening Vault...' : 'Unlock Vault',
                                style: VaultTypography.sans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isUnlocking ? Icons.lock_open_rounded : Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Secondary Links: Sign in & Sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showSignInSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Sign in',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: VaultColors.ink,
                                  decoration: TextDecoration.underline,
                                  decorationColor: VaultColors.ink,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '·',
                            style: TextStyle(
                              fontSize: 14,
                              color: VaultColors.ink3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showSignUpSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Create Vault',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: VaultColors.ink,
                                  decoration: TextDecoration.underline,
                                  decorationColor: VaultColors.ink,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Subtle hardware security badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF55B374), // Terminal green dot
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LOCAL ENCRYPTED STORAGE · 256-BIT AES',
                            style: VaultTypography.mono(
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                              color: VaultColors.ink3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
