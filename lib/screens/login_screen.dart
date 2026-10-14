import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/security/auth_service.dart';
import '../core/widgets/valto_mascot.dart';
import 'main_navigation_screen.dart';

/// Personalized, high-end onboarding and login screen for VAULTED.
/// Inspired by the warm, editorial NoteNova mobile aesthetic (Satya / heysatya_).
/// Features a gentle levitating Valto cat mascot, warm dune landscape, and delightful typography.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController(text: 'azzaky');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Smooth 3.2-second peaceful levitation for Valto
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickStart() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final success = await AuthService.instance.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
          transitionsBuilder: (context, anim, anim2, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid credentials. Please try again.',
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
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
          transitionsBuilder: (context, anim, anim2, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
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

  void _showSignInSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: VaultColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
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
                    // Sheet Handle
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

                    // Title
                    Text(
                      'Access Your Vault',
                      style: VaultTypography.sans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in with your local credentials or biometric key.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        color: VaultColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Username
                    Text(
                      'USERNAME',
                      style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
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
                    Text(
                      'PASSWORD',
                      style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2),
                    ),
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _handleQuickStart();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141413),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(
                          'Unlock Vault',
                          style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
          // 1. SOFT DESERT DUNES & AMBIENT HORIZON (Background landscape)
          Positioned.fill(
            child: CustomPaint(
              painter: _DunesLandscapePainter(),
            ),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // TOP BRAND EMBLEM (Folded luxury tile like NoteNova)
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141413).withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Folded corner accent
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBE6DA),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        // Center 4-Point Gold Star Sparkle
                        const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 28,
                            color: Color(0xFF2E5BFF), // Vibrant signature royal star
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // BRAND NAME & EDITORIAL SPARKLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAULTED',
                        style: GoogleFonts.newsreader(
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: Color(0xFF2E5BFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // TAGLINE WITH DELICATE WARM UNDERLINE
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Account for everything you ',
                            style: VaultTypography.sans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: VaultColors.ink2,
                            ),
                          ),
                          Text(
                            'own.',
                            style: VaultTypography.sans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E5BFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Delicate curved underline
                      CustomPaint(
                        size: const Size(64, 5),
                        painter: _SwoopUnderlinePainter(color: const Color(0xFFE08D5B)),
                      ),
                    ],
                  ),

                  // 3. CENTER HERO: FLOATING VALTO CAT + SPEECH ANNOTATION
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft Ambient Radiant Aura
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF2E5BFF).withValues(alpha: 0.12),
                                  const Color(0xFFC0A85C).withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),

                          // Valto Mascot Character (96px, authentic glowing yellow eyes)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Valto is ready to protect your vault!',
                                    style: VaultTypography.sans(fontSize: 12, color: Colors.white),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: const Color(0xFF141413),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const ValtoMascot(
                                size: 96,
                                mood: ValtoMood.vigilant,
                              ),
                            ),
                          ),

                          // Curved Speech Annotation: "Hi, I'm Valto..."
                          Positioned(
                            bottom: 18,
                            left: 12,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomPaint(
                                  size: const Size(28, 38),
                                  painter: _AnnotationPointerPainter(color: const Color(0xFF2E5BFF)),
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hi, I'm Valto.",
                                      style: VaultTypography.sans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2E5BFF),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "Your personal vault partner\nwith superpowers.",
                                      style: VaultTypography.sans(
                                        fontSize: 11.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w500,
                                        color: VaultColors.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. BOTTOM ACTION ZONE (Big Royal Pill CTA + Clean "Sign in")
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Get started ✦" Large Rounded Pill Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleQuickStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5BFF), // NoteNova vibrant cobalt
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF2E5BFF).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get started',
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
                                      color: Colors.white,
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

/// Paints the silky, serene dunes landscape at the bottom of the canvas
class _DunesLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back gentle sand dune (soft warm sand tone)
    final backPaint = Paint()
      ..color = const Color(0xFFEDE9DE).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.45, h * 0.70, w, h * 0.75)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(backPath, backPaint);

    // Front gentle sand dune (soft creamy foreground)
    final frontPaint = Paint()
      ..color = const Color(0xFFE5E0D3).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.55, h * 0.80, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the delicate, playful hand-drawn curved underline accent
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

/// Paints the playful curved pointer line connecting the "Hi, I'm Valto" text to Valto
class _AnnotationPointerPainter extends CustomPainter {
  final Color color;
  _AnnotationPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.65, size.width * 0.6, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
