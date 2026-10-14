import 'package:flutter/material.dart';

enum ValtoMood {
  vigilant,  // Classic seated vault guardian (alert vertical eyes & curled tail)
  playful,   // Waving paw greeting (prominent raised waving paw on left!)
  sleeping,  // Cozy cat loaf (distinct horizontal low loaf, paws tucked, sleeping eyes)
  happy,     // Victorious celebration (high-five paw & smiling crescent eyes)
  detective, // Inquisitive pose (cocked ear & gleaming golden monocle)
  peeking,   // Peeking pose (ears & paws resting over rim)
}

// Backward compatibility alias
typedef VowlMood = ValtoMood;
typedef VowlMascot = ValtoMascot;

/// Valto — The Signature Black Cat Mascot of VAULTED.
/// Built with 100% consistent 15x16 pixel geometry and palette across
/// dramatically distinct, human-readable poses:
/// - Vigilant (Upright sitting guardian)
/// - Playful (Prominent waving paw)
/// - Sleeping (Cozy horizontal low loaf)
/// - Happy (Victorious high paw & smiling eyes)
/// - Detective (Cocked ear & golden monocle)
/// - Peeking (Paws over ledge)
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

  // 1. VIGILANT: Classic Upright Sitting Cat (Alert Eyes, Tail Curled)
  static const List<String> _vigilantGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown between ears
    '.###########...', // Row 3: Forehead
    '#############..', // Row 4: Cheeks
    '###Y#####Y###..', // Row 5: Upper eye
    '###Y#####Y###..', // Row 6: Lower eye
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '...#######.....', // Row 9: Neck
    '...#######...#.', // Row 10: Chest & tail tip
    '...#######..###', // Row 11: Body & tail curve
    '..#########.###', // Row 12: Sitting body & tail
    '..#########.###', // Row 13: Front paws & tail base
    '..#########.##.', // Row 14: Paws & tail connection
    '...##########..', // Row 15: Bottom edge
  ];

  // 2. PLAYFUL / WAVING: Prominent Raised Waving Paw (Clear Asymmetric Silhouette!)
  static const List<String> _playfulGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown
    '.###########...', // Row 3: Forehead
    '#############..', // Row 4: Cheeks
    '###Y#####Y###..', // Row 5: Alert eyes
    '###Y#####Y###..', // Row 6: Alert eyes
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '..########.....', // Row 9: Neck
    '##..######...#.', // Row 10: PROMINENT WAVING PAW EXTENDED ON LEFT!
    '###.######..###', // Row 11: Waving arm & tail
    '.##.######..###', // Row 12: Waving arm & tail
    '..########.###.', // Row 13: Body
    '..########.##..', // Row 14: Base
    '...##########..', // Row 15: Bottom edge
  ];

  // 3. SLEEPING: Cozy Low Loaf (Dramatically Shorter Height, Paws Tucked In!)
  static const List<String> _sleepingGrid = [
    '...............', // Row 0: Resting low
    '...............', // Row 1: Resting low
    '...............', // Row 2: Resting low
    '...............', // Row 3: Resting low
    '..##.....##....', // Row 4: Relaxed low ears
    '.####...####...', // Row 5: Ear facets
    '.###########...', // Row 6: Head crown
    '#############..', // Row 7: Cheeks
    '###Y#####Y###..', // Row 8: Peaceful sleeping closed eyes (- -)
    '#############..', // Row 9: Snout resting
    '.#############.', // Row 10: Wide loaf shoulder
    '###############', // Row 11: Full low horizontal loaf!
    '###############', // Row 12: Full loaf
    '###############', // Row 13: Paws tucked underneath
    '.#############.', // Row 14: Tail wrapped along front
    '..###########..', // Row 15: Base
  ];

  // 4. HAPPY: Victorious Celebration (Left Paw High Five & Upward Smiling Eyes)
  static const List<String> _happyGrid = [
    '..##.....##....', // Row 0: Ear tips
    '.####...####...', // Row 1: Ear facets
    '.###########...', // Row 2: Crown
    '.###########...', // Row 3: Forehead
    '#############..', // Row 4: Cheeks
    '###Y#####Y###..', // Row 5: Smiling crescent eyes (^ ^)
    '#############..', // Row 6: Cheeks
    '#############..', // Row 7: Snout
    '.###########...', // Row 8: Chin
    '...#######.....', // Row 9: Neck
    '.#.#######....#', // Row 10: Celebratory high paw & tail held high!
    '###.######...##', // Row 11: Raised high paw
    '.##.######..###', // Row 12: Body & tail
    '..########.####', // Row 13: Body & tail
    '..########.###.', // Row 14: Base
    '...##########..', // Row 15: Bottom edge
  ];

  // 5. DETECTIVE: Cocked Ear & Gleaming Golden Monocle
  static const List<String> _detectiveGrid = [
    '..##...........', // Row 0: Left ear alert straight up
    '.####....##....', // Row 1: Right ear cocked curious
    '.####...####...', // Row 2: Crown
    '.###########...', // Row 3: Head slightly tilted
    '#############..', // Row 4: Cheeks
    '###Y#####M###..', // Row 5: Left eye sharp, Right eye with golden monocle 'M'
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

  // 6. PEEKING: Head & Paws Over Ledge
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
      case ValtoMood.playful:
        return _playfulGrid;
      case ValtoMood.sleeping:
        return _sleepingGrid;
      case ValtoMood.happy:
        return _happyGrid;
      case ValtoMood.detective:
        return _detectiveGrid;
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

    // Outer contour edge definition
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

    // Outer contour only
    canvas.drawPath(silhouettePath, borderPaint);

    // 2. Draw expressive eyes / monocle according to pose
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
