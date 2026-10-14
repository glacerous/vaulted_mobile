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
/// Built with compact, square 6x6 pixel geometry:
/// Two perky ear blocks, symmetrical square eyes, two stubby paws,
/// and a cute curled tail on the side. Pure matte black cat silhouette.
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
        painter: _CompactBlackCatPainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFF161615), // Pure matte black cat
          eyeColor: eyeColor ?? const Color(0xFFFBBF24), // Warm amber eyes
        ),
      ),
    );
  }
}

class _CompactBlackCatPainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;

  _CompactBlackCatPainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
  });

  // Compact 6x6 Pixel Grid (Not wide! Perfectly square, balanced proportions)
  // '#' = black body block, 'E' = eye block, '.' = transparent
  static const List<String> _catGrid = [
    '#...#.', // Row 0: Two cute ear blocks
    '#####.', // Row 1: Crown between ears
    '#E#E#.', // Row 2: Expressive eyes (symmetrical, compact)
    '#####.', // Row 3: Cheeks / snout
    '.###.#', // Row 4: Sitting body + tail tip
    '.#.#.#', // Row 5: Two paws + tail base
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 6;
    const rows = 6;

    final blockSize = (size.width / cols).clamp(1.0, size.height / rows);
    final totalW = blockSize * cols;
    final totalH = blockSize * rows;
    final ox = (size.width - totalW) / 2;
    final oy = (size.height - totalH) / 2;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Subtle outline for crisp visibility against dark backgrounds
    final borderPaint = Paint()
      ..color = const Color(0xFF32322F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

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
          canvas.drawRect(rect, borderPaint);
        } else if (ch == 'E') {
          // Body under eye
          canvas.drawRect(rect, bodyPaint);
          canvas.drawRect(rect, borderPaint);

          // Mood eye variations
          if (mood == ValtoMood.happy) {
            // Cheerful happy squint slit (- -)
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.35,
              rect.width,
              rect.height * 0.3,
            );
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.sleeping) {
            // Calm sleeping closed eyes
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.55,
              rect.width,
              rect.height * 0.25,
            );
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.detective && c == 3) {
            // Right eye has curious monocle frame
            canvas.drawRect(rect, eyePaint);
            final monoclePaint = Paint()
              ..color = const Color(0xFFC0A85C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;
            canvas.drawRect(rect.inflate(blockSize * 0.15), monoclePaint);
          } else {
            // Standard warm amber square eye
            canvas.drawRect(rect, eyePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompactBlackCatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor;
  }
}
