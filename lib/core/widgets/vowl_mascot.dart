import 'package:flutter/material.dart';

enum ValtoMood {
  vigilant,
  peeking,
  happy,
  detective,
  sleeping,
}

// Backward compatibility alias
typedef VowlMood = ValtoMood;
typedef VowlMascot = ValtoMascot;

/// Valto — The Simple Blocky Cat Mascot of VAULTED.
/// Inspired directly by Claude's iconic retro blocky mascot (Claw'd).
/// Ultra-minimal geometric grid silhouette: block ears, rectangular body,
/// side arms, 4 pillar legs, and radiant square eyes.
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BlockyValtoPainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFF161615),
          eyeColor: eyeColor ?? const Color(0xFFFBBF24),
          showHat: showHat,
        ),
      ),
    );
  }
}

class _BlockyValtoPainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;
  final bool showHat;

  _BlockyValtoPainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
    required this.showHat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    final fillPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Subtle edge highlight to ensure clean contrast on any dark surface
    final strokePaint = Paint()
      ..color = const Color(0xFF2E2E2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    // -----------------------------------------------------------------
    // PEEKING POSE: Head, 2 Block Ears, and 2 Block Paws resting on rim
    // -----------------------------------------------------------------
    if (mood == ValtoMood.peeking) {
      final u = s / 9.0;
      final x0 = (s - 8.0 * u) / 2;
      final y0 = (s - 6.5 * u) / 2;

      final peekingPath = Path();

      // Left Ear Block
      final leftEar = Rect.fromLTWH(x0 + 1.0 * u, y0 + 0.4 * u, 1.2 * u, 1.6 * u);
      // Right Ear Block
      final rightEar = Rect.fromLTWH(x0 + 5.8 * u, y0 + 0.4 * u, 1.2 * u, 1.6 * u);
      // Head Block
      final head = Rect.fromLTWH(x0 + 1.0 * u, y0 + 1.8 * u, 6.0 * u, 3.4 * u);

      peekingPath.addRect(leftEar);
      peekingPath.addRect(rightEar);
      peekingPath.addRect(head);

      canvas.drawPath(peekingPath, fillPaint);
      canvas.drawPath(peekingPath, strokePaint);

      // Two square paw blocks resting right on the rim
      final pawPaint = Paint()..color = bodyColor;
      final leftPaw = Rect.fromLTWH(x0 + 1.6 * u, y0 + 4.6 * u, 1.5 * u, 1.0 * u);
      final rightPaw = Rect.fromLTWH(x0 + 4.9 * u, y0 + 4.6 * u, 1.5 * u, 1.0 * u);

      canvas.drawRect(leftPaw, pawPaint);
      canvas.drawRect(leftPaw, strokePaint);
      canvas.drawRect(rightPaw, pawPaint);
      canvas.drawRect(rightPaw, strokePaint);

      // Square Eyes
      _drawBlockEyes(canvas, x0 + 2.0 * u, x0 + 5.1 * u, y0 + 2.7 * u, 0.9 * u, eyePaint);
      return;
    }

    // -----------------------------------------------------------------
    // FULL CLAW'D-STYLE BLOCKY CAT SILHOUETTE
    // -----------------------------------------------------------------
    // Proportions directly mapped from Claude's mascot (Claw'd):
    // 9 units wide, 7.5 units tall
    final u = s / 9.6;
    final x0 = (s - 9.0 * u) / 2;
    final y0 = (s - 7.5 * u) / 2;

    final bodyPath = Path();

    // 1. Left Ear Block (top-left of body)
    final leftEar = Rect.fromLTWH(x0 + 1.5 * u, y0, 1.2 * u, 1.5 * u);
    // 2. Right Ear Block (top-right of body)
    final rightEar = Rect.fromLTWH(x0 + 6.3 * u, y0, 1.2 * u, 1.5 * u);
    // 3. Main Rectangular Body
    final mainBody = Rect.fromLTWH(x0 + 1.5 * u, y0 + 1.5 * u, 6.0 * u, 4.0 * u);
    // 4. Left Arm Nub (extending outward horizontally, like Claw'd)
    final leftArm = Rect.fromLTWH(x0, y0 + 3.0 * u, 1.5 * u, 1.5 * u);
    // 5. Right Arm Nub (extending outward horizontally, like Claw'd)
    final rightArm = Rect.fromLTWH(x0 + 7.5 * u, y0 + 3.0 * u, 1.5 * u, 1.5 * u);

    // 6. Four Vertical Pillar Legs (extending down from body, like Claw'd)
    final legY = y0 + 5.5 * u;
    final legH = 2.0 * u;
    final legW = 0.9 * u;
    final leg1 = Rect.fromLTWH(x0 + 1.5 * u, legY, legW, legH); // Outer left
    final leg2 = Rect.fromLTWH(x0 + 3.0 * u, legY, legW, legH); // Inner left
    final leg3 = Rect.fromLTWH(x0 + 5.1 * u, legY, legW, legH); // Inner right
    final leg4 = Rect.fromLTWH(x0 + 6.6 * u, legY, legW, legH); // Outer right

    bodyPath.addRect(leftEar);
    bodyPath.addRect(rightEar);
    bodyPath.addRect(mainBody);
    bodyPath.addRect(leftArm);
    bodyPath.addRect(rightArm);
    bodyPath.addRect(leg1);
    bodyPath.addRect(leg2);
    bodyPath.addRect(leg3);
    bodyPath.addRect(leg4);

    // Draw solid body with crisp outline
    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // -----------------------------------------------------------------
    // EXPRESSIVE SQUARE BLOCK EYES
    // -----------------------------------------------------------------
    final eyeSize = 0.9 * u;
    final eyeY = y0 + 2.5 * u;
    final leftEyeX = x0 + 2.5 * u;
    final rightEyeX = x0 + 5.6 * u;

    _drawBlockEyes(canvas, leftEyeX, rightEyeX, eyeY, eyeSize, eyePaint);
  }

  void _drawBlockEyes(
    Canvas canvas,
    double leftX,
    double rightX,
    double y,
    double size,
    Paint eyePaint,
  ) {
    if (mood == ValtoMood.happy) {
      // Cheerful happy slit eyes (- -)
      final h = size * 0.4;
      canvas.drawRect(Rect.fromLTWH(leftX, y + size * 0.3, size, h), eyePaint);
      canvas.drawRect(Rect.fromLTWH(rightX, y + size * 0.3, size, h), eyePaint);
    } else if (mood == ValtoMood.sleeping) {
      // Peaceful sleeping eyes
      final h = size * 0.3;
      canvas.drawRect(Rect.fromLTWH(leftX, y + size * 0.5, size, h), eyePaint);
      canvas.drawRect(Rect.fromLTWH(rightX, y + size * 0.5, size, h), eyePaint);
    } else if (mood == ValtoMood.detective) {
      // One normal square eye, one curious monocle/squint
      canvas.drawRect(Rect.fromLTWH(leftX, y, size, size), eyePaint);
      // Monocle gold outline around right eye
      final monoclePaint = Paint()
        ..color = const Color(0xFFC0A85C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(
        Rect.fromLTWH(rightX - size * 0.15, y - size * 0.15, size * 1.3, size * 1.3),
        monoclePaint,
      );
      canvas.drawRect(Rect.fromLTWH(rightX, y, size, size), eyePaint);
    } else {
      // Default vigilant / peeking: Pure minimal solid square blocks
      canvas.drawRect(Rect.fromLTWH(leftX, y, size, size), eyePaint);
      canvas.drawRect(Rect.fromLTWH(rightX, y, size, size), eyePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlockyValtoPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.showHat != showHat;
  }
}
