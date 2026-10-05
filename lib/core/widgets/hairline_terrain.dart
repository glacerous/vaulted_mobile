import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

/// Accurate native Flutter port of the Hairline 3D Terrain figure
/// (from https://hairline.lucasmarkes.com/figures by Lucas Marques).
/// 
/// Topographic 3D voxel terrain with dynamic height springs,
/// interactive cursor ripples, and telemetry dots.
class HairlineTerrain extends StatefulWidget {
  final double width;
  final double height;
  final bool interactive;
  final String? subtitle;

  const HairlineTerrain({
    super.key,
    this.width = double.infinity,
    this.height = 220.0,
    this.interactive = true,
    this.subtitle,
  });

  @override
  State<HairlineTerrain> createState() => _HairlineTerrainState();
}

class _TerrainCell {
  final int i;
  final int j;
  final double h0;
  double hCurrent;
  double hTarget;
  double velocity = 0.0;

  _TerrainCell({
    required this.i,
    required this.j,
    required this.h0,
  })  : hCurrent = h0,
        hTarget = h0;
}

class _HairlineTerrainState extends State<HairlineTerrain>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0.0;

  static const int _gridSize = 9; // Ye = 9
  static const double _cellPitch = 14.0; // ee = 14
  static const double _maxHeight = 54.0; // Xr = 58

  late List<_TerrainCell> _cells;
  _TerrainCell? _hoveredCell;
  Offset? _touchWorldPos;

  // Spring physics
  static const double _springK = 85.0;
  static const double _springC = 14.0;

  @override
  void initState() {
    super.initState();
    _initGrid();
    _ticker = createTicker(_onTick)..start();
  }

  void _initGrid() {
    _cells = [];
    for (int l = 0; l <= 2 * (_gridSize - 1); l++) {
      for (int m = 0; m < _gridSize; m++) {
        final int y = l - m;
        if (y < 0 || y >= _gridSize) continue;
        final double bNorm = m / (_gridSize - 1.0);
        final double xNorm = y / (_gridSize - 1.0);

        // Twin Gaussian elevation formula from Hairline
        final double term1 = 25.0 *
            math.exp(-(math.pow(bNorm - 0.22, 2) + math.pow(xNorm - 0.74, 2)) / 0.07);
        final double term2 = 12.0 *
            math.exp(-(math.pow(bNorm - 0.80, 2) + math.pow(xNorm - 0.26, 2)) / 0.035);
        final double baseH = 4.0 + term1 + term2;

        _cells.add(_TerrainCell(i: m, j: y, h0: baseH));
      }
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

    bool moving = false;
    for (final cell in _cells) {
      if (_touchWorldPos != null) {
        final cx = (cell.i + 0.5) * _cellPitch;
        final cy = (cell.j + 0.5) * _cellPitch;
        final dist = math.sqrt(
          math.pow(cx - _touchWorldPos!.dx, 2) + math.pow(cy - _touchWorldPos!.dy, 2),
        );
        // Ripple effect
        final normDist = dist / (_cellPitch * 2.8);
        final ripple = _rippleProfile(normDist);
        cell.hTarget = _maxHeight * ripple;
      } else {
        cell.hTarget = cell.h0;
      }

      // Spring step
      final displ = cell.hCurrent - cell.hTarget;
      final accel = -_springK * displ - _springC * cell.velocity;
      cell.velocity += accel * dt;
      cell.hCurrent += cell.velocity * dt;

      if (displ.abs() > 0.02 || cell.velocity.abs() > 0.05) {
        moving = true;
      }
    }

    if (moving) {
      setState(() {});
    }
  }

  static double _rippleProfile(double t) {
    if (t <= 0) return 1.0;
    if (t <= 0.417) return 1.0 - t / 0.417 * 0.6875;
    if (t <= 1.0) return 0.3125 - (t - 0.417) / 0.583 * 0.2185;
    return 0.094;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.interactive) return;
    // Unproject 2D screen coordinate back to terrain plane (Z = 0)
    final pos = details.localPosition;
    const double azAngle = 45.0 * math.pi / 180.0;
    const double kFactor = 0.5;
    final double cosCam = math.cos(azAngle);
    final double sinCam = math.sin(azAngle);
    final double scale = (size.width / 400.0) * 1.58;
    final double cx = size.width / 2.0;
    final double cy = size.height * 0.52;

    final double sx = (pos.dx - cx) / scale;
    final double sy = (pos.dy - cy) / scale / kFactor;

    final double worldX = sx * cosCam + sy * sinCam;
    final double worldY = -sx * sinCam + sy * cosCam;

    _touchWorldPos = Offset(worldX, worldY);

    final int gi = (worldX / _cellPitch).floor().clamp(0, _gridSize - 1);
    final int gj = (worldY / _cellPitch).floor().clamp(0, _gridSize - 1);
    _hoveredCell = _cells.firstWhere(
      (c) => c.i == gi && c.j == gj,
      orElse: () => _cells.first,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    _touchWorldPos = null;
    _hoveredCell = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, widget.height);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onPanStart: (d) => _onPanUpdate(
              DragUpdateDetails(globalPosition: d.globalPosition, localPosition: d.localPosition),
              size,
            ),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: CustomPaint(
                size: size,
                painter: _HairlineTerrainPainter(
                  cells: _cells,
                  hoveredCell: _hoveredCell,
                ),
              ),
            ),
          ),
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
                      _hoveredCell != null
                          ? 'CELL ${_hoveredCell!.i} · ${_hoveredCell!.j}  ·  ELEV ${_hoveredCell!.hCurrent.toStringAsFixed(1)}'
                          : 'TOPOGRAPHIC DEPTH MAP',
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
                  widget.subtitle ?? 'TOUCH TO PROBE SURFACE',
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
    });
  }
}

class _HairlineTerrainPainter extends CustomPainter {
  final List<_TerrainCell> cells;
  final _TerrainCell? hoveredCell;

  _HairlineTerrainPainter({
    required this.cells,
    this.hoveredCell,
  });

  static const int _gridSize = 9;
  static const double _cellPitch = 14.0;
  static const double _pillarWidth = 10.5;
  static const double _plinthDepth = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const double azAngle = 45.0 * math.pi / 180.0;
    const double kFactor = 0.5;
    final double cFactor = math.sqrt(1.0 - kFactor * kFactor);
    final double cosCam = math.cos(azAngle);
    final double sinCam = math.sin(azAngle);

    final double scale = (size.width / 400.0) * 1.55;
    final double cx = size.width / 2.0;
    final double cy = size.height * 0.52;

    Offset project(double x, double y, double z) {
      final s = x * cosCam - y * sinCam;
      final h = x * sinCam + y * cosCam;
      return Offset(
        cx + scale * s,
        cy + scale * (h * kFactor - z * cFactor),
      );
    }

    // 1. Draw Base Plinth (-6, -6 to Cn+6, Cn+6)
    const double plinthMin = -6.0;
    final double plinthMax = _gridSize * _cellPitch + 6.0;

    final plinthBottom = <Offset>[
      project(plinthMin, plinthMin, -_plinthDepth),
      project(plinthMax, plinthMin, -_plinthDepth),
      project(plinthMax, plinthMax, -_plinthDepth),
      project(plinthMin, plinthMax, -_plinthDepth),
    ];
    final plinthTop = <Offset>[
      project(plinthMin, plinthMin, 0.0),
      project(plinthMax, plinthMin, 0.0),
      project(plinthMax, plinthMax, 0.0),
      project(plinthMin, plinthMax, 0.0),
    ];

    final plinthHull = _convexHull([...plinthBottom, ...plinthTop]);
    canvas.drawPath(
      _makePolygon(plinthHull),
      Paint()
        ..color = const Color(0xFF191917)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      _makePolygon(plinthHull),
      Paint()
        ..color = VaultColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawPath(
      _makePolygon(plinthTop),
      Paint()
        ..color = VaultColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. Sort pillars back-to-front by diagonal (i + j)
    final sortedCells = List<_TerrainCell>.from(cells)
      ..sort((a, b) => (a.i + a.j).compareTo(b.i + b.j));

    final pillarFill = Paint()
      ..color = const Color(0xFF1D1D1B)
      ..style = PaintingStyle.fill;

    final pillarStroke = Paint()
      ..color = const Color(0xFF4A4A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final pillarHiStroke = Paint()
      ..color = VaultColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (final cell in sortedCells) {
      final double px = cell.i * _cellPitch + (_cellPitch - _pillarWidth) / 2.0;
      final double py = cell.j * _cellPitch + (_cellPitch - _pillarWidth) / 2.0;
      final double h = math.max(0.8, cell.hCurrent);

      final p0 = project(px, py, 0.0);
      final p1 = project(px + _pillarWidth, py, 0.0);
      final p2 = project(px + _pillarWidth, py + _pillarWidth, 0.0);
      final p3 = project(px, py + _pillarWidth, 0.0);

      final t0 = project(px, py, h);
      final t1 = project(px + _pillarWidth, py, h);
      final t2 = project(px + _pillarWidth, py + _pillarWidth, h);
      final t3 = project(px, py + _pillarWidth, h);

      final hull = _convexHull([p0, p1, p2, p3, t0, t1, t2, t3]);
      final topQuad = [t0, t1, t2, t3];

      final isHi = h > 28.0 || (hoveredCell != null && hoveredCell!.i == cell.i && hoveredCell!.j == cell.j);

      canvas.drawPath(_makePolygon(hull), pillarFill);
      canvas.drawPath(_makePolygon(hull), isHi ? pillarHiStroke : pillarStroke);
      canvas.drawPath(_makePolygon(topQuad), isHi ? pillarHiStroke : pillarStroke);

      // Micro telemetry dots on top of active or hovered pillar
      if (isHi) {
        final cx = px + _pillarWidth / 2.0;
        final cy = py + _pillarWidth / 2.0;
        for (int di = -1; di <= 1; di++) {
          for (int dj = -1; dj <= 1; dj++) {
            final dotPt = project(cx + di * 2.2, cy + dj * 2.2, h);
            canvas.drawCircle(
              dotPt,
              di == 0 && dj == 0 ? 1.5 : 0.9,
              Paint()
                ..color = di == 0 && dj == 0 ? VaultColors.ink : VaultColors.accent
                ..style = PaintingStyle.fill,
            );
          }
        }
      }
    }
  }

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
  bool shouldRepaint(_HairlineTerrainPainter oldDelegate) => true;
}
