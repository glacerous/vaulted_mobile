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
/// Inspired directly by Claude's Claw'd: warm terracotta block silhouette,
/// two cute ear blocks, big friendly square eyes, and two stubby paws.
/// Ultra-minimal 7x5 retro grid that is friendly, charming, and never creepy.
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
        painter: _SimpleBlockyCatPainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFFCC6B49), // Warm Claude terracotta
          eyeColor: eyeColor ?? const Color(0xFF141413), // Clean black square eyes
        ),
      ),
    );
  }
}

class _SimpleBlockyCatPainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;

  _SimpleBlockyCatPainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
  });

  // Simple 7x5 Block Grid:
  // '#' = body block, 'E' = eye block, '.' = transparent
  static const List<String> _catGrid = [
    '#.....#', // Row 0: Two cute ear blocks on top corners
    '#######', // Row 1: Crown between ears
    '#E###E#', // Row 2: Friendly square eyes
    '#######', // Row 3: Cheeks / chin
    '..#.#..', // Row 4: Two cute little front paws in the middle
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 7;
    const rows = 5;

    final blockSize = (size.width / cols).clamp(1.0, size.height / rows);
    final totalW = blockSize * cols;
    final totalH = blockSize * rows;
    final ox = (size.width - totalW) / 2;
    final oy = (size.height - totalH) / 2;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      final rowStr = _catGrid[r];
      for (int c = 0; c < cols; c++) {
        final ch = rowStr[c];
        if (ch == '.') continue;

        final rect = Rect.fromLTWH(
          ox + c * blockSize,
          oy + r * blockSize,
          blockSize + 0.1,
          blockSize + 0.1,
        );

        if (ch == '#') {
          canvas.drawRect(rect, bodyPaint);
        } else if (ch == 'E') {
          // Body base under eye
          canvas.drawRect(rect, bodyPaint);

          // Render eye according to mood
          if (mood == ValtoMood.happy) {
            // Happy squint slit (^ ^)
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.35,
              rect.width,
              rect.height * 0.3,
            );
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.sleeping) {
            // Sleeping closed eye (- -)
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.55,
              rect.width,
              rect.height * 0.25,
            );
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.detective && c == 5) {
            // Right eye has curious monocle frame
            canvas.drawRect(rect, eyePaint);
            final monoclePaint = Paint()
              ..color = const Color(0xFFFBBF24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
            canvas.drawRect(rect.inflate(blockSize * 0.2), monoclePaint);
          } else {
            // Standard friendly square eye (like Claw'd)
            canvas.drawRect(rect, eyePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleBlockyCatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor;
  }
}
