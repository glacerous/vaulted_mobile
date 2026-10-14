import 'dart:math';
import 'package:flutter/material.dart';

enum VowlMood {
  vigilant,
  peeking,
  happy,
  detective,
  sleeping,
}

// Keep ValtoMood as alias for backward compatibility
typedef ValtoMood = VowlMood;

/// Vowl — The Guardian Owl of VAULTED.
/// An ultra-minimal, iconic, geometric vector mascot with 24/7 vigilant vault eyes.
class VowlMascot extends StatelessWidget {
  final double size;
  final VowlMood mood;
  final bool showHat;

  const VowlMascot({
    super.key,
    this.size = 56,
    this.mood = VowlMood.vigilant,
    this.showHat = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VowlPainter(mood: mood, showHat: showHat),
      ),
    );
  }
}

// Alias for seamless backward compatibility
typedef ValtoMascot = VowlMascot;

class _VowlPainter extends CustomPainter {
  final VowlMood mood;
  final bool showHat;

  _VowlPainter({required this.mood, required this.showHat});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Sleek Luxury Guardian Owl (Warm Charcoal & Gold Vault Dials)
    final bodyPaint = Paint()..color = const Color(0xFF2C2A28); // Deep espresso charcoal
    final innerFacePaint = Paint()..color = const Color(0xFFF7F5EE); // Porcelain warm cream
    final goldRingPaint = Paint()..color = const Color(0xFFD97706); // Warm golden vault lock ring
    final pupilPaint = Paint()..color = const Color(0xFF141413); // Deep pupil
    final catchlightPaint = Paint()..color = Colors.white;
    final beakPaint = Paint()..color = const Color(0xFFE58A2B); // Amber beak
    final monoclePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045;

    final cx = w * 0.5;
    final cy = h * 0.52;

    if (mood == VowlMood.peeking) {
      // Peeking over border: ears + big eyes + top of head
      final peekPath = Path();
      // Left ear tuft
      peekPath.moveTo(w * 0.18, h * 0.95);
      peekPath.lineTo(w * 0.14, h * 0.36);
      peekPath.lineTo(w * 0.32, h * 0.50);
      // Head crown
      peekPath.quadraticBezierTo(cx, h * 0.44, w * 0.68, h * 0.50);
      // Right ear tuft
      peekPath.lineTo(w * 0.86, h * 0.36);
      peekPath.lineTo(w * 0.82, h * 0.95);
      peekPath.close();
      canvas.drawPath(peekPath, bodyPaint);

      // Cream face disc
      final faceRect = Rect.fromCenter(center: Offset(cx, h * 0.76), width: w * 0.64, height: h * 0.52);
      canvas.drawOval(faceRect, innerFacePaint);

      // Vault dial eyes
      _drawEyes(canvas, cx, h * 0.70, w, h, goldRingPaint, pupilPaint, catchlightPaint, mood);

      // Beak
      final beakPath = Path();
      beakPath.moveTo(cx - w * 0.05, h * 0.75);
      beakPath.lineTo(cx + w * 0.05, h * 0.75);
      beakPath.lineTo(cx, h * 0.86);
      beakPath.close();
      canvas.drawPath(beakPath, beakPaint);
      return;
    }

    // Full Silhouette: Round minimal owl with signature ear tufts
    final bodyPath = Path();
    // Left ear tuft
    bodyPath.moveTo(w * 0.22, h * 0.36);
    bodyPath.lineTo(w * 0.12, h * 0.10); // Left tuft sharp tip
    bodyPath.lineTo(w * 0.34, h * 0.22);
    // Crown
    bodyPath.quadraticBezierTo(cx, h * 0.18, w * 0.66, h * 0.22);
    // Right ear tuft
    bodyPath.lineTo(w * 0.88, h * 0.10); // Right tuft sharp tip
    bodyPath.lineTo(w * 0.78, h * 0.36);
    // Body bottom curve
    bodyPath.cubicTo(w * 0.96, h * 0.60, w * 0.90, h * 0.92, cx, h * 0.92);
    bodyPath.cubicTo(w * 0.10, h * 0.92, w * 0.04, h * 0.60, w * 0.22, h * 0.36);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Cream mask / facial disc
    final maskPath = Path();
    maskPath.addOval(Rect.fromCenter(center: Offset(cx - w * 0.16, cy - h * 0.04), width: w * 0.34, height: w * 0.34));
    maskPath.addOval(Rect.fromCenter(center: Offset(cx + w * 0.16, cy - h * 0.04), width: w * 0.34, height: w * 0.34));
    canvas.drawPath(maskPath, innerFacePaint);

    // Eyes
    _drawEyes(canvas, cx, cy - h * 0.04, w, h, goldRingPaint, pupilPaint, catchlightPaint, mood);

    // Minimal amber geometric beak
    final beakPath = Path();
    beakPath.moveTo(cx - w * 0.05, cy + h * 0.02);
    beakPath.lineTo(cx + w * 0.05, cy + h * 0.02);
    beakPath.lineTo(cx, cy + h * 0.14);
    beakPath.close();
    canvas.drawPath(beakPath, beakPaint);

    // Detective Monocle / Inspector Hat
    if (showHat || mood == VowlMood.detective) {
      // Golden Monocle over left eye
      canvas.drawCircle(Offset(cx - w * 0.16, cy - h * 0.04), w * 0.17, monoclePaint);
      // Monocle cord
      final cordPath = Path();
      cordPath.moveTo(cx - w * 0.16 + w * 0.17, cy - h * 0.04);
      cordPath.quadraticBezierTo(cx - w * 0.02, cy + h * 0.18, cx - w * 0.10, cy + h * 0.36);
      canvas.drawPath(
        cordPath,
        Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.025,
      );
    }
  }

  void _drawEyes(
    Canvas canvas,
    double cx,
    double eyeY,
    double w,
    double h,
    Paint goldRingPaint,
    Paint pupilPaint,
    Paint catchlightPaint,
    VowlMood mood,
  ) {
    final eyeSpacing = w * 0.16;
    final leftX = cx - eyeSpacing;
    final rightX = cx + eyeSpacing;
    final eyeRadius = w * 0.12;

    if (mood == VowlMood.sleeping) {
      // Peaceful closed arcs
      final arcPaint = Paint()
        ..color = const Color(0xFF141413)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round;

      final leftRect = Rect.fromCircle(center: Offset(leftX, eyeY), radius: eyeRadius * 0.8);
      final rightRect = Rect.fromCircle(center: Offset(rightX, eyeY), radius: eyeRadius * 0.8);
      canvas.drawArc(leftRect, 0.2, pi - 0.4, false, arcPaint);
      canvas.drawArc(rightRect, 0.2, pi - 0.4, false, arcPaint);
      return;
    }

    if (mood == VowlMood.happy) {
      // Happy upward joyful arcs: ^ ^
      final arcPaint = Paint()
        ..color = const Color(0xFF141413)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round;

      final leftRect = Rect.fromCircle(center: Offset(leftX, eyeY + h * 0.02), radius: eyeRadius * 0.85);
      final rightRect = Rect.fromCircle(center: Offset(rightX, eyeY + h * 0.02), radius: eyeRadius * 0.85);
      canvas.drawArc(leftRect, pi + 0.3, pi - 0.6, false, arcPaint);
      canvas.drawArc(rightRect, pi + 0.3, pi - 0.6, false, arcPaint);
      return;
    }

    // Default: Vigilant Vault Dial Eyes
    // Golden dial rings
    canvas.drawCircle(Offset(leftX, eyeY), eyeRadius, goldRingPaint);
    canvas.drawCircle(Offset(rightX, eyeY), eyeRadius, goldRingPaint);

    // Pupils
    final pupilRadius = eyeRadius * 0.65;
    canvas.drawCircle(Offset(leftX, eyeY), pupilRadius, pupilPaint);
    canvas.drawCircle(Offset(rightX, eyeY), pupilRadius, pupilPaint);

    // Crisp catchlights
    final clRadius = pupilRadius * 0.35;
    canvas.drawCircle(Offset(leftX - clRadius * 0.6, eyeY - clRadius * 0.6), clRadius, catchlightPaint);
    canvas.drawCircle(Offset(rightX - clRadius * 0.6, eyeY - clRadius * 0.6), clRadius, catchlightPaint);
  }

  @override
  bool shouldRepaint(covariant _VowlPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.showHat != showHat;
  }
}
