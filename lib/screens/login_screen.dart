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
  final TextEditingController _signInUsernameController = TextEditingController(text: 'azzaky');
  final TextEditingController _signInPasswordController = TextEditingController(text: 'admin123');

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
          // 1. ORGANIC WARM HORIZON DUNES (Grounding the vault in a tactile luxury landscape)
          Positioned.fill(
            child: CustomPaint(
              painter: _OrganicDunesPainter(),
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

                  // 3. CENTER HERO: PROMINENT VALTO HERO WITH LEVITATION & FLOATING ASSET TELEMETRY
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _levitateController,
                        builder: (context, _) {
                          return SizedBox(
                            width: 320,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Ambient soft warm gold aura
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        VaultColors.accent.withValues(alpha: 0.18),
                                        VaultColors.accent.withValues(alpha: 0.04),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),

                                // Dynamic diffused floor shadow that expands/contracts with hover
                                Positioned(
                                  bottom: 22,
                                  child: Transform.scale(
                                    scaleX: _shadowAnim.value,
                                    scaleY: 0.85 * _shadowAnim.value,
                                    child: Container(
                                      width: 125,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF141413).withValues(alpha: 0.12),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // BIG VALTO HERO (size 190 - crisp 16-bit pixel fidelity)
                                Transform.translate(
                                  offset: Offset(0, _levitateAnim.value),
                                  child: const ValtoMascot(
                                    size: 190,
                                    mood: ValtoMood.vigilant,
                                  ),
                                ),

                                // FLOATING ASSET PILL 1 (Upper Left: Patek Philippe)
                                Positioned(
                                  left: 2,
                                  top: 36 + (-_levitateAnim.value * 0.7),
                                  child: const _FloatingAssetChip(
                                    icon: Icons.watch_outlined,
                                    title: 'PATEK 5711',
                                    value: '\$118,500',
                                  ),
                                ),

                                // FLOATING ASSET PILL 2 (Lower Right: Porsche 911 GT3)
                                Positioned(
                                  right: 2,
                                  bottom: 50 + (_levitateAnim.value * 0.7),
                                  child: const _FloatingAssetChip(
                                    icon: Icons.directions_car_outlined,
                                    title: '911 GT3 RS',
                                    value: '\$325,000',
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

/// Floating tactile luxury asset badge orbiting Valto
class _FloatingAssetChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _FloatingAssetChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8E2D8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141413).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child: Icon(
              icon,
              size: 14,
              color: VaultColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: VaultTypography.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: VaultTypography.mono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Organic warm horizon dunes painted on the lower canvas, grounding the scene
class _OrganicDunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Distant soft dune (#F3EFE8 -> #EBE3D6)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.68);
    path1.quadraticBezierTo(
      size.width * 0.32,
      size.height * 0.62,
      size.width * 0.68,
      size.height * 0.70,
    );
    path1.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.73,
      size.width,
      size.height * 0.71,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF3EFE8).withValues(alpha: 0.75),
          const Color(0xFFEBE3D6).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38));
    canvas.drawPath(path1, paint1);

    // 2. Midground warm dune (#EBE2D4 -> #E2D8C7)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.77);
    path2.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.80,
      size.width * 0.58,
      size.height * 0.74,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.69,
      size.width,
      size.height * 0.72,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFEBE2D4).withValues(alpha: 0.85),
          const Color(0xFFE2D8C7).withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.69, size.width, size.height * 0.31));
    canvas.drawPath(path2, paint2);

    // 3. Foreground crest highlight stroke
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final crestPath = Path();
    crestPath.moveTo(0, size.height * 0.77);
    crestPath.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.80,
      size.width * 0.58,
      size.height * 0.74,
    );
    crestPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.69,
      size.width,
      size.height * 0.72,
    );
    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
