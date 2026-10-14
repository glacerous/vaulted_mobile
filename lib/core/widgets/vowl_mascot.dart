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

/// Valto — The Signature Black Cat Mascot of VAULTED.
/// Faithfully modeled after authentic retro pixel cat art:
/// Pointed ears with inner facets, vertical radiant yellow cat eyes,
/// black pixel nose, compact sitting body, front paws, and a curled tail.
class ValtoMascot extends StatelessWidget {
  final double size;
  final ValtoMood mood;
  final Color? outlineColor;
  final Color? bodyColor;
  final Color? eyeColor;
  final bool showHat;

  const ValtoMascot({
    super.key,
    this.size = 56,
    this.mood = ValtoMood.vigilant,
    this.outlineColor,
    this.bodyColor,
    this.eyeColor,
    this.showHat = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ReferencePixelCatPainter(
          mood: mood,
          outlineColor: outlineColor ?? const Color(0xFF141413), // Deep black outline
          bodyColor: bodyColor ?? const Color(0xFF383836),       // Charcoal cat body
          eyeColor: eyeColor ?? const Color(0xFFFACC15),         // Glowing yellow cat iris
        ),
      ),
    );
  }
}

class _ReferencePixelCatPainter extends CustomPainter {
  final ValtoMood mood;
  final Color outlineColor;
  final Color bodyColor;
  final Color eyeColor;

  _ReferencePixelCatPainter({
    required this.mood,
    required this.outlineColor,
    required this.bodyColor,
    required this.eyeColor,
  });

  // Exact 15x16 Pixel Cat Grid from Reference Art
  // 'B' = Black outline, 'G' = Charcoal body fill, 'Y' = Yellow eye, '.' = Transparent
  static const List<String> _grid = [
    '..BB.....BB....', // Row 0: Ear tips
    '.BGGB...BGGB...', // Row 1: Ear facets
    '.BGGGBBBGGGB...', // Row 2: Crown between ears
    '.BGGGGGGGGGB...', // Row 3: Forehead
    'BGGGGGGGGGGGB..', // Row 4: Cheeks
    'BGGYGGGGGYGGB..', // Row 5: Upper eye
    'BGGYGGGGGYGGB..', // Row 6: Lower eye (vertical slit)
    'BGGGGGBGGGGGB..', // Row 7: Snout with black nose pixel in center
    '.BBGGGGGGGBB...', // Row 8: Chin / jaw
    '...BGGGGGB.....', // Row 9: Neck
    '...BGGGGGB...B.', // Row 10: Chest & tail tip
    '...BGGGGGB..BGB', // Row 11: Body & tail curve
    '..BGGGGGGGB.BGB', // Row 12: Sitting body & tail
    '..BGGBGBGGBBGGB', // Row 13: Front paws & tail base
    '..BGGBGBGGBGGB.', // Row 14: Paws & tail connection
    '...BBBBBBBBBB..', // Row 15: Bottom edge outline
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 15;
    const rows = 16;

    final blockSize = (size.width / cols).clamp(1.0, size.height / rows);
    final totalW = blockSize * cols;
    final totalH = blockSize * rows;
    final ox = (size.width - totalW) / 2;
    final oy = (size.height - totalH) / 2;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      final rowStr = _grid[r];
      for (int c = 0; c < cols; c++) {
        final ch = rowStr[c];
        if (ch == '.') continue;

        final rect = Rect.fromLTWH(
          ox + c * blockSize,
          oy + r * blockSize,
          blockSize + 0.1, // Subpixel antialias bridge
          blockSize + 0.1,
        );

        if (ch == 'B') {
          canvas.drawRect(rect, outlinePaint);
        } else if (ch == 'G') {
          canvas.drawRect(rect, fillPaint);
        } else if (ch == 'Y') {
          if (mood == ValtoMood.happy) {
            // Cheerful squint slit
            if (r == 6) {
              canvas.drawRect(rect, fillPaint);
              final slitRect = Rect.fromLTWH(
                rect.left,
                rect.top + rect.height * 0.35,
                rect.width,
                rect.height * 0.3,
              );
              canvas.drawRect(slitRect, eyePaint);
            } else {
              canvas.drawRect(rect, fillPaint);
            }
          } else if (mood == ValtoMood.sleeping) {
            // Sleeping closed eye
            if (r == 6) {
              canvas.drawRect(rect, fillPaint);
              final slitRect = Rect.fromLTWH(
                rect.left,
                rect.top + rect.height * 0.5,
                rect.width,
                rect.height * 0.25,
              );
              canvas.drawRect(slitRect, eyePaint);
            } else {
              canvas.drawRect(rect, fillPaint);
            }
          } else if (mood == ValtoMood.detective && c == 9) {
            // Right eye has curious golden monocle
            canvas.drawRect(rect, eyePaint);
            final monoclePaint = Paint()
              ..color = const Color(0xFFFBBF24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;
            canvas.drawRect(rect.inflate(blockSize * 0.2), monoclePaint);
          } else {
            // Standard vertical yellow cat eye (as in reference art)
            canvas.drawRect(rect, eyePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReferencePixelCatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor;
  }
}
