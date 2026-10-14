import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// A rich, living animated sunset scenery header inspired by Oyenza & ascii.rest/cloud-sea.
/// Features a drifting sea of golden sunset clouds, glowing sun, flapping birds, and Vowl peeking over the omnibar.
class ScenicCloudSeaHeader extends StatefulWidget {
  final TextEditingController promptController;
  final FocusNode promptFocus;
  final bool isAiProcessing;
  final VowlMood vowlMood;
  final VoidCallback onSubmit;

  const ScenicCloudSeaHeader({
    super.key,
    required this.promptController,
    required this.promptFocus,
    required this.isAiProcessing,
    required this.vowlMood,
    required this.onSubmit,
  });

  @override
  State<ScenicCloudSeaHeader> createState() => _ScenicCloudSeaHeaderState();
}

class _ScenicCloudSeaHeaderState extends State<ScenicCloudSeaHeader>
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
            // 1. LIVING ANIMATED SCENERY CANVAS (Cloud Sea, Sun, Horizon & Birds)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CloudSeaSceneryPainter(
                      progress: _animController.value,
                    ),
                  );
                },
              ),
            ),

            // 2. SCENIC CONTENT OVERLAY
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
                      color: Colors.white.withValues(alpha: 0.85),
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
                      color: Colors.white.withValues(alpha: 0.92),
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
                                        color: Colors.white.withValues(alpha: 0.75),
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

/// Custom animated painter for the cloud sea scenery
class _CloudSeaSceneryPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 continuously looping

  _CloudSeaSceneryPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. SKY GRADIENT: Radiant Dusk & Sunset Palette
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF5A3D68), // Twilight violet / dusk
          Color(0xFF8A516E), // Mauve
          Color(0xFFCE6753), // Deep terracotta rose
          Color(0xFFE98858), // Warm apricot
          Color(0xFFFBB362), // Radiant sunset gold
        ],
        stops: [0.0, 0.22, 0.50, 0.75, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 2. SINKING SUN ON THE HORIZON
    final sunX = w * 0.72;
    final sunY = h * 0.44;
    final sunRadius = 26.0;

    // Sun outer atmospheric glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFECC7).withValues(alpha: 0.65),
          const Color(0xFFF9B365).withValues(alpha: 0.35),
          const Color(0xFFE57D61).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius * 4.2));
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 4.2, glowPaint);

    // Sun Core Disc
    final sunCorePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.white,
          Color(0xFFFFF3D6),
          Color(0xFFFFC078),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius));
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunCorePaint);

    // 3. DISTANT SILHOUETTED MOUNTAINS & HORIZON SKYLINE (Mount Merapi & Yogyakarta Tower)
    _drawDistantSkyline(canvas, w, h);

    // 4. PARALLAX DRIFTING CLOUD SEA BILLOWS (Multiple Layers)
    // Layer 1: Distant soft misty clouds (slowest)
    _drawCloudSeaLayer(
      canvas: canvas,
      width: w,
      height: h,
      baseY: h * 0.58,
      amplitude: 14,
      drift: progress * 0.25,
      frequency: 3.5,
      cloudColor: const Color(0xFFF6A463).withValues(alpha: 0.55),
      highlightColor: const Color(0xFFFFECC7).withValues(alpha: 0.60),
    );

    // Layer 2: Mid-ground billowy cloud sea
    _drawCloudSeaLayer(
      canvas: canvas,
      width: w,
      height: h,
      baseY: h * 0.70,
      amplitude: 18,
      drift: (progress * 0.45) % 1.0,
      frequency: 4.2,
      cloudColor: const Color(0xFFE27C59).withValues(alpha: 0.75),
      highlightColor: const Color(0xFFFFD99E).withValues(alpha: 0.70),
    );

    // Layer 3: Foreground lush sunset canopy / trees
    _drawForegroundCanopy(canvas, w, h);

    // 5. ANIMATED SILHOUETTE BIRDS CROSSING DUSK SKY
    _drawFlappingBirds(canvas, w, h, progress);
  }

  void _drawDistantSkyline(Canvas canvas, double w, double h) {
    final skylinePath = Path();
    final skylinePaint = Paint()..color = const Color(0xFF6B425A).withValues(alpha: 0.38);

    skylinePath.moveTo(0, h * 0.65);
    // Smooth rolling hills & mountain peak
    skylinePath.lineTo(w * 0.18, h * 0.62);
    skylinePath.lineTo(w * 0.32, h * 0.52); // Mountain ridge peak
    skylinePath.lineTo(w * 0.44, h * 0.64);
    skylinePath.lineTo(w * 0.58, h * 0.61);
    // Distant needle / tower (like Monas or temple spire)
    skylinePath.lineTo(w * 0.78, h * 0.61);
    skylinePath.lineTo(w * 0.784, h * 0.48); // Spire top
    skylinePath.lineTo(w * 0.788, h * 0.61);
    skylinePath.lineTo(w, h * 0.63);
    skylinePath.lineTo(w, h);
    skylinePath.lineTo(0, h);
    skylinePath.close();

    canvas.drawPath(skylinePath, skylinePaint);
  }

  void _drawCloudSeaLayer({
    required Canvas canvas,
    required double width,
    required double height,
    required double baseY,
    required double amplitude,
    required double drift,
    required double frequency,
    required Color cloudColor,
    required Color highlightColor,
  }) {
    final path = Path();
    path.moveTo(0, height);
    path.lineTo(0, baseY);

    const int steps = 48;
    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * width;
      final normalizedX = i / steps;
      // Rolling wave function with drift
      final angle = (normalizedX * frequency * 2 * pi) + (drift * 2 * pi);
      final yOffset = sin(angle) * amplitude + cos(angle * 1.8) * (amplitude * 0.4);
      final y = baseY + yOffset;
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.close();

    final bodyPaint = Paint()..color = cloudColor;
    canvas.drawPath(path, bodyPaint);

    // Glowing rim along cloud tops
    final rimPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, rimPaint);
  }

  void _drawForegroundCanopy(Canvas canvas, double w, double h) {
    // Dense silhouetted palm tree / forest horizon at the bottom edge
    final canopyPath = Path();
    canopyPath.moveTo(0, h);
    canopyPath.lineTo(0, h * 0.88);

    const int clusters = 32;
    for (int i = 0; i <= clusters; i++) {
      final x = (i / clusters) * w;
      final y = h * 0.84 + sin(i * 1.5) * 6 + cos(i * 3.1) * 4;
      canopyPath.lineTo(x, y);
    }

    canopyPath.lineTo(w, h);
    canopyPath.close();

    final canopyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3B2533).withValues(alpha: 0.65),
          const Color(0xFF221620).withValues(alpha: 0.85),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.80, w, h * 0.20));

    canvas.drawPath(canopyPath, canopyPaint);
  }

  void _drawFlappingBirds(Canvas canvas, double w, double h, double t) {
    // 3 Birds flying gracefully across the sunset sky at different speeds & altitudes
    final birdPaint = Paint()
      ..color = const Color(0xFF2C1929).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final speed = 0.18 + (i * 0.05);
      final xPos = ((t * speed * w * 2.2) + (i * w * 0.38)) % (w + 60) - 30;
      final yPos = h * (0.18 + (i * 0.07)) + sin((t * 2 * pi) + i) * 4;

      // Wing flap animation cycle
      final flapAngle = sin((t * 24) + (i * 3.2)) * 0.38;

      final birdPath = Path();
      // Left wing
      birdPath.moveTo(xPos - 8, yPos - 5 * flapAngle);
      birdPath.quadraticBezierTo(xPos - 4, yPos - 8 - 4 * flapAngle, xPos, yPos);
      // Right wing
      birdPath.quadraticBezierTo(xPos + 4, yPos - 8 - 4 * flapAngle, xPos + 8, yPos - 5 * flapAngle);

      canvas.drawPath(birdPath, birdPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudSeaSceneryPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
