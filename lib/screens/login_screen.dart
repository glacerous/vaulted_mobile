import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import '../core/widgets/valto_mascot.dart';
import 'main_navigation_screen.dart';

/// Clean luxury onboarding and login screen for VAULTED.
/// Features the isometric Anatomy Desk Computer workstation paired with Valto the 2D pixel cat.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _signInUsernameController = TextEditingController();
  final TextEditingController _signInPasswordController = TextEditingController();

  final TextEditingController _signUpFullNameController = TextEditingController();
  final TextEditingController _signUpUsernameController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();

  late AnimationController _levitateController;
  late Animation<double> _levitateAnim;
  late Animation<double> _shadowAnim;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _levitateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _levitateAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _levitateController, curve: Curves.easeInOutSine),
    );

    _shadowAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _levitateController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _levitateController.dispose();
    _signInUsernameController.dispose();
    _signInPasswordController.dispose();
    _signUpFullNameController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim, anim2, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _handleSignIn(StateSetter setModalState) async {
    final user = _signInUsernameController.text.trim();
    final pass = _signInPasswordController.text.trim();

    if (user.isEmpty || pass.isEmpty) return;

    setModalState(() => _isLoading = true);
    try {
      final success = await AuthService.instance.login(user, pass);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Close sheet
        _navigateToApp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrect username or password.',
              style: VaultTypography.sans(fontSize: 12, color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: VaultColors.toastBg,
          ),
        );
      }
    } catch (e) {
      debugPrint('[LoginScreen] Sign-in error: $e');
    } finally {
      if (mounted) {
        setModalState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp(StateSetter setModalState) async {
    final name = _signUpFullNameController.text.trim();
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
          backgroundColor: VaultColors.toastBg,
        ),
      );
      return;
    }

    setModalState(() => _isLoading = true);
    try {
      final success = await AuthService.instance.register(
        user,
        pass,
        fullName: name.isNotEmpty ? name : user,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Close sheet
        _navigateToApp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Username already registered. Please try another.',
              style: VaultTypography.sans(fontSize: 12, color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: VaultColors.toastBg,
          ),
        );
      }
    } catch (e) {
      debugPrint('[LoginScreen] Sign-up error: $e');
    } finally {
      if (mounted) {
        setModalState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    HapticFeedback.selectionClick();
    final authenticated = await AuthService.instance.authenticateWithBiometrics();
    if (authenticated) {
      if (!mounted) return;
      _navigateToApp();
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
            backgroundColor: VaultColors.toastBg,
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

                    // Full Name Input
                    Text('FULL NAME', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _signUpFullNameController,
                      style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Azzaky Raihan',
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
                          backgroundColor: VaultColors.primaryButton,
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() {
                            _signInUsernameController.text = 'azzaky';
                            _signInPasswordController.text = 'admin123';
                          });
                        },
                        child: Text(
                          '⚡ Quick fill demo account',
                          style: VaultTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Unlock Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleSignIn(setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VaultColors.primaryButton,
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
          // 1. DITHER PIXEL CANYON LANDSCAPE (Transparent authentic dither art environment)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            height: 480,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.70, 0.88, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/dither_landscape.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // TOP MONOSPACE REPOSITORY EYEBROW (Clean luxury editorial, zero clip art)
                  Text(
                    'PERSONAL ASSET REPOSITORY',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                      color: VaultColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // BRAND NAME (Clean authoritative serif typography, zero sparkles)
                  Text(
                    'VAULTED',
                    style: GoogleFonts.newsreader(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ELEGANT SUBTITLE
                  Text(
                    'Account for everything you own.',
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: VaultColors.ink2,
                    ),
                  ),

                  // 3. CENTER HERO: VALTO IN RETRO DITHER CANYON
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _levitateController,
                        builder: (context, _) {
                          return SizedBox(
                            width: 250,
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Dynamic diffused shadow grounded on canyon floor
                                Positioned(
                                  bottom: 20,
                                  child: Transform.scale(
                                    scaleX: _shadowAnim.value,
                                    scaleY: 0.85 * _shadowAnim.value,
                                    child: Container(
                                      width: 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: VaultColors.ink.withValues(alpha: 0.16),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // VALTO GUARDIAN (16-bit retro pixel cat nestled in the dither valley)
                                Transform.translate(
                                  offset: Offset(0, _levitateAnim.value),
                                  child: const ValtoMascot(
                                    size: 185,
                                    mood: ValtoMood.vigilant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 4. BOTTOM ACTION ZONE (Thumb-zone luxury actions)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Sign up" Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _showSignUpSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.primaryButton,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: VaultColors.primaryButton.withValues(alpha: 0.20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign up',
                                style: VaultTypography.sans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Secondary "Sign in" Link
                      GestureDetector(
                        onTap: _showSignInSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink,
                              decoration: TextDecoration.underline,
                              decorationColor: VaultColors.ink,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

