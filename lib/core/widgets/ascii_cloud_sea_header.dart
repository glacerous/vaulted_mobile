import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/typography.dart';
import 'valto_mascot.dart';

/// Permanent, signature Alpine Dawn header
typedef AsciiCloudSeaHeader = AlpineDawnHeader;
typedef DitheredCloudSeaHeader = AlpineDawnHeader;

/// A warm, friendly, casual luxury header featuring the authentic, breathtaking
/// dithered scenery from ascii.rest/alpine-dawn (snow peaks & misty mountain lake).
/// Hardware-accelerated, zero-lag pre-cached frame playback that runs smoothly on all platforms.
class AlpineDawnHeader extends StatefulWidget {
  final TextEditingController promptController;
  final FocusNode promptFocus;
  final bool isAiProcessing;
  final ValtoMood valtoMood;
  final VoidCallback onSubmit;

  const AlpineDawnHeader({
    super.key,
    required this.promptController,
    required this.promptFocus,
    required this.isAiProcessing,
    ValtoMood? valtoMood,
    ValtoMood? vowlMood,
    required this.onSubmit,
  }) : valtoMood = valtoMood ?? vowlMood ?? ValtoMood.peeking;

  @override
  State<AlpineDawnHeader> createState() => _AlpineDawnHeaderState();
}

class _AlpineDawnHeaderState extends State<AlpineDawnHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  static const int _frameCount = 36;

  @override
  void initState() {
    super.initState();
    // Smooth, relaxing 2.8 second cycle
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache all alpine dawn frames into Flutter memory for instant, zero-lag frame swapping
    for (int i = 0; i < _frameCount; i++) {
      precacheImage(
        AssetImage('assets/images/alpine_dawn_frames/f_$i.png'),
        context,
      );
    }
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
            color: const Color(0xFF3B487A).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. GUARANTEED ZERO-LAG 60FPS DITHERED ANIMATION (Alpine Dawn)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final frameIndex = (_animController.value * _frameCount).floor() % _frameCount;
                  return Image.asset(
                    'assets/images/alpine_dawn_frames/f_$frameIndex.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                  );
                },
              ),
            ),

            // 2. DELICATE ATMOSPHERIC SCRIM (Keeps dither art vibrant & visible, lets typography pop)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.32),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. WARM CASUAL CONTENT OVERLAY (Clean, focused, no distracting pills)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean Date line in warm white / subtle gold glow
                  Text(
                    dateStr.toUpperCase(),
                    style: VaultTypography.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Giant Bold Greeting
                  Text(
                    _getGreeting(),
                    style: VaultTypography.sans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.85),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Conversational Prompt Subtitle
                  Text(
                    'Say "coffee 25k" or snap a receipt. It takes two seconds.',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 38),

                  // 4. FROSTED GLASS OMNIBAR

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
                                      hintText: 'Ask Valto anything...',
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
            ),
          ],
        ),
      ),
    );
  }
}
