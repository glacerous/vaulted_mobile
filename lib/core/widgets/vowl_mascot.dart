import 'package:flutter/material.dart';

enum ValtoMood {
  vigilant,  // Classic seated vault guardian
  happy,     // Victorious celebrating pose (paw raised high & smiling eyes)
  detective, // Investigative pose (cocked ear & golden monocle)
  sleeping,  // Cozy cat loaf (paws tucked, relaxed ears, sleeping eyes)
  playful,   // Friendly greeting wave (Maneki-neko lucky cat pose)
  peeking,   // Peeking pose (ears & paws over rim)
}

// Backward compatibility alias
typedef VowlMood = ValtoMood;
typedef VowlMascot = ValtoMascot;

/// Valto — The Signature Black Cat Mascot of VAULTED.
/// Built with consistent 15x16 pixel geometry across multiple expressive poses:
/// Vigilant (seated), Happy (victory paw raised), Detective (monocle),
/// Sleeping (loaf), Playful (waving), and Peeking.
/// Rendered with horizontal span merging for a 100% solid, seamless silhouette.
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
        painter: _ValtoPosePainter(
          mood: mood,
          bodyColor: color ?? const Color(0xFF141413),  // Solid matte black cat
          eyeColor: eyeColor ?? const Color(0xFFFACC15), // Radiant yellow eyes
        ),
      ),
    );
  }
}

class _ValtoPosePainter extends CustomPainter {
  final ValtoMood mood;
  final Color bodyColor;
  final Color eyeColor;

  _ValtoPosePainter({
    required this.mood,
    required this.bodyColor,
    required this.eyeColor,
  });

  // 1. VIGILANT: Classic Seated Vault Guardian
  static const List<String> _vigilantGrid = [
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
    '...#######...#.', // Row 10: Chest & tail tip
    '...#######..###', // Row 11: Body & tail curve
    '..#########.###', // Row 12: Sitting body & tail
    '..#########.###', // Row 13: Front paws & tail base
    '..#########.##.', // Row 14: Paws & tail connection
    '...##########..', // Row 15: Bottom edge
  ];

  // 2. HAPPY: Victorious Celebration (Paw Raised High, Tail Perked, Smiling Eyes)
  static const List<String> _happyGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown between ears
    '.###########...', // Row 3: Forehead
    '#############..', // Row 4: Cheeks
    '###Y#####Y###..', // Row 5: Cheerful smiling crescent eyes (^ ^)
    '#############..', // Row 6: Snout
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '...#######.....', // Row 9: Neck
    '.#.#######....#', // Row 10: High victorious paw & high tail tip!
    '###.######...##', // Row 11: Raised paw arm & tail
    '.##.######..###', // Row 12: Paw leg & tail
    '..########.####', // Row 13: Sitting body & tail
    '..########.###.', // Row 14: Base
    '...##########..', // Row 15: Bottom edge
  ];

  // 3. SLEEPING: Cozy Cat Loaf (Tucked Paws, Relaxed Body, Closed Eyes)
  static const List<String> _sleepingGrid = [
    '...............', // Row 0: Resting low
    '...............', // Row 1: Resting low
    '..##.....##....', // Row 2: Relaxed ears
    '.####...####...', // Row 3: Ear facets
    '.###########...', // Row 4: Head crown
    '.###########...', // Row 5: Forehead
    '#############..', // Row 6: Cheeks
    '###Y#####Y###..', // Row 7: Peaceful sleeping slit eyes (- -)
    '#############..', // Row 8: Resting snout
    '.###########...', // Row 9: Chin
    '.#############.', // Row 10: Loaf shoulder
    '###############', // Row 11: Full loaf body
    '###############', // Row 12: Full loaf body
    '###############', // Row 13: Paws tucked underneath
    '.#############.', // Row 14: Tail wrapped snugly along the front
    '..###########..', // Row 15: Base
  ];

  // 4. DETECTIVE: Investigative Pose (Cocked Ear, Golden Monocle, Inquisitive Paw)
  static const List<String> _detectiveGrid = [
    '..##...........', // Row 0: Left ear alert straight up
    '.####....##....', // Row 1: Right ear cocked curious
    '.####...####...', // Row 2: Crown
    '.###########...', // Row 3: Head slightly tilted
    '#############..', // Row 4: Cheeks
    '###Y#####M###..', // Row 5: Left eye sharp, Right eye with monocle 'M'
    '###Y#####M###..', // Row 6: Monocle lens
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '...#######.....', // Row 9: Neck
    '...#######...#.', // Row 10: Tail
    '...#######..###', // Row 11: Body
    '..#########.###', // Row 12: Sitting body
    '..#########.###', // Row 13: Front paws
    '..#########.##.', // Row 14: Paws
    '...##########..', // Row 15: Bottom edge
  ];

  // 5. PLAYFUL / WAVING: Lucky Cat Greeting Wave (Maneki-neko)
  static const List<String> _playfulGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown
    '.###########.#.', // Row 3: Paw raising on right
    '#############.#', // Row 4: Waving paw!
    '###Y#####Y###.#', // Row 5: Eyes & waving paw tip
    '###Y#####Y###..', // Row 6: Eyes
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '...#######.....', // Row 9: Neck
    '...#######...#.', // Row 10: Tail
    '...#######..###', // Row 11: Body
    '..#########.###', // Row 12: Sitting body
    '..#########.###', // Row 13: Front paws
    '..#########.##.', // Row 14: Paws
    '...##########..', // Row 15: Bottom edge
  ];

  // 6. PEEKING: Head, Ears, Eyes & Two Paws resting on the rim
  static const List<String> _peekingGrid = [
    '...............',
    '...............',
    '...............',
    '..##.....##....', // Ear tips
    '.####...####...', // Ear facets
    '.###########...', // Crown
    '.###########...', // Forehead
    '#############..', // Cheeks
    '###Y#####Y###..', // Eyes top
    '###Y#####Y###..', // Eyes bottom
    '#############..', // Snout
    '.###########...', // Chin
    '..##.....##....', // Two paws resting on the rim!
    '...............',
    '...............',
    '...............',
  ];

  List<String> get _activeGrid {
    switch (mood) {
      case ValtoMood.happy:
        return _happyGrid;
      case ValtoMood.sleeping:
        return _sleepingGrid;
      case ValtoMood.detective:
        return _detectiveGrid;
      case ValtoMood.playful:
        return _playfulGrid;
      case ValtoMood.peeking:
        return _peekingGrid;
      case ValtoMood.vigilant:
        return _vigilantGrid;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _activeGrid;
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

    // Outer contour outline to define edges on dark cards
    final borderPaint = Paint()
      ..color = const Color(0xFF2C2C29)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final silhouettePath = Path();

    // 1. Draw solid body spans (run-length merged horizontally for ZERO grid seams)
    for (int r = 0; r < rows; r++) {
      final rowStr = grid[r];
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

    // Outer edge contour only
    canvas.drawPath(silhouettePath, borderPaint);

    // 2. Draw expressive eyes / features according to pose
    for (int r = 0; r < rows; r++) {
      final rowStr = grid[r];
      for (int c = 0; c < cols; c++) {
        final ch = rowStr[c];
        if (ch != 'Y' && ch != 'M') continue;

        final eyeRect = Rect.fromLTWH(
          ox + c * blockSize,
          oy + r * blockSize,
          blockSize + 0.1,
          blockSize + 0.1,
        );

        if (ch == 'M') {
          // Monocle eye for detective pose
          canvas.drawRect(eyeRect, eyePaint);
          final monoclePaint = Paint()
            ..color = const Color(0xFFFBBF24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawRect(eyeRect.inflate(blockSize * 0.2), monoclePaint);
        } else if (mood == ValtoMood.happy) {
          // Cheerful smiling crescent slit (^ ^)
          final slitRect = Rect.fromLTWH(
            eyeRect.left,
            eyeRect.top + eyeRect.height * 0.25,
            eyeRect.width,
            eyeRect.height * 0.35,
          );
          canvas.drawRect(slitRect, eyePaint);
        } else if (mood == ValtoMood.sleeping) {
          // Closed peaceful eye slit (- -)
          final slitRect = Rect.fromLTWH(
            eyeRect.left,
            eyeRect.top + eyeRect.height * 0.5,
            eyeRect.width,
            eyeRect.height * 0.25,
          );
          canvas.drawRect(slitRect, eyePaint);
        } else {
          // Standard vertical yellow cat eye
          canvas.drawRect(eyeRect, eyePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ValtoPosePainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.eyeColor != eyeColor;
  }
}
