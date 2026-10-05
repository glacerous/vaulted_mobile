import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

/// Accurate native Flutter port of the Hairline Parabolic Dish figure
/// (from https://hairline.lucasmarkes.com/figures by Lucas Marques).
/// 
/// Mathematical engine:
/// - Isometric axonometric projection with tunable angle & foreshortening.
/// - Base plinth with 36 compass rose calibration ticks.
/// - 2-axis gimbal fork with dual trunnion arms (Z = 46).
/// - True parabolic dish surface: Z' = r² / (4 * 17) - q_n with concentric depth rings.
/// - Tripod feed strut assembly with receiver feed horn.
/// - Fluid spring-damper physics responding to touch drag or programmatic targets.
class HairlineDish extends StatefulWidget {
  final double targetAzimuth;
  final double targetElevation;
  final double width;
  final double height;
  final bool interactive;
  final bool showTelemetry;
  final bool pulseBeam;
  final String? subtitle;
  final ValueChanged<DishAngle>? onAngleChanged;

  const HairlineDish({
    super.key,
    this.targetAzimuth = -20.0,
    this.targetElevation = 30.0,
    this.width = double.infinity,
    this.height = 240.0,
    this.interactive = true,
    this.showTelemetry = true,
    this.pulseBeam = true,
    this.subtitle,
    this.onAngleChanged,
  });

  @override
  State<HairlineDish> createState() => _HairlineDishState();
}

class DishAngle {
  final double azimuth;
  final double elevation;
  DishAngle(this.azimuth, this.elevation);
}

class _HairlineDishState extends State<HairlineDish>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0.0;

  // Spring physics states for Azimuth and Elevation
  double _azCurrent = -20.0;
  double _azVelocity = 0.0;
  double _azTarget = -20.0;

  double _elCurrent = 30.0;
  double _elVelocity = 0.0;
  double _elTarget = 30.0;

  // Spring parameters: stiffness k, damping c, mass m
  static const double _springK = 95.0;
  static const double _springC = 16.0;
  static const double _springM = 1.0;

  // Touch drag tracking
  Offset? _dragStartPos;
  double _dragStartAz = -20.0;
  double _dragStartEl = 30.0;

  // Beam pulse phase for radar wave effect
  double _pulsePhase = 0.0;

  @override
  void initState() {
    super.initState();
    _azCurrent = widget.targetAzimuth;
    _azTarget = widget.targetAzimuth;
    _elCurrent = widget.targetElevation;
    _elTarget = widget.targetElevation;

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(HairlineDish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetAzimuth != oldWidget.targetAzimuth ||
        widget.targetElevation != oldWidget.targetElevation) {
      _azTarget = widget.targetAzimuth;
      _elTarget = widget.targetElevation.clamp(5.0, 85.0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double now = elapsed.inMicroseconds / 1000000.0;
    if (_lastTime == 0.0) {
      _lastTime = now;
      return;
    }
    double dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    // Advance radar wave pulse
    _pulsePhase = (_pulsePhase + dt * 1.5) % 1.0;

    // Simulate Azimuth spring with sub-stepping for stability
    bool changed = false;
    const int subSteps = 4;
    final double subDt = dt / subSteps;

    for (int i = 0; i < subSteps; i++) {
      // Azimuth
      final double azDispl = _azCurrent - _azTarget;
      final double azAccel = (-_springK * azDispl - _springC * _azVelocity) / _springM;
      _azVelocity += azAccel * subDt;
      _azCurrent += _azVelocity * subDt;

      // Elevation
      final double elDispl = _elCurrent - _elTarget;
      final double elAccel = (-_springK * elDispl - _springC * _elVelocity) / _springM;
      _elVelocity += elAccel * subDt;
      _elCurrent += _elVelocity * subDt;
    }

    // Check if moving
    if ((_azCurrent - _azTarget).abs() > 0.01 ||
        _azVelocity.abs() > 0.02 ||
        (_elCurrent - _elTarget).abs() > 0.01 ||
        _elVelocity.abs() > 0.02) {
      changed = true;
    }

    if (changed || widget.pulseBeam) {
      setState(() {});
      widget.onAngleChanged?.call(DishAngle(_azCurrent, _elCurrent));
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.interactive) return;
    _dragStartPos = details.localPosition;
    _dragStartAz = _azCurrent;
    _dragStartEl = _elCurrent;
  }

  void _onPanUpdate(DragStartDetails? start, DragUpdateDetails details) {
    if (!widget.interactive || _dragStartPos == null) return;
    final delta = details.localPosition - _dragStartPos!;
    // Drag horizontally controls azimuth, drag vertically controls elevation
    _azTarget = _dragStartAz - (delta.dx * 0.7);
    _elTarget = (_dragStartEl - (delta.dy * 0.5)).clamp(5.0, 85.0);
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartPos = null;
  }

  @override
  Widget build(BuildContext context) {
    final normAz = ((_azCurrent % 360) + 360) % 360;
    final normEl = _elCurrent.clamp(5.0, 85.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: (d) => _onPanUpdate(null, d),
          onPanEnd: _onPanEnd,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _HairlineDishPainter(
                azimuth: _azCurrent,
                elevation: normEl,
                pulsePhase: widget.pulseBeam ? _pulsePhase : null,
              ),
            ),
          ),
        ),
        if (widget.showTelemetry)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VaultColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AZ ${normAz.toStringAsFixed(1).padLeft(5, '0')}°  ·  EL ${normEl.toStringAsFixed(1)}°',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.subtitle ?? 'DRAG TO AIM DISH',
                  style: VaultTypography.mono(
                    fontSize: 9,
                    color: VaultColors.ink3,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3D MATHEMATICAL WIREFRAME PAINTER FOR HAIRLINE DISH
// ---------------------------------------------------------------------------

class _HairlineDishPainter extends CustomPainter {
  final double azimuth;
  final double elevation;
  final double? pulsePhase;

  _HairlineDishPainter({
    required this.azimuth,
    required this.elevation,
    this.pulsePhase,
  });

  // Hairline Dish Constants
  static const double radius = 26.0;      // ge = 26
  static const double focalParam = 17.0;  // Ln = 17
  static const double depthOffset = 1.4;  // Js = 1.4
  static const double trunnionHeight = 46.0; // ir = 46
  static const double gimbalArmSpread = 31.0; // xe = 31
  static const double gimbalArmWidth = 5.0;   // we = 5
  static const double stemHeight = 10.0;      // Sr = 10
  static const double yokeHeight = 16.0;      // ma = 16

  // Dish rim depth: qn = radius^2 / (4 * Ln)
  static final double rimDepth = (radius * radius) / (4.0 * focalParam);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Axonometric isometric projection setup
    const double azAngle = 45.0 * math.pi / 180.0;
    const double kFactor = 0.5;
    final double cFactor = math.sqrt(1.0 - kFactor * kFactor);
    final double cosCam = math.cos(azAngle);
    final double sinCam = math.sin(azAngle);

    // Responsive scaling: standard stage is 400x320 with scale = 2.5
    final double scale = (size.width / 400.0) * 2.35;
    final double cx = size.width / 2.0;
    final double cy = size.height * 0.52;

    // 3D Point Projection to 2D Screen
    Offset project(double x, double y, double z) {
      final s = x * cosCam - y * sinCam;
      final h = x * sinCam + y * cosCam;
      return Offset(
        cx + scale * s,
        cy + scale * (h * kFactor - z * cFactor),
      );
    }

    // Vectors based on current azimuth & elevation
    final double azRad = azimuth * math.pi / 180.0;
    final double elRad = elevation * math.pi / 180.0;
    final double cosEl = math.cos(elRad);
    final double sinEl = math.sin(elRad);
    final double cosAz = math.cos(azRad);
    final double sinAz = math.sin(azRad);

    // Coordinate Frame:
    // h: horizontal pointing unit vector
    final hVec = [cosAz, sinAz, 0.0];
    // e: horizontal trunnion / pitch axis (perpendicular to h)
    final eVec = [-sinAz, cosAz, 0.0];
    // a: boresight / main dish pointing unit vector
    final aVec = [hVec[0] * cosEl, hVec[1] * cosEl, sinEl];
    // u: up vector perpendicular to dish axis
    final uVec = [-hVec[0] * sinEl, -hVec[1] * sinEl, cosEl];

    // Trunnion Center P0 = (0, 0, trunnionHeight)
    final trunnionCenter = [0.0, 0.0, trunnionHeight];

    // Point on dish helper: gn(L, depth, r, angle)
    List<double> pointOnDish(double depth, double r, double angle) {
      final cosAng = math.cos(angle);
      final sinAng = math.sin(angle);
      return [
        trunnionCenter[0] + aVec[0] * depth + eVec[0] * (r * cosAng) + uVec[0] * (r * sinAng),
        trunnionCenter[1] + aVec[1] * depth + eVec[1] * (r * cosAng) + uVec[1] * (r * sinAng),
        trunnionCenter[2] + aVec[2] * depth + eVec[2] * (r * cosAng) + uVec[2] * (r * sinAng),
      ];
    }

    // Paints
    final baseSilhouettePaint = Paint()
      ..color = const Color(0xFF1B1B19)
      ..style = PaintingStyle.fill;

    final plinthEdgePaint = Paint()
      ..color = VaultColors.hairline.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final baseTickPaint = Paint()
      ..color = VaultColors.ink3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final baseTickHiPaint = Paint()
      ..color = VaultColors.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final gimbalArmPaint = Paint()
      ..color = const Color(0xFF8E8D8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dishBackPaint = Paint()
      ..color = const Color(0xFF181816).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final dishCreasePaint = Paint()
      ..color = const Color(0xFF4A4A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final dishRimPaint = Paint()
      ..color = VaultColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;

    final tripodPaint = Paint()
      ..color = VaultColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final feedHornPaint = Paint()
      ..color = VaultColors.accent
      ..style = PaintingStyle.fill;

    // -----------------------------------------------------------------------
    // 1. BASE PLINTH (Octagonal/rounded foundation, Z = 0 to 5)
    // -----------------------------------------------------------------------
    final basePointsBottom = <Offset>[];
    final basePointsTop = <Offset>[];
    const double bHalf = 30.0;
    const double bCorner = 9.0;

    // Generate rounded base perimeter
    final basePerimeter = <List<double>>[
      [bHalf - bCorner, bHalf],
      [bHalf, bHalf - bCorner],
      [bHalf, -bHalf + bCorner],
      [bHalf - bCorner, -bHalf],
      [-bHalf + bCorner, -bHalf],
      [-bHalf, -bHalf + bCorner],
      [-bHalf, bHalf - bCorner],
      [-bHalf + bCorner, bHalf],
    ];

    for (final pt in basePerimeter) {
      basePointsBottom.add(project(pt[0], pt[1], 0.0));
      basePointsTop.add(project(pt[0], pt[1], 5.0));
    }

    // Draw base plinth hull
    final baseHull = _convexHull([...basePointsBottom, ...basePointsTop]);
    final basePath = _makePolygon(baseHull);
    canvas.drawPath(basePath, baseSilhouettePaint);
    canvas.drawPath(basePath, plinthEdgePaint);
    canvas.drawPath(_makePolygon(basePointsTop), plinthEdgePaint);

    // Base Compass Dial: 36 ticks around circle of radius 26 at Z = 5
    for (int i = 0; i < 36; i++) {
      final double theta = i / 36.0 * 2.0 * math.pi;
      final bool isCard = i % 9 == 0;
      final double rIn = isCard ? 24.5 : 25.2;
      final double rOut = isCard ? 27.2 : 26.2;
      final p1 = project(rIn * math.cos(theta), rIn * math.sin(theta), 5.0);
      final p2 = project(rOut * math.cos(theta), rOut * math.sin(theta), 5.0);
      canvas.drawLine(p1, p2, isCard ? plinthEdgePaint : baseTickPaint);

      if (isCard) {
        canvas.drawCircle(p2, 1.4, baseTickHiPaint);
      }
    }

    // Active Azimuth Target Indicator Dot on Compass Rose
    final azDotPos = project(26.0 * math.cos(azRad), 26.0 * math.sin(azRad), 5.0);
    canvas.drawCircle(
      azDotPos,
      2.8,
      Paint()
        ..color = VaultColors.accent
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      azDotPos,
      4.2,
      Paint()
        ..color = VaultColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // -----------------------------------------------------------------------
    // 2. PEDESTAL STEM & AZIMUTH ROTATING FORK (Z = 5 to stemHeight)
    // -----------------------------------------------------------------------
    final stemPtsBottom = <Offset>[];
    final stemPtsTop = <Offset>[];
    for (int i = 0; i < 20; i++) {
      final th = i / 20.0 * 2.0 * math.pi;
      stemPtsBottom.add(project(18.0 * math.cos(th), 18.0 * math.sin(th), 5.0));
      stemPtsTop.add(project(17.0 * math.cos(th), 17.0 * math.sin(th), stemHeight));
    }
    final stemHull = _convexHull([...stemPtsBottom, ...stemPtsTop]);
    canvas.drawPath(_makePolygon(stemHull), baseSilhouettePaint);
    canvas.drawPath(_makePolygon(stemPtsTop), plinthEdgePaint);

    // -----------------------------------------------------------------------
    // 3. DUAL GIMBAL SUPPORT FORKS (Left arm s = -1, Right arm s = +1)
    // -----------------------------------------------------------------------
    // Sort arms by depth to camera so back arm renders before dish, front after!
    final cameraDir = [cosCam * sinCam, cosCam * cosCam, cFactor];
    final armSide1Dot = (-1.0 * eVec[0]) * cameraDir[0] + (-1.0 * eVec[1]) * cameraDir[1];
    final armSides = armSide1Dot < 0 ? [-1.0, 1.0] : [1.0, -1.0];

    void drawGimbalArm(double side) {
      final armCenter = [
        trunnionCenter[0] + eVec[0] * side * gimbalArmSpread,
        trunnionCenter[1] + eVec[1] * side * gimbalArmSpread,
        trunnionHeight,
      ];

      // Arm runs from yoke base (Z = stemHeight) to trunnion pivot (Z = 46)
      final pBaseInner = project(
        eVec[0] * side * (gimbalArmSpread - gimbalArmWidth),
        eVec[1] * side * (gimbalArmSpread - gimbalArmWidth),
        yokeHeight,
      );
      final pBaseOuter = project(
        eVec[0] * side * (gimbalArmSpread + gimbalArmWidth),
        eVec[1] * side * (gimbalArmSpread + gimbalArmWidth),
        yokeHeight,
      );
      final pPivot = project(armCenter[0], armCenter[1], armCenter[2]);
      final pPivotOuter = project(
        armCenter[0] + eVec[0] * side * 2.0,
        armCenter[1] + eVec[1] * side * 2.0,
        armCenter[2],
      );

      // Arm strut path
      final armPath = Path()
        ..moveTo(pBaseInner.dx, pBaseInner.dy)
        ..lineTo(pPivot.dx, pPivot.dy)
        ..lineTo(pPivotOuter.dx, pPivotOuter.dy)
        ..lineTo(pBaseOuter.dx, pBaseOuter.dy)
        ..close();

      canvas.drawPath(
        armPath,
        Paint()
          ..color = const Color(0xFF1D1D1B)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(armPath, gimbalArmPaint);

      // Trunnion bearing ring
      canvas.drawCircle(pPivot, 3.2 * scale * 0.4, gimbalArmPaint);
      canvas.drawCircle(
        pPivot,
        1.5 * scale * 0.4,
        Paint()
          ..color = VaultColors.accent
          ..style = PaintingStyle.fill,
      );
    }

    // Draw background arm first
    drawGimbalArm(armSides[0]);

    // -----------------------------------------------------------------------
    // 4. PARABOLIC DISH REFLECTOR SURFACE & CONCENTRIC RINGS
    // -----------------------------------------------------------------------
    // Rim Circle: 72 points
    final rimPoints3D = <List<double>>[];
    final rimPoints2D = <Offset>[];
    const int rimSegments = 64;
    for (int i = 0; i < rimSegments; i++) {
      final angle = i / rimSegments * 2.0 * math.pi;
      // Rim is at depth Z' = 0 relative to rim plane (Z' = rimDepth - qn = 0)
      final pt = pointOnDish(0.0, radius, angle);
      rimPoints3D.add(pt);
      rimPoints2D.add(project(pt[0], pt[1], pt[2]));
    }

    // Parabolic back apex point (vertex of paraboloid)
    // Z' = -rimDepth
    final dishApex3D = pointOnDish(-rimDepth - depthOffset, 0.0, 0.0);
    final dishApex2D = project(dishApex3D[0], dishApex3D[1], dishApex3D[2]);

    // Draw filled dish back silhouette
    final dishHull = _convexHull([...rimPoints2D, dishApex2D]);
    canvas.drawPath(_makePolygon(dishHull), dishBackPaint);

    // Concentric Parabolic Depth Rings on Dish Surface
    const ringFractions = [0.25, 0.50, 0.72, 0.88];
    for (final f in ringFractions) {
      final r = radius * f;
      // Z' = r^2 / (4 * focalParam) - rimDepth
      final ringZ = (r * r) / (4.0 * focalParam) - rimDepth;
      final ringPts = <Offset>[];
      for (int i = 0; i < 48; i++) {
        final angle = i / 48.0 * 2.0 * math.pi;
        final pt = pointOnDish(ringZ, r, angle);
        ringPts.add(project(pt[0], pt[1], pt[2]));
      }
      canvas.drawPath(_makePolygon(ringPts), dishCreasePaint);
    }

    // Outer Rim Highlight
    canvas.drawPath(_makePolygon(rimPoints2D), dishRimPaint);

    // -----------------------------------------------------------------------
    // 5. TRIPOD SUBREFLECTOR STRUTS & RECEIVER FEED HORN
    // -----------------------------------------------------------------------
    // Apex Feed Horn is positioned in front along the boresight axis aVec:
    // focal point is at distance focalParam from paraboloid vertex
    // In our coordinate system, vertex is at -rimDepth, so feed is at (focalParam - rimDepth + 3)
    final feedDist = focalParam - rimDepth + 4.0;
    final feedHorn3D = pointOnDish(feedDist, 0.0, 0.0);
    final feedHorn2D = project(feedHorn3D[0], feedHorn3D[1], feedHorn3D[2]);

    // 3 Tripod struts connecting from rim (angles 90, 210, 330 deg) to feed horn
    const strutAngles = [90.0 * math.pi / 180.0, 210.0 * math.pi / 180.0, 330.0 * math.pi / 180.0];
    for (final angle in strutAngles) {
      final rimStrutPt = pointOnDish(0.0, radius, angle);
      final pRim = project(rimStrutPt[0], rimStrutPt[1], rimStrutPt[2]);
      canvas.drawLine(pRim, feedHorn2D, tripodPaint);
    }

    // Feed Horn Receiver Cone / Cap
    final feedHornRing = <Offset>[];
    for (int i = 0; i < 16; i++) {
      final th = i / 16.0 * 2.0 * math.pi;
      final pt = pointOnDish(feedDist - 1.2, 3.2, th);
      feedHornRing.add(project(pt[0], pt[1], pt[2]));
    }
    canvas.drawPath(_makePolygon(feedHornRing), feedHornPaint);
    canvas.drawCircle(feedHorn2D, 2.8, Paint()..color = VaultColors.ink);

    // -----------------------------------------------------------------------
    // 6. RADAR EMISSION BEAM / SIGNAL PULSES
    // -----------------------------------------------------------------------
    if (pulsePhase != null) {
      final double phase = pulsePhase!;
      // Draw 3 radiating wave rings expanding along the dish boresight vector
      for (int wave = 0; wave < 3; wave++) {
        final double waveFrac = (phase + wave * 0.33) % 1.0;
        final double waveDist = feedDist + 8.0 + waveFrac * 40.0;
        final double waveRadius = 4.0 + waveFrac * 18.0;
        final double opacity = (1.0 - waveFrac) * 0.45;

        final waveRing = <Offset>[];
        for (int i = 0; i < 24; i++) {
          final th = i / 24.0 * 2.0 * math.pi;
          final pt = pointOnDish(waveDist, waveRadius, th);
          waveRing.add(project(pt[0], pt[1], pt[2]));
        }

        canvas.drawPath(
          _makePolygon(waveRing),
          Paint()
            ..color = VaultColors.accent.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Draw foreground gimbal arm last so it overlaps the dish in front
    drawGimbalArm(armSides[1]);
  }

  // -------------------------------------------------------------------------
  // 2D CONVEX HULL & POLYGON HELPERS
  // -------------------------------------------------------------------------

  static List<Offset> _convexHull(List<Offset> pts) {
    if (pts.length <= 2) return List.from(pts);
    final points = List<Offset>.from(pts)
      ..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));

    double cross(Offset o, Offset a, Offset b) {
      return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    }

    final lower = <Offset>[];
    for (final p in points) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (final p in points.reversed) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return lower..addAll(upper);
  }

  static Path _makePolygon(List<Offset> pts, {bool close = true}) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    if (close) path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HairlineDishPainter oldDelegate) {
    return oldDelegate.azimuth != azimuth ||
        oldDelegate.elevation != elevation ||
        oldDelegate.pulsePhase != pulsePhase;
  }
}
