import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

/// VaultDoor3D — Authentic 3D Isometric Luxury Bank Vault.
///
/// Features:
/// 1. True 3D isometric perspective safe chassis with clean mathematical silhouette tangents
///    (smooth rounded corners, zero duplicate/inconsistent lines).
/// 2. Ultra-heavy mechanical combination steering wheel (1000ms high-inertia spin,
///    thick 3.2px forged spokes, dual-step counterweight handles, and heavy haptics).
/// 3. Unified door painter: slab, sunken well, dial, locking bolts, and edge thickness
///    are drawn in a single unified canvas pass (immune to compositor culling, never goes poof).
/// 4. Integrated 3D door thickness edge perfectly bounded to door height (never oversized).
/// 5. Recessed Swiss safety deposit box chamber with warm ambient illumination.
class VaultDoor3D extends StatefulWidget {
  final double size;
  final bool isUnlocking;
  final VoidCallback? onOpened;

  const VaultDoor3D({
    super.key,
    this.size = 190,
    this.isUnlocking = false,
    this.onOpened,
  });

  @override
  State<VaultDoor3D> createState() => _VaultDoor3DState();
}

class _VaultDoor3DState extends State<VaultDoor3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dialSpin;
  late Animation<double> _boltRetract;
  late Animation<double> _doorSwing;
  late Animation<double> _interiorGlow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    // Act 1: Ultra-heavy mechanical dial spin with massive inertia (0% - 48%, ~1000ms)
    _dialSpin = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.48, curve: Cubic(0.25, 0.1, 0.15, 1.0)),
    );

    // Act 2: Hardened steel locking bolts retract into door (44% - 56%, ~920ms - 1170ms)
    _boltRetract = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.44, 0.56, curve: Curves.easeInOutCubic),
    );

    // Act 3: Armored door swings open forward towards the user (54% - 100%)
    _doorSwing = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.54, 1.0, curve: Curves.easeInOutCubic),
    );

    // Act 4: Interior lighting warms up inside deposit box chamber (58% - 100%)
    _interiorGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onOpened?.call();
      }
    });

    if (widget.isUnlocking) {
      _triggerSequence();
    }
  }

  @override
  void didUpdateWidget(covariant VaultDoor3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocking != oldWidget.isUnlocking && widget.isUnlocking) {
      _triggerSequence();
    }
  }

  void _triggerSequence() {
    _controller.forward(from: 0.0);
    // Haptic feedback sequence:
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 460), () {
      if (mounted) HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 920), () {
      if (mounted) HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 1050), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final doorSize = s * 0.88;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: s * 1.12,
          height: s * 1.12,
          child: Center(
            // MASTER 3D ISOMETRIC PERSPECTIVE
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014) // Optical perspective depth
                ..rotateX(-0.05)          // Clean consistent pitch (~2.9 deg)
                ..rotateY(0.13),          // Clean consistent yaw (~7.5 deg)
              child: SizedBox(
                width: s,
                height: s,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1. SOLID 3D ISOMETRIC SAFE CHASSIS
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _Vault3DExtrudedChassisPainter(),
                      ),
                    ),

                    // 2. INDUSTRIAL BARREL HINGES (Anchored to stationary outer chassis frame)
                    _buildHinges(s),

                    // 3. RECESSED INTERIOR CHAMBER (Swiss Bank Safety Deposit Boxes)
                    _buildChamber(doorSize),

                    // 4. 3D SWINGING ARMORED DOOR (Swings forward in front of hinges & chamber!)
                    _buildSwingingDoor(doorSize),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Interior Chamber: Swiss bank dark titanium safety deposit box matrix
  Widget _buildChamber(double doorSize) {
    final glow = _interiorGlow.value;

    return Container(
      width: doorSize,
      height: doorSize,
      decoration: BoxDecoration(
        color: const Color(0xFF090908),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF262624),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: RadialGradient(
                center: const Alignment(0.1, -0.2),
                radius: 0.85,
                colors: [
                  Color.lerp(
                    const Color(0xFF141412),
                    const Color(0xFF2A261A),
                    glow,
                  )!,
                  const Color(0xFF070706),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size(doorSize, doorSize),
            painter: _SafetyDepositChamberPainter(glow: glow),
          ),
        ],
      ),
    );
  }

  /// Heavy 3D Armor Door: Swings forward towards user with authentic 3D depth slices
  Widget _buildSwingingDoor(double doorSize) {
    final swing = _doorSwing.value;
    // Rotates outward towards viewer: 0 to ~72 degrees
    final angle = swing * 1.25;
    final spinAngle = _dialSpin.value * (2.2 * pi);
    final boltRetract = _boltRetract.value;

    // Physical 3D door slab thickness: 11.0 depth units in local 3D space
    // Rendered via true 3D rigid body matrix slices. Zero perspective distortion,
    // zero spikes, 100% bounded to door's rounded corners at all angles!
    const totalDepth = 11.0;
    const slices = 10;

    final children = <Widget>[];

    // 1. Backing 3D depth slices (from back to front)
    if (swing > 0.005) {
      for (int i = slices; i >= 1; i--) {
        final t = i / slices;
        final zDepth = totalDepth * t;

        final fillColor = Color.lerp(
          const Color(0xFF10100E),
          const Color(0xFF22221E),
          1.0 - t * 0.5,
        )!;

        final strokeColor = i == slices
            ? const Color(0xFF6E6D67)
            : Color.lerp(
                const Color(0xFF2A2A26),
                const Color(0xFF484844),
                1.0 - t * 0.4,
              )!;

        children.add(
          Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(angle)
              ..translateByDouble(0.0, 0.0, zDepth, 1.0),
            child: SizedBox(
              width: doorSize,
              height: doorSize,
              child: CustomPaint(
                size: Size(doorSize, doorSize),
                painter: _DoorBackSlicePainter(
                  doorSize: doorSize,
                  fillColor: fillColor,
                  strokeColor: strokeColor,
                  isBackmost: i == slices,
                  boltRetract: boltRetract,
                ),
              ),
            ),
          ),
        );
      }
    }

    // 2. Front door plate with dial, spokes, hub, corner chamfers, and locking bolts
    children.add(
      Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(angle),
        child: SizedBox(
          width: doorSize,
          height: doorSize,
          child: CustomPaint(
            size: Size(doorSize, doorSize),
            painter: _UnifiedSwingingDoorPainter(
              doorSize: doorSize,
              spinAngle: spinAngle,
              boltRetract: boltRetract,
              swingAngle: angle,
              swingProgress: swing,
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }

  /// Left industrial cylindrical barrel hinges
  Widget _buildHinges(double s) {
    return Positioned(
      left: s * 0.06 - 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cylinderHinge(),
          SizedBox(height: s * 0.42),
          _cylinderHinge(),
        ],
      ),
    );
  }

  Widget _cylinderHinge() {
    return Container(
      width: 9,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF222220),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF8E8D8A),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(width: 5, height: 1.5, color: const Color(0xFF5A5A55)),
          Container(width: 5, height: 1.5, color: const Color(0xFF5A5A55)),
        ],
      ),
    );
  }
}

/// Unified Door Painter:
/// Combines the door plate, corner chamfers, locking bolts, sunken dial well,
/// full precision combination wheel, and bounded door thickness edge
/// into ONE single unified rendering pass.
/// Immune to compositor culling, never drops draw calls, never goes poof!
class _UnifiedSwingingDoorPainter extends CustomPainter {
  final double doorSize;
  final double spinAngle;
  final double boltRetract;
  final double swingAngle;
  final double swingProgress;

  _UnifiedSwingingDoorPainter({
    required this.doorSize,
    required this.spinAngle,
    required this.boltRetract,
    required this.swingAngle,
    required this.swingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = 10.0;
    final doorRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, doorSize, doorSize),
      const Radius.circular(r),
    );


    // 2. Main Front Door Slab Plate (at offset 0, 0)
    canvas.drawRRect(
      doorRRect,
      Paint()
        ..color = const Color(0xFF171715)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      doorRRect,
      Paint()
        ..color = const Color(0xFF8E8D8A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 3. Hairline Corner Chamfers & Decorative Inset Rectangles
    final strokeMid = Paint()
      ..color = const Color(0xFF383834)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final strokeEdge = Paint()
      ..color = const Color(0xFF52524D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const inset = 7.0;
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, doorSize - inset * 2, doorSize - inset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(outerRect, strokeMid);

    const inset2 = 13.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset2, inset2, doorSize - inset2 * 2, doorSize - inset2 * 2),
      const Radius.circular(5),
    );
    canvas.drawRRect(innerRect, strokeEdge);

    // Corner diagonal bevel lines
    canvas.drawLine(const Offset(inset, inset), const Offset(inset2, inset2), strokeMid);
    canvas.drawLine(Offset(doorSize - inset, inset), Offset(doorSize - inset2, inset2), strokeMid);
    canvas.drawLine(Offset(inset, doorSize - inset), Offset(inset2, doorSize - inset2), strokeMid);
    canvas.drawLine(Offset(doorSize - inset, doorSize - inset), Offset(doorSize - inset2, doorSize - inset2), strokeMid);

    // Precision corner rivets
    final rivetPaint = Paint()
      ..color = const Color(0xFF6E6D68)
      ..style = PaintingStyle.fill;
    const ro = 16.0;
    for (final pt in [
      const Offset(ro, ro),
      Offset(doorSize - ro, ro),
      Offset(ro, doorSize - ro),
      Offset(doorSize - ro, doorSize - ro),
    ]) {
      canvas.drawCircle(pt, 1.4, rivetPaint);
    }

    // 4. Hardened Steel Locking Pins (Retract smoothly into door edges)
    final ext = (1.0 - boltRetract) * 6.0;
    final pinFill = Paint()
      ..color = const Color(0xFF222220)
      ..style = PaintingStyle.fill;
    final pinStroke = Paint()
      ..color = const Color(0xFF8E8D8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Right pin
    final rightPin = RRect.fromRectAndRadius(
      Rect.fromLTWH(doorSize - 8, doorSize * 0.5 - 7, 8 + ext, 14),
      const Radius.circular(2),
    );
    canvas.drawRRect(rightPin, pinFill);
    canvas.drawRRect(rightPin, pinStroke);

    // Top pin
    final topPin = RRect.fromRectAndRadius(
      Rect.fromLTWH(doorSize * 0.5 - 7, -ext, 14, 8 + ext),
      const Radius.circular(2),
    );
    canvas.drawRRect(topPin, pinFill);
    canvas.drawRRect(topPin, pinStroke);

    // Bottom pin
    final bottomPin = RRect.fromRectAndRadius(
      Rect.fromLTWH(doorSize * 0.5 - 7, doorSize - 8, 14, 8 + ext),
      const Radius.circular(2),
    );
    canvas.drawRRect(bottomPin, pinFill);
    canvas.drawRRect(bottomPin, pinStroke);

    // 5. Sunken Circular Dial Well (Recessed into door plate)
    final center = Offset(doorSize / 2, doorSize / 2);
    final wellRadius = doorSize * 0.29;

    canvas.drawCircle(
      center,
      wellRadius,
      Paint()
        ..color = const Color(0xFF0F0F0E)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      wellRadius,
      Paint()
        ..color = const Color(0xFF282825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 6. Ultra-Heavy Precision Combination Steering Wheel
    final dialRadius = doorSize * 0.28;

    // Base drop shadow under wheel
    canvas.drawCircle(
      Offset(center.dx + 1.8, center.dy + 2.2),
      dialRadius - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill,
    );

    // Outer graduation track rings
    final dialRingPaint = Paint()
      ..color = const Color(0xFF4A4A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, dialRadius, dialRingPaint);
    canvas.drawCircle(center, dialRadius - 6.0, dialRingPaint);

    // 36 graduation tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF8E8D8A)
      ..strokeWidth = 1.0;
    const totalTicks = 36;
    for (int i = 0; i < totalTicks; i++) {
      final a = (i * 2 * pi / totalTicks) + spinAngle;
      final isMajor = i % 6 == 0;
      final outerR = dialRadius - 0.8;
      final innerR = isMajor ? dialRadius - 5.5 : dialRadius - 3.4;

      canvas.drawLine(
        Offset(center.dx + innerR * cos(a), center.dy + innerR * sin(a)),
        Offset(center.dx + outerR * cos(a), center.dy + outerR * sin(a)),
        tickPaint,
      );
    }

    // Inner dial face plate
    canvas.drawCircle(
      center,
      dialRadius - 7.0,
      Paint()
        ..color = const Color(0xFF1E1E1C)
        ..style = PaintingStyle.fill,
    );

    // Concentric hairline groove
    canvas.drawCircle(
      center,
      dialRadius - 13.0,
      Paint()
        ..color = const Color(0xFF383834)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // 3 Heavy forged steel steering handles (3.2px with polished spine highlight)
    final spokeBasePaint = Paint()
      ..color = const Color(0xFF6E6D68)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final spokeHighlightPaint = Paint()
      ..color = const Color(0xFFC8C7C2)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final spokeLength = dialRadius - 8.0;
    for (int i = 0; i < 3; i++) {
      final spokeAngle = spinAngle + (i * 2 * pi / 3);
      final spokeEnd = Offset(
        center.dx + spokeLength * cos(spokeAngle),
        center.dy + spokeLength * sin(spokeAngle),
      );

      // Spoke shadow
      canvas.drawLine(
        Offset(center.dx + 1.2, center.dy + 1.6),
        Offset(spokeEnd.dx + 1.2, spokeEnd.dy + 1.6),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..strokeWidth = 3.8
          ..strokeCap = StrokeCap.round,
      );

      // Forged steel core
      canvas.drawLine(center, spokeEnd, spokeBasePaint);
      // Silver spine highlight
      canvas.drawLine(center, spokeEnd, spokeHighlightPaint);

      // Machined counterweight knob
      canvas.drawCircle(
        spokeEnd,
        4.4,
        Paint()
          ..color = const Color(0xFF8E8D8A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      canvas.drawCircle(
        spokeEnd,
        3.8,
        Paint()
          ..color = const Color(0xFF222220)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        spokeEnd,
        1.4,
        Paint()
          ..color = const Color(0xFFD4D3CE)
          ..style = PaintingStyle.fill,
      );
    }

    // Central heavy hub boss
    const hubRadius = 12.0;
    canvas.drawCircle(
      center,
      hubRadius,
      Paint()
        ..color = const Color(0xFF131311)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      hubRadius,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF8E8D8A),
          VaultColors.accent,
          boltRetract,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Central rivet
    canvas.drawCircle(
      center,
      3.4,
      Paint()
        ..color = const Color(0xFF757470)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      1.4,
      Paint()
        ..color = const Color(0xFFE0DFDA)
        ..style = PaintingStyle.fill,
    );

  }

  @override
  bool shouldRepaint(covariant _UnifiedSwingingDoorPainter oldDelegate) => true;
}

/// Painter for the 3D isometric safe chassis:
/// Solid continuous rounded-rectangle extrusion with clean mathematical tangent contours.
/// Eliminates duplicate lines and inconsistencies.
class _Vault3DExtrudedChassisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 14.0;

    // Physical extrusion depth vector (proportional to -0.05 pitch and 0.13 yaw)
    const depthX = 13.0;
    const depthY = -5.5;
    const slices = 24;

    // 1. Draw solid smooth continuous 3D extrusion slices from back to front
    for (int i = slices; i >= 0; i--) {
      final t = i / slices;
      final ox = depthX * t;
      final oy = depthY * t;

      final color = Color.lerp(
        const Color(0xFF0B0B0A),
        const Color(0xFF181816),
        1.0 - (t * 0.70),
      )!;

      final sliceRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, w, h),
        const Radius.circular(r),
      );

      // Back-most silhouette edge
      if (i == slices) {
        canvas.drawRRect(
          sliceRRect,
          Paint()
            ..color = const Color(0xFF4E4E49)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
        );
      }

      canvas.drawRRect(
        sliceRRect,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // 2. Structural silhouette contour lines connecting front and back RRect
    final contourPaint = Paint()
      ..color = const Color(0xFF4E4E49)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Exact mathematical tangent points on the corner circles:
    final len = sqrt(depthX * depthX + depthY * depthY);
    final nx = -depthY / len; // ~0.389
    final ny = depthX / len;  // ~0.921

    // Top-left tangent seam connecting front to back
    final pTL = Offset(r - ny * r, r - nx * r);
    canvas.drawLine(pTL, pTL + const Offset(depthX, depthY), contourPaint);

    // Bottom-right tangent seam connecting front to back
    final pBR = Offset(w - r + ny * r, h - r + nx * r);
    canvas.drawLine(pBR, pBR + const Offset(depthX, depthY), contourPaint);

    // 3. Front Face Frame Plate (at t = 0)
    final frontRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(r),
    );

    // Front plate fill
    canvas.drawRRect(
      frontRRect,
      Paint()
        ..color = const Color(0xFF141412)
        ..style = PaintingStyle.fill,
    );

    // Front outer border
    canvas.drawRRect(
      frontRRect,
      Paint()
        ..color = const Color(0xFF4A4A45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Front inner bezel line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2.5, 2.5, w - 5, h - 5),
        const Radius.circular(r - 2.5),
      ),
      Paint()
        ..color = const Color(0xFF242422)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 4. Bolt mortise keeper pockets on top, right, bottom of frame
    final mortiseFill = Paint()
      ..color = const Color(0xFF090908)
      ..style = PaintingStyle.fill;
    final mortiseStroke = Paint()
      ..color = const Color(0xFF383834)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Top mortise
    final topMortise = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, 3.5), width: 18, height: 5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(topMortise, mortiseFill);
    canvas.drawRRect(topMortise, mortiseStroke);

    // Bottom mortise
    final bottomMortise = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h - 3.5), width: 18, height: 5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(bottomMortise, mortiseFill);
    canvas.drawRRect(bottomMortise, mortiseStroke);

    // Right mortise
    final rightMortise = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w - 3.5, h * 0.5), width: 5, height: 18),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rightMortise, mortiseFill);
    canvas.drawRRect(rightMortise, mortiseStroke);

    // Corner rivets
    final rivetPaint = Paint()
      ..color = const Color(0xFF5A5A55)
      ..style = PaintingStyle.fill;
    const ro = 7.0;
    for (final pt in [
      const Offset(ro, ro),
      Offset(w - ro, ro),
      Offset(ro, h - ro),
      Offset(w - ro, h - ro),
    ]) {
      canvas.drawCircle(pt, 1.2, rivetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Swiss bank dark safety deposit box matrix inside the open vault
class _SafetyDepositChamberPainter extends CustomPainter {
  final double glow;

  _SafetyDepositChamberPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final hairline = Paint()
      ..color = const Color(0xFF383834)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final keyholePaint = Paint()
      ..color = const Color(0xFF5A5A55)
      ..style = PaintingStyle.fill;

    const margin = 10.0;
    final w = size.width - margin * 2;
    final h = size.height - margin * 2;

    const rows = 4;
    const cols = 3;
    final cellW = w / cols;
    final cellH = h / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = margin + c * cellW;
        final y = margin + r * cellH;

        final boxRect = Rect.fromLTWH(x + 1.5, y + 1.5, cellW - 3, cellH - 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(boxRect, const Radius.circular(2)),
          hairline,
        );

        // Keyhole dot
        canvas.drawCircle(
          Offset(boxRect.center.dx - 8, boxRect.center.dy),
          1.0,
          keyholePaint,
        );
        // Box label line
        canvas.drawLine(
          Offset(boxRect.center.dx - 2, boxRect.center.dy),
          Offset(boxRect.center.dx + 10, boxRect.center.dy),
          hairline,
        );
      }
    }

    // Highlighted central open compartment with gold bullion / digital ledger
    final centerBox = Rect.fromLTWH(
      margin + cellW + 2,
      margin + cellH + 2,
      cellW - 4,
      cellH - 4,
    );

    // Warm titanium highlight on center asset box
    final goldStroke = Paint()
      ..color = const Color(0xFFC0A85C).withValues(alpha: 0.35 + glow * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawRRect(
      RRect.fromRectAndRadius(centerBox, const Radius.circular(2)),
      goldStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SafetyDepositChamberPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}

/// Painter for each 3D depth slice of the swinging vault door slab
class _DoorBackSlicePainter extends CustomPainter {
  final double doorSize;
  final Color fillColor;
  final Color strokeColor;
  final bool isBackmost;
  final double boltRetract;

  _DoorBackSlicePainter({
    required this.doorSize,
    required this.fillColor,
    required this.strokeColor,
    required this.isBackmost,
    required this.boltRetract,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = 10.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, doorSize, doorSize),
      const Radius.circular(r),
    );

    // Solid titanium slice body
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Fine contour stroke
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isBackmost ? 0.95 : 0.8,
    );

    // Hardened steel locking bolt pins on the back-most plate
    if (isBackmost) {
      final ext = (1.0 - boltRetract) * 3.5;
      for (final boltCenterRatio in [0.35, 0.65]) {
        final boltY = doorSize * boltCenterRatio;

        // Recessed pin socket hole
        final socketRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(doorSize - 1.0, boltY),
            width: 4.5,
            height: 12.0,
          ),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(
          socketRect,
          Paint()
            ..color = const Color(0xFF090908)
            ..style = PaintingStyle.fill,
        );

        // Cylindrical chrome locking bolt pin
        final pinRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            doorSize - 2.0,
            boltY - 4.5,
            2.5 + ext,
            9.0,
          ),
          const Radius.circular(1.2),
        );

        canvas.drawRRect(
          pinRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFF6A6A65),
                Color(0xFF9E9D97),
                Color(0xFF484844),
              ],
            ).createShader(pinRect.outerRect)
            ..style = PaintingStyle.fill,
        );

        canvas.drawRRect(
          pinRect,
          Paint()
            ..color = const Color(0xFFB4B3AD)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.65,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoorBackSlicePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.isBackmost != isBackmost ||
        oldDelegate.boltRetract != boltRetract;
  }
}

