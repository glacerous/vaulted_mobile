import 'package:flutter/material.dart';

enum ValtoMood {
  vigilant,  // Classic seated vault guardian
  playful,   // Waving greeting paw
  sleeping,  // Cozy sleeping cat loaf
  happy,     // Victorious celebrating paw
  detective, // Cocked ear & golden monocle
  peeking,   // Peeking pose
}

// Backward compatibility alias
typedef VowlMood = ValtoMood;
typedef VowlMascot = ValtoMascot;

/// Valto — The Signature Black Cat Mascot of VAULTED.
/// Clean, simple, and reliable: renders directly from pixel-perfect PNG assets.
class ValtoMascot extends StatelessWidget {
  final double size;
  final ValtoMood mood;
  final Color? color;
  final Color? eyeColor;
  final bool showHat;

  const ValtoMascot({
    super.key,
    this.size = 56,
    this.mood = ValtoMood.vigilant,
    this.color,
    this.eyeColor,
    this.showHat = false,
  });

  String get _assetPath {
    switch (mood) {
      case ValtoMood.sleeping:
        return 'assets/images/valto_sleeping.png';
      case ValtoMood.happy:
        return 'assets/images/valto_happy.png';
      case ValtoMood.detective:
        return 'assets/images/valto_detective.png';
      case ValtoMood.playful:
      case ValtoMood.peeking:
      case ValtoMood.vigilant:
        return 'assets/images/valto_vigilant.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // Pixel-perfect sharpness without blur
    );
  }
}
