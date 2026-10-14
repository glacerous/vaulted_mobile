import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// An authentic, living animated ASCII Cloud-Sea header inspired by ascii.rest/cloud-sea & ascii-magic.
/// Renders an animated matrix of ASCII characters with sunset colors, drifting cloud sea waves, glowing sun, and ASCII birds.
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEE d MMM · HH:mm').format(now).toUpperCase();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131518), // Pure dark terminal chassis
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C2F36), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. ANIMATED ASCII CLOUD-SEA MATRIX PAINTER
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AsciiCloudSeaPainter(
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),

            // 2. RETRO TERMINAL HEADER INFO & PROMPT OVERLAY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top ASCII Status Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ASCII.REST // CLOUD-SEA',
                              style: VaultTypography.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: const Color(0xFFFDBA74),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateStr,
                        style: VaultTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title in bold ASCII vibe
                  Text(
                    'GOOD AFTERNOON.',
                    style: VaultTypography.mono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Say "coffee 25k" or "macbook 1999 usd".',
                    style: VaultTypography.mono(
                      fontSize: 11,
                      color: const Color(0xFFFED7AA),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. ASCII VOWL MASCOT PEEKING + RETRO MONOSPACE OMNIBAR
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ASCII Vowl Owl sitting on top
                      Positioned(
                        top: -30,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2127),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            '/\\_/\\ \n((@v@))\n():::()',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: Color(0xFFFDBA74),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // ASCII Styled Terminal Capsule
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131518).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF97316).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Row(
                          children: [
                            Text(
                              '>_',
                              style: VaultTypography.mono(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: widget.promptController,
                                focusNode: widget.promptFocus,
                                onSubmitted: (_) => widget.onSubmit(),
                                style: VaultTypography.mono(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'prompt vowl ascii...',
                                  hintStyle: VaultTypography.mono(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onSubmit,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: widget.isAiProcessing
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.terminal_rounded,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                              ),
                            ),
                          ],
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

/// Custom animated painter that produces the living ASCII Cloud-Sea matrix
class _AsciiCloudSeaPainter extends CustomPainter {
  final double progress;

  _AsciiCloudSeaPainter({required this.progress});

  // ASCII Halftone character density ramp:
  // " " < "·" < ":" < "-" < "=" < "+" < "*" < "%" < "#" < "@"
  static const List<String> _ramp = [' ', '·', ':', '-', '=', '+', '*', '%', '#', '@'];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid resolution: 32 columns x 14 rows of ASCII characters
    const cols = 34;
    const rows = 14;
    final cellW = w / cols;
    final cellH = h / rows;

    final sunCol = (cols * 0.72).floor();
    final sunRow = (rows * 0.42).floor();

    final time = progress * 2 * pi;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * cellW + cellW * 0.5;
        final y = r * cellH + cellH * 0.5;

        // Normalized positions
        final u = c / cols;
        final v = r / rows;

        // Distance from sun
        final dCol = c - sunCol;
        final dRow = (r - sunRow) * 1.6;
        final sunDist = sqrt(dCol * dCol + dRow * dRow);

        // Cloud Sea Wave function (undulating billow layers drifting left to right)
        final wave1 = sin(u * 6.5 + time * 1.8) * 0.12;
        final wave2 = cos(u * 12.0 - time * 0.9) * 0.08;
        final horizonY = 0.52 + wave1 + wave2;

        double luminance = 0.0;
        Color charColor = const Color(0xFF64748B);

        if (v < horizonY) {
          // SKY REGION: Dusk charcoal/purple fading to amber at horizon
          final skyGrad = (v / horizonY);
          luminance = 0.15 + (skyGrad * 0.35);

          // Sun Core & Bloom
          if (sunDist < 1.8) {
            luminance = 0.95;
            charColor = const Color(0xFFFFFFFF);
          } else if (sunDist < 4.5) {
            final bloom = 1.0 - (sunDist / 4.5);
            luminance += bloom * 0.55;
            charColor = Color.lerp(
              const Color(0xFFFBBF24),
              const Color(0xFFFB923C),
              sunDist / 4.5,
            )!;
          } else {
            // Twilight gradient
            charColor = Color.lerp(
              const Color(0xFF6B7280),
              const Color(0xFFF97316),
              pow(skyGrad, 1.8).toDouble(),
            )!;
          }

          // Twinkling stars in high sky
          if (r < 3 && ((c * 7 + r * 13) % 11 == 0)) {
            final twinkle = sin(time * 3 + c);
            if (twinkle > 0.4) {
              luminance = 0.85;
              charColor = const Color(0xFFE2E8F0);
            }
          }
        } else {
          // CLOUD SEA REGION: Burning golden rim along wave tops, deep amber/ember below
          final depth = (v - horizonY) / (1.0 - horizonY);
          // Wave crest gets high sunlight
          final crest = 1.0 - depth;
          luminance = 0.35 + (crest * 0.55) + sin(u * 14.0 + time * 2.2 + r) * 0.15;

          // Color ramp from burning white-gold to orange to deep ember
          if (depth < 0.25) {
            charColor = const Color(0xFFFEF08A); // Burning rim
          } else if (depth < 0.65) {
            charColor = const Color(0xFFF97316); // Tangerine cloud face
          } else {
            charColor = const Color(0xFFC2410C); // Deep rust/ember shadow
          }
        }

        // Animated ASCII birds crossing the sky
        for (int i = 0; i < 2; i++) {
          final birdC = (((progress * 18 * (i + 1) + (i * 14)) % (cols + 6)) - 3).floor();
          final birdR = 3 + i * 2;
          if (c == birdC && r == birdR) {
            luminance = 0.98;
            charColor = const Color(0xFFFFFFFF);
          }
        }

        // Clamp luminance to ramp index
        luminance = luminance.clamp(0.0, 1.0);
        final charIndex = (luminance * (_ramp.length - 1)).round();
        final char = _ramp[charIndex];

        if (char != ' ') {
          final textSpan = TextSpan(
            text: char,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.5,
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
            Offset(x - textPainter.width * 0.5, y - textPainter.height * 0.5),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiCloudSeaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
