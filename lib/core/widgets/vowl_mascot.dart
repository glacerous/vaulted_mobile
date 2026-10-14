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

/// Valto — The Signature Solid Black Cat Mascot of VAULTED.
/// Built from the user's reference pixel art: pointed ears, round head,
/// radiant vertical yellow cat eyes, sitting body, and curled tail.
/// Rendered with run-length horizontal quad spans to eliminate all subpixel grid seams.
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
        painter: _SeamlessBlackCatPainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFF141413),  // Solid matte black cat
          eyeColor: eyeColor ?? const Color(0xFFFACC15), // Glowing yellow cat eyes
        ),
      ),
    );
  }
}

class _SeamlessBlackCatPainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;

  _SeamlessBlackCatPainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
  });

  // Solid Pixel Cat Grid from Reference Art (15 cols x 16 rows)
  // '#' = Solid Black Cat Body, 'Y' = Radiant Yellow Cat Eyes, '.' = Transparent
  static const List<String> _catGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown between ears
    '.###########...', // Row 3: Forehead
    '#############..', // Row 4: Cheeks
    '###Y#####Y###..', // Row 5: Upper eye
    '###Y#####Y###..', // Row 6: Lower eye (vertical slit)
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin / jaw
    '...#######.....', // Row 9: Neck
    '...#######...#.', // Row 10: Chest & curled tail tip
    '...#######..###', // Row 11: Body & tail curve
    '..#########.###', // Row 12: Sitting body & tail
    '..#########.###', // Row 13: Front paws & tail base
    '..#########.##.', // Row 14: Paws & tail connection
    '...##########..', // Row 15: Bottom edge
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

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Subtle hairline contour on outer edges for crisp contrast on dark cards
    final borderPaint = Paint()
      ..color = const Color(0xFF2C2C29)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final silhouettePath = Path();

    // 1. Draw solid body spans (run-length merged horizontally to eliminate grid seams!)
    for (int r = 0; r < rows; r++) {
      final rowStr = _catGrid[r];
      int c = 0;
      while (c < cols) {
        final ch = rowStr[c];
        if (ch == '.') {
          c++;
          continue;
        }

        int startC = c;
        while (c < cols && rowStr[c] != '.') {
          c++;
        }

        // Single continuous solid rectangle for the entire row span!
        final rect = Rect.fromLTRB(
          ox + startC * blockSize - 0.2,
          oy + r * blockSize - 0.2,
          ox + c * blockSize + 0.2,
          oy + (r + 1) * blockSize + 0.2,
        );

        canvas.drawRect(rect, bodyPaint);
        silhouettePath.addRect(rect);
      }
    }

    // Outer silhouette outline
    canvas.drawPath(silhouettePath, borderPaint);

    // 2. Draw radiant yellow cat eyes with mood expressions
    for (int r = 0; r < rows; r++) {
      final rowStr = _catGrid[r];
      for (int c = 0; c < cols; c++) {
        if (rowStr[c] != 'Y') continue;

        final eyeRect = Rect.fromLTWH(
          ox + c * blockSize,
          oy + r * blockSize,
          blockSize + 0.1,
          blockSize + 0.1,
        );

        if (mood == ValtoMood.happy) {
          // Cheerful squint slit
          if (r == 6) {
            final slitRect = Rect.fromLTWH(
              eyeRect.left,
              eyeRect.top + eyeRect.height * 0.35,
              eyeRect.width,
              eyeRect.height * 0.35,
            );
            canvas.drawRect(slitRect, eyePaint);
          }
        } else if (mood == ValtoMood.sleeping) {
          // Closed peaceful eye slit
          if (r == 6) {
            final slitRect = Rect.fromLTWH(
              eyeRect.left,
              eyeRect.top + eyeRect.height * 0.5,
              eyeRect.width,
              eyeRect.height * 0.25,
            );
            canvas.drawRect(slitRect, eyePaint);
          }
        } else if (mood == ValtoMood.detective && c == 9) {
          // Right eye has curious golden monocle rim
          canvas.drawRect(eyeRect, eyePaint);
          final monoclePaint = Paint()
            ..color = const Color(0xFFFBBF24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawRect(eyeRect.inflate(blockSize * 0.15), monoclePaint);
        } else {
          // Standard vibrant yellow cat eye
          canvas.drawRect(eyeRect, eyePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeamlessBlackCatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor;
  }
}
