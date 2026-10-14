import 'package:flutter/material.dart';

enum ValtoMood {
  peeking,
  idle,
  detective,
  sleeping,
  happy,
}

/// A delightful, responsive Flutter vector widget for Valto the Vault Cat.
/// Renders crisp and smooth at any resolution with zero external assets needed.
class ValtoMascot extends StatelessWidget {
  final double size;
  final ValtoMood mood;
  final bool showHat;

  const ValtoMascot({
    super.key,
    this.size = 56,
    this.mood = ValtoMood.peeking,
    this.showHat = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ValtoPainter(mood: mood, showHat: showHat),
      ),
    );
  }
}

class _ValtoPainter extends CustomPainter {
  final ValtoMood mood;
  final bool showHat;

  _ValtoPainter({required this.mood, required this.showHat});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Warm Golden Tabby Cat (Oyen)
    final furPaint = Paint()..color = const Color(0xFFF09A38); // Warm honey orange
    final innerEarPaint = Paint()..color = const Color(0xFFFFB5A7); // Soft peach
    final muzzlePaint = Paint()..color = const Color(0xFFFFE3B8); // Cream muzzle
    final eyePaint = Paint()..color = const Color(0xFF1D1D1B); // Ink dark
    final catchlightPaint = Paint()..color = Colors.white;
    final nosePaint = Paint()..color = const Color(0xFFE06D53); // Terracotta nose
    final blushPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.45);
    final pawPaint = Paint()..color = const Color(0xFFFFD199); // Soft paw pads
    final stripePaint = Paint()..color = const Color(0xFFD97724); // Darker orange stripes

    // Center coordinates
    final cx = w * 0.5;
    final cy = h * 0.55;

    // 1. EARS
    final leftEarPath = Path()
      ..moveTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.16, h * 0.08)
      ..lineTo(w * 0.42, h * 0.22)
      ..close();
    canvas.drawPath(leftEarPath, furPaint);

    final leftInnerEar = Path()
      ..moveTo(w * 0.25, h * 0.34)
      ..lineTo(w * 0.20, h * 0.14)
      ..lineTo(w * 0.38, h * 0.24)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    final rightEarPath = Path()
      ..moveTo(w * 0.78, h * 0.38)
      ..lineTo(w * 0.84, h * 0.08)
      ..lineTo(w * 0.58, h * 0.22)
      ..close();
    canvas.drawPath(rightEarPath, furPaint);

    final rightInnerEar = Path()
      ..moveTo(w * 0.75, h * 0.34)
      ..lineTo(w * 0.80, h * 0.14)
      ..lineTo(w * 0.62, h * 0.24)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // 2. HEAD (Rounded oval)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.78, height: h * 0.65),
      Radius.circular(w * 0.35),
    );
    canvas.drawRRect(headRect, furPaint);

    // Forehead Stripes (Classic Tabby)
    final stripe1 = Path()
      ..moveTo(cx - 3, h * 0.26)
      ..lineTo(cx + 3, h * 0.26)
      ..lineTo(cx, h * 0.34)
      ..close();
    canvas.drawPath(stripe1, stripePaint);

    final stripe2 = Path()
      ..moveTo(cx - 10, h * 0.28)
      ..lineTo(cx - 6, h * 0.28)
      ..lineTo(cx - 7, h * 0.33)
      ..close();
    canvas.drawPath(stripe2, stripePaint);

    final stripe3 = Path()
      ..moveTo(cx + 10, h * 0.28)
      ..lineTo(cx + 6, h * 0.28)
      ..lineTo(cx + 7, h * 0.33)
      ..close();
    canvas.drawPath(stripe3, stripePaint);

    // 3. CREAM MUZZLE
    final muzzleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.12), width: w * 0.38, height: h * 0.24),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(muzzleRect, muzzlePaint);

    // Nose
    final nosePath = Path()
      ..moveTo(cx - 3.5, cy + h * 0.06)
      ..lineTo(cx + 3.5, cy + h * 0.06)
      ..lineTo(cx, cy + h * 0.10)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Whiskers mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF6B451A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(cx, cy + h * 0.10)
      ..lineTo(cx, cy + h * 0.13)
      ..moveTo(cx, cy + h * 0.13)
      ..quadraticBezierTo(cx - 5, cy + h * 0.17, cx - 9, cy + h * 0.13)
      ..moveTo(cx, cy + h * 0.13)
      ..quadraticBezierTo(cx + 5, cy + h * 0.17, cx + 9, cy + h * 0.13);
    canvas.drawPath(mouthPath, mouthPaint);

    // 4. EYES ACCORDING TO MOOD
    if (mood == ValtoMood.sleeping) {
      // Happy sleeping eyes (^ . ^)
      final sleepEyePath = Path()
        ..moveTo(cx - 16, cy + 2)
        ..quadraticBezierTo(cx - 11, cy - 4, cx - 6, cy + 2)
        ..moveTo(cx + 6, cy + 2)
        ..quadraticBezierTo(cx + 11, cy - 4, cx + 16, cy + 2);
      canvas.drawPath(sleepEyePath, mouthPaint);
    } else {
      // Big expressive round eyes
      final eyeRadius = w * 0.07;
      final leftEye = Offset(cx - 11, cy + 1);
      final rightEye = Offset(cx + 11, cy + 1);

      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);

      // Catchlights
      canvas.drawCircle(Offset(leftEye.dx - 1.8, leftEye.dy - 1.8), eyeRadius * 0.38, catchlightPaint);
      canvas.drawCircle(Offset(rightEye.dx - 1.8, rightEye.dy - 1.8), eyeRadius * 0.38, catchlightPaint);
      canvas.drawCircle(Offset(leftEye.dx + 2, leftEye.dy + 2), eyeRadius * 0.18, catchlightPaint);
      canvas.drawCircle(Offset(rightEye.dx + 2, rightEye.dy + 2), eyeRadius * 0.18, catchlightPaint);
    }

    // Blushing Cheeks
    canvas.drawCircle(Offset(cx - 19, cy + h * 0.11), w * 0.065, blushPaint);
    canvas.drawCircle(Offset(cx + 19, cy + h * 0.11), w * 0.065, blushPaint);

    // 5. DETECTIVE GLASSES (when mood == detective)
    if (mood == ValtoMood.detective) {
      final glassPaint = Paint()
        ..color = const Color(0xFFC0A85C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(cx - 11, cy + 1), w * 0.10, glassPaint);
      canvas.drawCircle(Offset(cx + 11, cy + 1), w * 0.10, glassPaint);
      canvas.drawLine(Offset(cx - 1, cy + 1), Offset(cx + 1, cy + 1), glassPaint);
    }

    // 6. PEEKING PAWS (rest on bottom edge)
    if (mood == ValtoMood.peeking) {
      final paw1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 24, h * 0.80, w * 0.18, h * 0.18),
        Radius.circular(w * 0.09),
      );
      final paw2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 8, h * 0.80, w * 0.18, h * 0.18),
        Radius.circular(w * 0.09),
      );
      canvas.drawRRect(paw1, pawPaint);
      canvas.drawRRect(paw2, pawPaint);

      final linePaint = Paint()
        ..color = const Color(0xFFD97724)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(cx - 18, h * 0.88), Offset(cx - 18, h * 0.94), linePaint);
      canvas.drawLine(Offset(cx - 14, h * 0.88), Offset(cx - 14, h * 0.94), linePaint);
      canvas.drawLine(Offset(cx + 14, h * 0.88), Offset(cx + 14, h * 0.94), linePaint);
      canvas.drawLine(Offset(cx + 18, h * 0.88), Offset(cx + 18, h * 0.94), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ValtoPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.showHat != showHat;
  }
}
