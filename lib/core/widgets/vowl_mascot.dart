import 'dart:math';
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

/// Valto — The Minimal Black Cat Mascot of VAULTED.
/// Inspired by Claude's organic, ultra-minimal character design.
/// Pure matte obsidian silhouette with expressive minimal eyes and sleek contours.
class ValtoMascot extends StatelessWidget {
  final double size;
  final ValtoMood mood;
  final bool showHat;

  const ValtoMascot({
    super.key,
    this.size = 56,
    this.mood = ValtoMood.vigilant,
    this.showHat = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ValtoCatPainter(mood: mood, showHat: showHat),
      ),
    );
  }
}

class _ValtoCatPainter extends CustomPainter {
  final ValtoMood mood;
  final bool showHat;

  _ValtoCatPainter({required this.mood, required this.showHat});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Sleek Matte Obsidian Black Cat
    final catBlack = Paint()
      ..color = const Color(0xFF141413)
      ..style = PaintingStyle.fill;

    final innerEarPaint = Paint()
      ..color = const Color(0xFF2C2A29)
      ..style = PaintingStyle.fill;

    final eyeGold = const Color(0xFFFBBF24); // Warm radiant amber eyes
    final eyeWhite = Colors.white;
    final pupilBlack = const Color(0xFF141413);

    final whiskerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, w * 0.022)
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.5;

    // -------------------------------------------------------------
    // PEEKING POSE: Head, Pointed Ears, and Paws resting on the rim
    // -------------------------------------------------------------
    if (mood == ValtoMood.peeking) {
      // Head base path
      final headPath = Path();
      // Left ear
      headPath.moveTo(w * 0.16, h * 0.95);
      headPath.lineTo(w * 0.14, h * 0.28); // Left ear tip
      headPath.lineTo(w * 0.36, h * 0.44);
      // Crown between ears
      headPath.quadraticBezierTo(cx, h * 0.40, w * 0.64, h * 0.44);
      // Right ear
      headPath.lineTo(w * 0.86, h * 0.28); // Right ear tip
      headPath.lineTo(w * 0.84, h * 0.95);
      headPath.close();
      canvas.drawPath(headPath, catBlack);

      // Inner ear shadows
      final leftEarInner = Path()
        ..moveTo(w * 0.18, h * 0.80)
        ..lineTo(w * 0.17, h * 0.35)
        ..lineTo(w * 0.34, h * 0.48)
        ..close();
      canvas.drawPath(leftEarInner, innerEarPaint);

      final rightEarInner = Path()
        ..moveTo(w * 0.82, h * 0.80)
        ..lineTo(w * 0.83, h * 0.35)
        ..lineTo(w * 0.66, h * 0.48)
        ..close();
      canvas.drawPath(rightEarInner, innerEarPaint);

      // Two minimal paws resting on the ledge
      final pawPaint = Paint()..color = const Color(0xFF141413);
      final pawRim = Paint()
        ..color = const Color(0xFF2C2A29)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Left paw
      final leftPaw = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.30, h * 0.92), width: w * 0.22, height: h * 0.16),
        Radius.circular(w * 0.08),
      );
      canvas.drawRRect(leftPaw, pawPaint);
      canvas.drawRRect(leftPaw, pawRim);

      // Right paw
      final rightPaw = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.70, h * 0.92), width: w * 0.22, height: h * 0.16),
        Radius.circular(w * 0.08),
      );
      canvas.drawRRect(rightPaw, pawPaint);
      canvas.drawRRect(rightPaw, pawRim);

      // Expressive minimalist eyes
      _drawCatEyes(canvas, cx, h * 0.64, w, h, eyeGold, pupilBlack, eyeWhite, mood);

      // Fine whiskers
      _drawWhiskers(canvas, cx, h * 0.74, w, whiskerPaint);
      return;
    }

    // -------------------------------------------------------------
    // FULL SILHOUETTE: Clean loaf / seated cat silhouette
    // -------------------------------------------------------------
    final catBody = Path();
    // Left ear
    catBody.moveTo(w * 0.22, h * 0.40);
    catBody.lineTo(w * 0.15, h * 0.12); // Left ear sharp tip
    catBody.lineTo(w * 0.38, h * 0.25);
    // Crown
    catBody.quadraticBezierTo(cx, h * 0.22, w * 0.62, h * 0.25);
    // Right ear
    catBody.lineTo(w * 0.85, h * 0.12); // Right ear sharp tip
    catBody.lineTo(w * 0.78, h * 0.40);
    // Sleek body / loaf curves down
    catBody.cubicTo(w * 0.94, h * 0.58, w * 0.90, h * 0.88, cx, h * 0.88);
    catBody.cubicTo(w * 0.10, h * 0.88, w * 0.06, h * 0.58, w * 0.22, h * 0.40);
    catBody.close();
    canvas.drawPath(catBody, catBlack);

    // Subtle inner ear facets
    final leftEarInner = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.18, h * 0.18)
      ..lineTo(w * 0.35, h * 0.28)
      ..close();
    canvas.drawPath(leftEarInner, innerEarPaint);

    final rightEarInner = Path()
      ..moveTo(w * 0.78, h * 0.36)
      ..lineTo(w * 0.82, h * 0.18)
      ..lineTo(w * 0.65, h * 0.28)
      ..close();
    canvas.drawPath(rightEarInner, innerEarPaint);

    // Curled Tail by the side
    final tailPath = Path();
    tailPath.moveTo(w * 0.74, h * 0.84);
    tailPath.quadraticBezierTo(w * 0.96, h * 0.80, w * 0.94, h * 0.62);
    tailPath.quadraticBezierTo(w * 0.92, h * 0.52, w * 0.86, h * 0.54);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFF141413)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );

    // Expressive eyes
    _drawCatEyes(canvas, cx, h * 0.48, w, h, eyeGold, pupilBlack, eyeWhite, mood);

    // Nose
    final nosePath = Path();
    nosePath.moveTo(cx - w * 0.025, h * 0.56);
    nosePath.lineTo(cx + w * 0.025, h * 0.56);
    nosePath.lineTo(cx, h * 0.585);
    nosePath.close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFF4A4442));

    // Whiskers
    _drawWhiskers(canvas, cx, h * 0.58, w, whiskerPaint);

    // Detective hat/accessory (minimalist subtle gold bell or collar)
    if (showHat || mood == ValtoMood.detective) {
      // Sleek luxury gold vault collar
      final collarPath = Path();
      collarPath.moveTo(w * 0.32, h * 0.72);
      collarPath.quadraticBezierTo(cx, h * 0.76, w * 0.68, h * 0.72);
      canvas.drawPath(
        collarPath,
        Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round,
      );

      // Tiny gold lock pendant
      canvas.drawCircle(
        Offset(cx, h * 0.76),
        w * 0.035,
        Paint()..color = const Color(0xFFFBBF24),
      );
    }
  }

  void _drawCatEyes(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    Color eyeColor,
    Color pupilColor,
    Color catchlight,
    ValtoMood mood,
  ) {
    final eyeSpacing = w * 0.16;
    final eyeW = w * 0.16;
    final eyeH = w * 0.16;

    if (mood == ValtoMood.sleeping) {
      // Peaceful sleeping curved eyes: ◡  ◡
      final sleepPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round;

      final leftEye = Path();
      leftEye.moveTo(cx - eyeSpacing - eyeW * 0.45, cy);
      leftEye.quadraticBezierTo(cx - eyeSpacing, cy + eyeH * 0.45, cx - eyeSpacing + eyeW * 0.45, cy);
      canvas.drawPath(leftEye, sleepPaint);

      final rightEye = Path();
      rightEye.moveTo(cx + eyeSpacing - eyeW * 0.45, cy);
      rightEye.quadraticBezierTo(cx + eyeSpacing, cy + eyeH * 0.45, cx + eyeSpacing + eyeW * 0.45, cy);
      canvas.drawPath(rightEye, sleepPaint);
      return;
    }

    if (mood == ValtoMood.happy) {
      // Cheerful happy eyes: ^  ^
      final happyPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round;

      final leftEye = Path();
      leftEye.moveTo(cx - eyeSpacing - eyeW * 0.45, cy + eyeH * 0.15);
      leftEye.quadraticBezierTo(cx - eyeSpacing, cy - eyeH * 0.40, cx - eyeSpacing + eyeW * 0.45, cy + eyeH * 0.15);
      canvas.drawPath(leftEye, happyPaint);

      final rightEye = Path();
      rightEye.moveTo(cx + eyeSpacing - eyeW * 0.45, cy + eyeH * 0.15);
      rightEye.quadraticBezierTo(cx + eyeSpacing, cy - eyeH * 0.40, cx + eyeSpacing + eyeW * 0.45, cy + eyeH * 0.15);
      canvas.drawPath(rightEye, happyPaint);
      return;
    }

    // Default / Vigilant / Detective: Glowing almond-shaped amber eyes
    final eyePaint = Paint()..color = eyeColor;
    final pupilPaint = Paint()..color = pupilColor;
    final catchPaint = Paint()..color = catchlight;

    for (final sign in [-1.0, 1.0]) {
      final eyeCenter = Offset(cx + sign * eyeSpacing, cy);

      // Elegant almond eye contour
      final almondPath = Path();
      almondPath.moveTo(eyeCenter.dx - eyeW * 0.45, eyeCenter.dy);
      almondPath.quadraticBezierTo(eyeCenter.dx, eyeCenter.dy - eyeH * 0.48, eyeCenter.dx + eyeW * 0.45, eyeCenter.dy);
      almondPath.quadraticBezierTo(eyeCenter.dx, eyeCenter.dy + eyeH * 0.48, eyeCenter.dx - eyeW * 0.45, eyeCenter.dy);
      almondPath.close();

      canvas.drawPath(almondPath, eyePaint);

      // Slit pupil
      final pupilRect = Rect.fromCenter(
        center: eyeCenter,
        width: mood == ValtoMood.detective ? eyeW * 0.45 : eyeW * 0.22,
        height: eyeH * 0.65,
      );
      canvas.drawOval(pupilRect, pupilPaint);

      // Micro catchlight twinkle
      canvas.drawCircle(
        Offset(eyeCenter.dx + eyeW * 0.12, eyeCenter.dy - eyeH * 0.15),
        eyeW * 0.09,
        catchPaint,
      );
    }
  }

  void _drawWhiskers(Canvas canvas, double cx, double cy, double w, Paint whiskerPaint) {
    // Left whiskers
    canvas.drawLine(
      Offset(cx - w * 0.12, cy - w * 0.02),
      Offset(cx - w * 0.38, cy - w * 0.06),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(cx - w * 0.12, cy + w * 0.03),
      Offset(cx - w * 0.36, cy + w * 0.08),
      whiskerPaint,
    );

    // Right whiskers
    canvas.drawLine(
      Offset(cx + w * 0.12, cy - w * 0.02),
      Offset(cx + w * 0.38, cy - w * 0.06),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.12, cy + w * 0.03),
      Offset(cx + w * 0.36, cy + w * 0.08),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ValtoCatPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.showHat != showHat;
  }
}
