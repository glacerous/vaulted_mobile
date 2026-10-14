import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// Scene mode for the ASCII Retro Dither Canvas
enum AsciiScene { cloudSea, vowlOwl }

/// An authentic, high-density dithered ASCII art header inspired by ascii.rest/cloud-sea & ascii.rest/owl.
/// Uses true 4x4 Bayer ordered dithering (DOTS: " ", "·", "•", "●") for the cloud sea,
/// and handcrafted authentic ASCII character art for Vowl the Guardian Owl.
class AsciiCloudSeaHeader extends StatefulWidget {
  final TextEditingController promptController;
  final FocusNode promptFocus;
  final bool isAiProcessing;
  final VowlMood vowlMood;
  final VoidCallback onSubmit;

  const AsciiCloudSeaHeader({
    super.key,
    required this.promptController,
    required this.promptFocus,
    required this.isAiProcessing,
    required this.vowlMood,
    required this.onSubmit,
  });

  @override
  State<AsciiCloudSeaHeader> createState() => _AsciiCloudSeaHeaderState();
}

class _AsciiCloudSeaHeaderState extends State<AsciiCloudSeaHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  AsciiScene _selectedScene = AsciiScene.cloudSea;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyQuickPrompt(String prompt) {
    HapticFeedback.selectionClick();
    widget.promptController.text = prompt;
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss').format(now);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0F), // Authentic ascii.rest ground
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF26262B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP RETRO TERMINAL TITLE BAR & SCENE SWITCHER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141518),
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF26262B), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Terminal status indicator
                Row(
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E), // Terminal green dot
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedScene == AsciiScene.cloudSea
                          ? 'ASCII.REST // CLOUD-SEA'
                          : 'ASCII.REST // VOWL-OWL',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: const Color(0xFFE4E4E7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· 70x28 DITHER',
                      style: VaultTypography.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),

                // Scene Selector Pills
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A0B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF27272A), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      _buildSceneButton('SUNSET', AsciiScene.cloudSea),
                      _buildSceneButton('OWL', AsciiScene.vowlOwl),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. DEDICATED DITHERED ASCII ART VIEWPORT (UNOBSTRUCTED HERO CANVAS)
          Container(
            height: 185,
            width: double.infinity,
            color: const Color(0xFF0E0E0F),
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _selectedScene == AsciiScene.cloudSea
                        ? _AsciiDitherCloudSeaPainter(progress: _controller.value)
                        : _AsciiOwlPainter(progress: _controller.value),
                  );
                },
              ),
            ),
          ),

          // 3. TELEMETRY STRIP (Clean separation from prompt)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF121316),
              border: Border(
                top: BorderSide(color: Color(0xFF222328), width: 1.0),
                bottom: BorderSide(color: Color(0xFF222328), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VALTO SECURE VAULT ENGINE // 15 FPS // BAYER 4x4',
                  style: VaultTypography.mono(
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                    color: const Color(0xFF71717A),
                  ),
                ),
                Text(
                  timeStr,
                  style: VaultTypography.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),

          // 4. RETRO COMMAND PROMPT CAPSULE (In the Thumb Zone, Cleanly Accessible)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141518),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2C2F36),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Row(
                    children: [
                      Text(
                        '>_',
                        style: VaultTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: widget.promptController,
                          focusNode: widget.promptFocus,
                          onSubmitted: (_) => widget.onSubmit(),
                          style: VaultTypography.mono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF4F4F5),
                          ),
                          decoration: InputDecoration(
                            hintText: 'prompt valto (e.g. "coffee 25k" or "100 usd")...',
                            hintStyle: VaultTypography.mono(
                              fontSize: 11.5,
                              color: const Color(0xFF71717A),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSubmit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: widget.isAiProcessing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'RUN',
                                      style: VaultTypography.mono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_return_rounded,
                                      size: 13,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Quick Prompt Chips (One-tap test)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickChip('☕ Kopi 25k BCA', 'kopi 25k bca'),
                      _buildQuickChip('💵 50 USD to IDR', '50 usd to idr'),
                      _buildQuickChip('🎮 Steam Deck 500 USD', 'steam deck 500 usd'),
                      _buildQuickChip('🛡️ Warranty 24m', 'beli macbook pro 2000 usd garansi 24 bln'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneButton(String title, AsciiScene scene) {
    final isSelected = _selectedScene == scene;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedScene = scene);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: VaultTypography.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String command) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _applyQuickPrompt(command),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27272A), width: 0.8),
          ),
          child: Text(
            label,
            style: VaultTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }
}

/// Authentic Bayer 4x4 Ordered Dither Cloud Sea Painter.
/// Implements the exact halftone dot density ramp and palette from ascii.rest/cloud-sea.
class _AsciiDitherCloudSeaPainter extends CustomPainter {
  final double progress;

  _AsciiDitherCloudSeaPainter({required this.progress});

  // 4x4 Bayer Dithering Matrix normalized
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

    // High density grid matching ascii.rest aspect
    const cols = 70;
    const rows = 28;
    final cellW = w / cols;
    final cellH = h / rows;

    // Sinking sun at dusk (col ~50, row ~13)
    final sunCol = cols * 0.73;
    final sunRow = rows * 0.44;
    final pulse = sin(progress * 2 * pi * 4);
    final sunR = 3.8 + 0.3 * pulse;

    final drift = progress * 2 * pi;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * cellW + cellW * 0.5;
        final cy = r * cellH + cellH * 0.5;

        final u = c / cols;
        final v = r / rows;

        // Multi-octave wave profiles for the rolling cloud sea
        final wave1 = sin(u * 8.0 + drift * 1.2) * 0.055;
        final wave2 = cos(u * 14.0 - drift * 0.7) * 0.035;
        final wave3 = sin(u * 22.0 + drift * 2.0) * 0.015;
        final horizonY = 0.46 + wave1 + wave2 + wave3;

        // Distance from sun
        final dx = c - sunCol;
        final dy = (r - sunRow) * 1.5;
        final sunDist = sqrt(dx * dx + dy * dy);

        double level = 0.0;
        Color col = const Color(0xFF18181B);

        if (v < horizonY) {
          // SKY REGION: charcoal dusk transitioning to warm orange haze
          final skyGradient = pow(v / horizonY, 1.4).toDouble();
          level = 0.05 + 0.35 * skyGradient;

          // Sun Core and Ambient Glow
          if (sunDist < sunR) {
            // Sun disc: hot white/gold center
            final t = sunDist / sunR;
            level = 0.95;
            col = Color.lerp(
              const Color(0xFFFFF6E6), // White-gold core
              const Color(0xFFFBBF24), // Golden orange edge
              t,
            )!;
          } else {
            // Sun twilight glow
            final glow = exp(-sunDist / 7.5) * (0.85 + 0.15 * pulse);
            level += glow * 0.65;

            // Horizon color gradient (charcoal -> deep amber -> bright tangerine near sun)
            final nearSun = exp(-dx.abs() / 14.0);
            if (glow > 0.3) {
              col = Color.lerp(
                const Color(0xFFF97316),
                const Color(0xFFFDE047),
                (glow - 0.3) * 1.4,
              )!;
            } else {
              col = Color.lerp(
                const Color(0xFF27272A), // Dusk grey
                const Color(0xFF9A3412), // Amber horizon
                skyGradient * (0.3 + 0.7 * nearSun),
              )!;
            }
          }

          // Twinkling stars in upper sky
          if (r < 6 && ((c * 17 + r * 31) % 23 == 0)) {
            final starTwinkle = sin(drift * 3 + c);
            if (starTwinkle > 0.4) {
              level = 0.75;
              col = const Color(0xFFE4E4E7);
            }
          }

          // Animated flying dusk birds
          for (int i = 0; i < 3; i++) {
            final birdC = (((progress * 24 * (i + 1) + (i * 22)) % (cols + 10)) - 5).floor();
            final birdR = 4 + i * 2;
            if (c == birdC && r == birdR) {
              level = 1.0;
              col = const Color(0xFFFFFFFF);
            } else if (c == birdC + 1 && r == birdR - 1) {
              level = 0.75;
              col = const Color(0xFFFDE047);
            }
          }
        } else {
          // CLOUD SEA REGION: rolling cloud billows catching the low orange sun
          final depth = (v - horizonY) / (1.0 - horizonY);
          final billow = sin(u * 16.0 + drift * 1.8 + depth * 4.0) * 0.18 +
              cos(u * 8.0 - drift * 0.9) * 0.12;

          // Billow crests catch high light
          final illumination = (1.0 - depth) * 0.7 + billow;
          level = (0.28 + illumination * 0.65).clamp(0.0, 1.0);

          // Color ramp based on light catching:
          // Top illuminated crests = bright tangerine & warm peach
          // Deep valleys = deep charcoal & ember
          if (depth < 0.2) {
            col = const Color(0xFFFED7AA); // Sunlit rim peach
          } else if (depth < 0.45) {
            col = const Color(0xFFF97316); // Tangerine orange
          } else if (depth < 0.75) {
            col = const Color(0xFFC2410C); // Deep rust
          } else {
            col = const Color(0xFF43302A); // Ember shadow
          }
        }

        // Apply Bayer 4x4 ordered dithering
        final bayerVal = _bayer4x4[(r & 3) * 4 + (c & 3)];
        final ditherStep = (level * 3.0 + bayerVal).round().clamp(0, 3);

        // Render authentic halftone dot sizes
        // step 0: empty space
        // step 1: light dot (r = 0.8)
        // step 2: medium bullet (r = 1.6)
        // step 3: solid dot (r = 2.4)
        if (ditherStep > 0) {
          final radius = ditherStep == 1
              ? 0.75
              : ditherStep == 2
                  ? 1.55
                  : 2.35;

          dotPaint.color = col;
          canvas.drawCircle(Offset(cx, cy), radius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiDitherCloudSeaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Authentic handcrafted ASCII Owl Painter inspired by ascii.rest/owl.
/// Renders Vowl the Guardian Owl perched on a branch at night with blinking dial eyes,
/// plumage shading, moon, and twinkling stars.
class _AsciiOwlPainter extends CustomPainter {
  final double progress;

  _AsciiOwlPainter({required this.progress});

  // Authentic ASCII Owl Art Matrix from ascii.rest/owl
  // Eyes at row 6: (@@) or (--) when blinking!
  static const List<String> _owlLines = [
    "      +                               .      ",
    "   .       /\\                 /\\             ",
    "          /  \\_.-------._/  \\            ",
    "         /  ` ' ` ' ` ' ` ' ` '  \\      +    ",
    "        |  ' .----.  `  .----. '  |          ",
    "  .     | ' / .--. \\   / .--. \\ ` |          ",
    "        |  '| {EYE} |   | {EYE} |'  |  .       ",
    "        | ' \\ `--' / V \\ `--' / ` |          ",
    "        |  ' `----'     `----' '  |          ",
    "        (\\ ' ` ' ` ' ` ' ` ' ` ' /)          ",
    "       /  \\. v   v   v   v   v ./  \\         ",
    "      /  ( (\\  v   v   v   v  /) )  \\   .    ",
    "     |  ( ( (|   v   v   v   |) ) )  |       ",
    "     |  ( ( ( \\  v  v  v  v / ) ) )  |       ",
    "     |  \\\\\\\\\\  \\  v  v  v  /  /////  |       ",
    "     |  \\\\\\\\ \\  \\   v  v  /  / ////  |       ",
    "      \\  \\\\\\\\ \\  \\ v v v /  / ////  /        ",
    "       \\  \\\\\\\\ \\  \\ v v /  / ////  /         ",
    "        `. \\\\\\\\ \\  `. .'  / //// .'          ",
    "          `-.\\\\\\ \\_______/ ///.-'            ",
    " =-==-===-==-=mm=====-=-===mm-==-=-==-=-=)   ",
    "  `-.__.-'~~`--.__.||||| `--.__.-'~`-.__/    ",
    "                   '''''                     ",
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Owl blinking state: blinks every 4 seconds
    final blinkCycle = (progress * 12) % 1.0;
    final isBlinking = blinkCycle > 0.88;
    final eyeString = isBlinking ? "(--)" : "(@@)";

    // Render moon in background
    final moonCenter = Offset(w * 0.82, h * 0.28);
    final moonPaint = Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.15);
    canvas.drawCircle(moonCenter, 22, moonPaint);
    moonPaint.color = const Color(0xFFFEF08A).withValues(alpha: 0.9);
    canvas.drawCircle(moonCenter, 14, moonPaint);
    // Crescent shadow
    final shadowPaint = Paint()..color = const Color(0xFF0E0E0F);
    canvas.drawCircle(Offset(moonCenter.dx - 6, moonCenter.dy - 3), 13, shadowPaint);

    // Compute cell dimensions to center the owl
    final rows = _owlLines.length;
    const cols = 45;
    final cellW = (w / cols).clamp(5.5, 9.5);
    final cellH = (h / (rows + 1)).clamp(6.5, 9.0);

    final startX = (w - (cols * cellW)) * 0.5;
    final startY = (h - (rows * cellH)) * 0.5;

    for (int r = 0; r < rows; r++) {
      String line = _owlLines[r];
      // Inject animated blinking eyes
      line = line.replaceAll("{EYE}", eyeString);

      for (int c = 0; c < line.length; c++) {
        final char = line[c];
        if (char == ' ') continue;

        final x = startX + c * cellW;
        final y = startY + r * cellH;

        Color charColor = const Color(0xFFD4D4D8); // Default crisp ASCII zinc

        // Eye highlights
        if (line.contains(eyeString) && (char == '@' || char == '-')) {
          charColor = const Color(0xFFF59E0B); // Amber dial-lock eyes!
        } else if (char == 'V') {
          charColor = const Color(0xFFF97316); // Golden beak
        } else if (char == '+' || char == '.') {
          // Twinkling stars
          final twinkle = sin(progress * 2 * pi * 5 + c * 3);
          charColor = twinkle > 0 ? const Color(0xFFFDE047) : const Color(0xFF71717A);
        } else if (r >= 20) {
          // Branch
          charColor = const Color(0xFF854D0E); // Rich cedar bark
        } else if (char == 'v') {
          // Feather flecks
          charColor = const Color(0xFFA1A1AA);
        }

        final textSpan = TextSpan(
          text: char,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: charColor,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(x, y),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiOwlPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
