import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import '../core/widgets/valto_mascot.dart';
import 'main_navigation_screen.dart';

/// Clean luxury onboarding and login screen for VAULTED.
/// Formatted in the authentic warm porcelain and luxury gold aesthetic.
/// Features an anchored, animated Valto cat guardian, genuine Sign Up / Sign In flows, and zero AI slop.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _signInUsernameController = TextEditingController(text: 'azzaky');
  final TextEditingController _signInPasswordController = TextEditingController(text: 'admin123');

  final TextEditingController _signUpUsernameController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
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
    final success = await AuthService.instance.login(user, pass);

    if (!mounted) return;
    setModalState(() => _isLoading = false);

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
      _navigateToApp();
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
                                  const Icon(Icons.auto_awesome_rounded, size: 16, color: VaultColors.accent),
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
          // 1. SOFT DESERT DUNES LANDSCAPE (Gentle warm dunes)
          Positioned.fill(
            child: CustomPaint(
              painter: _WarmDunesPainter(),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // TOP BRAND EMBLEM (Luxury porcelain squircle with gold folded corner and vault sparkle)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: VaultColors.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141413).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Folded corner in warm gold
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6DEC9),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(9),
                                topRight: Radius.circular(19),
                              ),
                            ),
                          ),
                        ),
                        // Center warm gold luxury star
                        const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 26,
                            color: VaultColors.accent, // Warm Signature Gold
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BRAND NAME & EDITORIAL SPARKLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAULTED',
                        style: GoogleFonts.newsreader(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: VaultColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // TAGLINE WITH DELICATE WARM GOLD UNDERLINE
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Account for everything you ',
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: VaultColors.ink2,
                            ),
                          ),
                          Text(
                            'own.',
                            style: VaultTypography.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: VaultColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Delicate curved underline in warm gold
                      CustomPaint(
                        size: const Size(58, 4),
                        painter: _SwoopUnderlinePainter(color: VaultColors.accent),
                      ),
                    ],
                  ),

                  // 3. CENTER HERO: FRAMED VALTO COMPANION WITH DIRECTLY ANCHORED SPEECH BUBBLE
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grounded Speech Callout (Sitting directly above Valto with a bottom indicator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: VaultColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VaultColors.hairline),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF141413).withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Hi, I'm Valto.",
                                    style: VaultTypography.sans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: VaultColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Your personal vault guardian.",
                                    style: VaultTypography.sans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: VaultColors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Little Pointer Triangle
                            CustomPaint(
                              size: const Size(14, 8),
                              painter: _BubbleTrianglePainter(),
                            ),
                            const SizedBox(height: 8),

                            // Valto Cat on Soft Ambient Halo
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        VaultColors.accent.withValues(alpha: 0.16),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 1.0],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Valto: "Welcome! Your private vault is ready."',
                                          style: VaultTypography.sans(fontSize: 12, color: Colors.white),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: const Color(0xFF141413),
                                      ),
                                    );
                                  },
                                  child: const ValtoMascot(
                                    size: 92,
                                    mood: ValtoMood.vigilant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. BOTTOM ACTION ZONE (Jet Obsidian "Sign up ✦" + Clean "Sign in")
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Get started — Sign up ✦" Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showSignUpSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF141413), // Signature Oyenza Obsidian
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF141413).withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
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
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: VaultColors.accent, // Signature Luxury Gold Sparkle
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // "Sign in" Underlined Link
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
                      const SizedBox(height: 10),
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

/// Paints the warm, silky dunes landscape at the bottom of the canvas
class _WarmDunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back sand curve (warm porcelain dune)
    final backPaint = Paint()
      ..color = const Color(0xFFEDE9DF).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.40, h * 0.76, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(backPath, backPaint);

    // Front sand curve (soft cream dune)
    final frontPaint = Paint()
      ..color = const Color(0xFFE4DFD3).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h * 0.89)
      ..quadraticBezierTo(w * 0.60, h * 0.84, w, h * 0.87)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the delicate curved underline accent in warm gold
class _SwoopUnderlinePainter extends CustomPainter {
  final Color color;
  _SwoopUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width - 2, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the little speech bubble pointer triangle
class _BubbleTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VaultColors.card
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = VaultColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(0, 0), Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(size.width / 2, size.height), Offset(size.width, 0), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
