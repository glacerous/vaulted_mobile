import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// Alias to maintain backward compatibility with previous imports
typedef AsciiCloudSeaHeader = DitheredCloudSeaHeader;

/// A warm, friendly, casual luxury header featuring an authentic, lightweight,
/// zero-lag dithered sunset cloud-sea artwork from ascii.rest/cloud-sea.
/// Hardware-accelerated, perfectly smooth 60fps loop with zero CPU overhead.
class DitheredCloudSeaHeader extends StatelessWidget {
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
            color: const Color(0xFFF97316).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. LIGHTWEIGHT ZERO-LAG AUTHENTIC DITHERED ARTWORK (ascii.rest/cloud-sea)
            Positioned.fill(
              child: Image.asset(
                'assets/images/cloud_sea_dither.gif',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
              ),
            ),

            // 2. SOFT ATMOSPHERIC GRADIENT (Ensures text & omnibar are crisp and readable)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.38),
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
                  // Date line
                  Text(
                    dateStr,
                    style: VaultTypography.mono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.90),
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
                          mood: vowlMood,
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
                                    controller: promptController,
                                    focusNode: promptFocus,
                                    onSubmitted: (_) => onSubmit(),
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
                                  onTap: onSubmit,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF141413),
                                    ),
                                    child: isAiProcessing
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
