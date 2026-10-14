import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// Alias to maintain backward compatibility with previous imports
typedef AsciiCloudSeaHeader = DitheredCloudSeaHeader;

/// A warm, friendly, casual luxury header featuring an authentic fine-grained
/// Bayer 4x4 dithered sunset cloud-sea artwork across the canvas.
/// Designed for casual mobile users with a clean, welcoming layout matching the "Illust" mode.
class DitheredCloudSeaHeader extends StatefulWidget {
  final TextEditingController promptController;
  final FocusNode promptFocus;
  final bool isAiProcessing;
  final VowlMood vowlMood;
  final VoidCallback onSubmit;

  const DitheredCloudSeaHeader({
    super.key,
    required this.promptController,
    required this.promptFocus,
    required this.isAiProcessing,
    required this.vowlMood,
    required this.onSubmit,
  });

  @override
  State<DitheredCloudSeaHeader> createState() => _DitheredCloudSeaHeaderState();
}

class _DitheredCloudSeaHeaderState extends State<DitheredCloudSeaHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE58163).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. FINE-GRAIN HIGH-DENSITY DITHERED SUNSET SCENERY (Background Art)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FineDitherCloudSeaPainter(
                      progress: _animController.value,
                    ),
                  );
                },
              ),
            ),

            // 2. WARM CASUAL CONTENT OVERLAY (Matching "Illust" option exactly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date line
                  Text(
                    dateStr,
                    style: VaultTypography.mono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Giant Bold Greeting
                  Text(
                    _getGreeting(),
                    style: VaultTypography.sans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Conversational Prompt Subtitle
                  Text(
                    'Say "coffee 25k" or snap a receipt. It takes two seconds.',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(height: 38),

                  // 3. VOWL MASCOT PEEKING + FROSTED GLASS OMNIBAR
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Vowl peeking gracefully right over the frosted capsule
                      Positioned(
                        top: -34,
                        right: 32,
                        child: VowlMascot(
                          size: 42,
                          mood: widget.vowlMood,
                          showHat: true,
                        ),
                      ),

                      // Frosted Glass Capsule
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.38),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                // Golden Vault Sparkle / Icon
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Omnibar Input
                                Expanded(
                                  child: TextField(
                                    controller: widget.promptController,
                                    focusNode: widget.promptFocus,
                                    onSubmitted: (_) => widget.onSubmit(),
                                    style: VaultTypography.sans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ask Vowl anything...',
                                      hintStyle: VaultTypography.sans(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.78),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),

                                // Black Circle Arrow Button (Oyenza signature)
                                GestureDetector(
                                  onTap: widget.onSubmit,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF141413),
                                    ),
                                    child: widget.isAiProcessing
                                        ? const Padding(
                                            padding: EdgeInsets.all(9),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}

/// High-density fine-grain Bayer 4x4 ordered dither painter.
/// Creates a true scenic landscape of the sunset cloud sea, glowing sun,
/// mountain horizon silhouettes, and flapping dusk birds using micro-halftone dots.
class _FineDitherCloudSeaPainter extends CustomPainter {
  final double progress;

  _FineDitherCloudSeaPainter({required this.progress});

  // Standard 4x4 Bayer Dithering Matrix normalized (-0.47 to 0.47)
  static const List<double> _bayer4x4 = [
    0.0 / 16.0 - 0.47,
    8.0 / 16.0 - 0.47,
    2.0 / 16.0 - 0.47,
    10.0 / 16.0 - 0.47,
    12.0 / 16.0 - 0.47,
    4.0 / 16.0 - 0.47,
    14.0 / 16.0 - 0.47,
    6.0 / 16.0 - 0.47,
    3.0 / 16.0 - 0.47,
    11.0 / 16.0 - 0.47,
    1.0 / 16.0 - 0.47,
    9.0 / 16.0 - 0.47,
    15.0 / 16.0 - 0.47,
    7.0 / 16.0 - 0.47,
    13.0 / 16.0 - 0.47,
    5.0 / 16.0 - 0.47,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Atmospheric Dusk Gradient (deep violet to dark peach foundation)
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF381F47), // Deep dusk twilight violet
          Color(0xFF5D2D50), // Mauve dusk
          Color(0xFF8B3A44), // Terracotta shadow
          Color(0xFFB44E36), // Deep apricot
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // High density grid: 150 columns x 92 rows
    // On a ~360x220 container, cell size is ~2.4px x 2.4px
    const cols = 150;
    const rows = 92;
    final cellW = w / cols;
    final cellH = h / rows;

    // Sinking Sun parameters
    final sunCol = cols * 0.72;
    final sunRow = rows * 0.44;
    final sunR = 12.0; // In grid units
    final pulse = sin(progress * 2 * pi * 3);

    final drift = progress * 2 * pi;

    // Pre-allocated painter for micro-dither dots
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * cellW + cellW * 0.5;
        final cy = r * cellH + cellH * 0.5;

        final u = c / cols;
        final v = r / rows;

        // Wave profiles for the rolling cloud sea layers
        final wave1 = sin(u * 7.5 + drift * 0.7) * 0.055;
        final wave2 = cos(u * 13.0 - drift * 0.4) * 0.035;
        final wave3 = sin(u * 21.0 + drift * 1.2) * 0.015;
        final horizonY = 0.50 + wave1 + wave2 + wave3;

        // Distance from sun
        final dx = c - sunCol;
        final dy = (r - sunRow) * 1.5;
        final sunDist = sqrt(dx * dx + dy * dy);

        double luminance = 0.0;
        Color dotColor = const Color(0xFFF97316);

        if (v < horizonY) {
          // SKY & SUNSET REGION
          final skyGrad = pow(v / horizonY, 1.3).toDouble();
          luminance = 0.12 + 0.38 * skyGrad;

          if (sunDist < sunR) {
            // Sun Disc Core
            final t = sunDist / sunR;
            luminance = 0.98;
            dotColor = Color.lerp(
              const Color(0xFFFFFDF5), // Pure glowing white-gold
              const Color(0xFFFFD166), // Golden orange edge
              t,
            )!;
          } else {
            // Sun Radial Glow & Halo
            final glow = exp(-sunDist / 18.0) * (0.85 + 0.15 * pulse);
            luminance += glow * 0.65;

            // Sky color transition from dusk violet to apricot/gold
            if (glow > 0.32) {
              dotColor = Color.lerp(
                const Color(0xFFFF9E43),
                const Color(0xFFFFE29A),
                (glow - 0.32) * 1.4,
              )!;
            } else {
              dotColor = Color.lerp(
                const Color(0xFF86497B), // Mauve dusk highlight
                const Color(0xFFF58A4D), // Apricot horizon
                skyGrad,
              )!;
            }
          }

          // Subtle distant mountain silhouette
          final mtnHeight = 0.08 * sin(u * 4.2 + 0.8) + 0.04 * cos(u * 9.5);
          if (v > horizonY - mtnHeight - 0.04) {
            luminance = 0.18;
            dotColor = const Color(0xFF4C274A); // Silhouette ridge
          }
        } else {
          // ROLLING CLOUD SEA REGION
          final depth = (v - horizonY) / (1.0 - horizonY);

          // Billow undulating crests
          final billow = sin(u * 14.0 + drift * 1.1 + depth * 3.5) * 0.18 +
              cos(u * 8.0 - drift * 0.6) * 0.10;

          final illumination = (1.0 - depth) * 0.75 + billow;
          luminance = (0.30 + illumination * 0.65).clamp(0.0, 1.0);

          // Sunset cloud light-catching colors
          if (depth < 0.22) {
            dotColor = const Color(0xFFFFE0A3); // Sunlit glowing crest
          } else if (depth < 0.50) {
            dotColor = const Color(0xFFF57D42); // Warm apricot-tangerine
          } else if (depth < 0.78) {
            dotColor = const Color(0xFFC7462B); // Deep terracotta
          } else {
            dotColor = const Color(0xFF732626); // Deep ember shadow
          }
        }

        // Animated silhouette birds flying across dusk sky
        for (int i = 0; i < 3; i++) {
          final birdC = (((progress * 38 * (i + 1) + (i * 44)) % (cols + 16)) - 8).floor();
          final birdR = 14 + i * 8;
          if ((c == birdC && r == birdR) ||
              (c == birdC + 1 && r == birdR - 1) ||
              (c == birdC - 1 && r == birdR - 1)) {
            luminance = 1.0;
            dotColor = const Color(0xFF2B132C); // Dark silhouette bird
          }
        }

        // Apply Bayer 4x4 ordered dithering
        final bayerVal = _bayer4x4[(r & 3) * 4 + (c & 3)];
        final ditherStep = (luminance * 3.0 + bayerVal).round().clamp(0, 3);

        // Render micro-halftone dither dots (tiny, crisp, high-resolution)
        // Step 0: transparent (shows rich dusk ground)
        // Step 1: micro dot (radius 0.55px)
        // Step 2: medium dot (radius 0.95px)
        // Step 3: dense dot (radius 1.35px)
        if (ditherStep > 0) {
          final radius = ditherStep == 1
              ? 0.55
              : ditherStep == 2
                  ? 0.95
                  : 1.35;

          dotPaint.color = dotColor;
          canvas.drawCircle(Offset(cx, cy), radius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FineDitherCloudSeaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
