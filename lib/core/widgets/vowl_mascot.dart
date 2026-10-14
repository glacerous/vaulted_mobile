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

/// Valto — The Authentic Blocky Cat Mascot of VAULTED.
/// Built with retro pixel/block geometric clarity:
/// Pointed triangular block ears, wide cat cheeks, glowing amber square eyes,
/// compact sitting torso, front paws, side haunches, and a curling block tail.
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
        painter: _PixelCatPainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFF141413),
          eyeColor: eyeColor ?? const Color(0xFFFBBF24),
          showHat: showHat,
        ),
      ),
    );
  }
}

class _PixelCatPainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;
  final bool showHat;

  _PixelCatPainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
    required this.showHat,
  });

  // 13x11 Authentic Symmetrical Pixel Cat Grid
  // '#' = body block, 'E' = eye block, '.' = transparent
  static const List<String> _fullCatGrid = [
    '..#.......#..', // Row 0: Sharp ear tips (cols 2, 10)
    '.###.....###.', // Row 1: Triangular ear bases (cols 1..3, 9..11)
    '.###########.', // Row 2: Top crown between ears
    '.##EE###EE##.', // Row 3: Expressive eyes (cols 3..4, 8..9)
    '.###########.', // Row 4: Cat muzzle / cheeks
    '..#########.#', // Row 5: Jaw taper + tail curl tip!
    '..#########.#', // Row 6: Neck + tail
    '.##########.#', // Row 7: Sitting torso + tail
    '.##########.#', // Row 8: Sitting torso + tail
    '.############', // Row 9: Body connected to tail base
    '##.##...##.##', // Row 10: 2 paws & 2 folded haunches
  ];

  // Peeking over omnibar ledge: Head, ears, eyes & two paws on the rim
  static const List<String> _peekingGrid = [
    '..#.......#..', // Row 0: Ear tips
    '.###.....###.', // Row 1: Triangular ears
    '.###########.', // Row 2: Top crown
    '.##EE###EE##.', // Row 3: Eyes
    '.###########.', // Row 4: Muzzle
    '..##.....##..', // Row 5: Two paws resting on the rim!
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final grid = (mood == ValtoMood.peeking) ? _peekingGrid : _fullCatGrid;
    final cols = grid[0].length; // 13
    final rows = grid.length;    // 11 or 6

    final blockSize = (size.width / cols).clamp(1.0, size.height / rows);
    final totalW = blockSize * cols;
    final totalH = blockSize * rows;
    final ox = (size.width - totalW) / 2;
    final oy = (size.height - totalH) / 2;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2C2A28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      final rowStr = grid[r];
      for (int c = 0; c < cols; c++) {
        final ch = rowStr[c];
        if (ch == '.') continue;

        final rect = Rect.fromLTWH(
          ox + c * blockSize,
          oy + r * blockSize,
          blockSize + 0.1, // tiny overlap to prevent subpixel hairline gap
          blockSize + 0.1,
        );

        if (ch == '#') {
          canvas.drawRect(rect, bodyPaint);
          canvas.drawRect(rect, borderPaint);
        } else if (ch == 'E') {
          // Draw eye with mood expression
          if (mood == ValtoMood.happy) {
            // Happy squint slit
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.35,
              rect.width,
              rect.height * 0.35,
            );
            canvas.drawRect(rect, bodyPaint);
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.sleeping) {
            // Calm sleeping line
            final slitRect = Rect.fromLTWH(
              rect.left,
              rect.top + rect.height * 0.5,
              rect.width,
              rect.height * 0.25,
            );
            canvas.drawRect(rect, bodyPaint);
            canvas.drawRect(slitRect, eyePaint);
          } else if (mood == ValtoMood.detective && c >= 8) {
            // Right eye has a gold monocle frame
            canvas.drawRect(rect, eyePaint);
            final monocleRim = Paint()
              ..color = const Color(0xFFC0A85C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;
            canvas.drawRect(
              rect.inflate(blockSize * 0.25),
              monocleRim,
            );
          } else {
            // Solid bright square eye block
            canvas.drawRect(rect, eyePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.showHat != showHat;
  }
}
