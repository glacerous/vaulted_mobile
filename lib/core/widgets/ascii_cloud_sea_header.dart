import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// Alias to maintain backward compatibility with previous imports
typedef AsciiCloudSeaHeader = DitheredCloudSeaHeader;

/// Available authentic dithered scenes
enum DitherScene { alpineDawn, cloudSea }

/// A warm, friendly, casual luxury header featuring the authentic, breathtaking
/// dithered scenery from ascii.rest/alpine-dawn (snow peaks & misty lake) and cloud-sea.
/// Hardware-accelerated, zero-lag pre-cached frame playback that works on all browsers and devices.
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
  DitherScene _scene = DitherScene.alpineDawn;

  static const int _alpineFrameCount = 36;
  static const int _cloudSeaFrameCount = 30;

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
    // Pre-cache all alpine dawn frames into Flutter memory
    for (int i = 0; i < _alpineFrameCount; i++) {
      precacheImage(
        AssetImage('assets/images/alpine_dawn_frames/f_$i.png'),
        context,
      );
    }
    // Also pre-cache cloud sea frames
    for (int i = 0; i < _cloudSeaFrameCount; i++) {
      precacheImage(
        AssetImage('assets/images/cloud_sea_frames/f_$i.png'),
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

    final isAlpine = _scene == DitherScene.alpineDawn;
    final frameCount = isAlpine ? _alpineFrameCount : _cloudSeaFrameCount;
    final folder = isAlpine ? 'alpine_dawn_frames' : 'cloud_sea_frames';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isAlpine
                ? const Color(0xFF3B487A).withValues(alpha: 0.35)
                : const Color(0xFFF97316).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. GUARANTEED ZERO-LAG 60FPS DITHERED ANIMATION (Pre-cached frame player)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final frameIndex = (_animController.value * frameCount).floor() % frameCount;
                  return Image.asset(
                    'assets/images/$folder/f_$frameIndex.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                  );
                },
              ),
            ),

            // 2. SOFT ATMOSPHERIC GRADIENT (Ensures text & omnibar remain razor crisp)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.40),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. WARM CASUAL CONTENT OVERLAY (Matching "Illust" option exactly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Date line + Scene Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: VaultTypography.mono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),

                      // Discreet Scene Toggle Pill
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildSceneTab('🏔️ ALPINE', DitherScene.alpineDawn),
                            _buildSceneTab('🌅 CLOUDS', DitherScene.cloudSea),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

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

                  // 4. VOWL MASCOT PEEKING + FROSTED GLASS OMNIBAR
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

  Widget _buildSceneTab(String title, DitherScene scene) {
    final isSel = _scene == scene;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _scene = scene);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? Colors.white.withValues(alpha: 0.28) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: VaultTypography.mono(
            fontSize: 9.5,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}
