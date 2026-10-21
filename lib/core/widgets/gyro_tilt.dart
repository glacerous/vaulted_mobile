import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';

/// Membuat [child] miring 3D mengikuti rotasi HP (sensor gyroscope),
/// lengkap dengan kilau yang bergeser seperti kartu holo.
/// Subscription sensor hanya aktif selama widget ini tampil.
class GyroTilt extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool showStatus;

  const GyroTilt({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.showStatus = true,
  });

  @override
  State<GyroTilt> createState() => _GyroTiltState();
}

class _GyroTiltState extends State<GyroTilt> {
  static const double _maxTilt = 0.40; // radian

  StreamSubscription<GyroscopeEvent>? _sub;
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  DateTime? _lastEvent;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (kIsWeb) return; // gyroscope hanya tersedia di perangkat asli
    try {
      _sub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
          .listen(
            (GyroscopeEvent e) {
              final now = DateTime.now();
              final dt = _lastEvent == null
                  ? 0.02
                  : (now.difference(_lastEvent!).inMicroseconds / 1000000.0)
                        .clamp(0.001, 0.1)
                        .toDouble();
              _lastEvent = now;

              // Integrasi kecepatan sudut (rad/s) menjadi sudut miring, lalu perlahan kembali ke 0
              final decay = exp(-3.0 * dt);
              final tx = ((_tilt.value.dx + e.y * dt) * decay)
                  .clamp(-_maxTilt, _maxTilt)
                  .toDouble();
              final ty = ((_tilt.value.dy + e.x * dt) * decay)
                  .clamp(-_maxTilt, _maxTilt)
                  .toDouble();
              _tilt.value = Offset(tx, ty);

              if (!_active && mounted) setState(() => _active = true);
            },
            onError: (_) {},
            cancelOnError: false,
          );
    } catch (_) {
      // Perangkat tanpa gyroscope: efek tilt dilewati
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String label;
    if (_active) {
      label = 'GYROSCOPE ACTIVE · tilt your phone';
    } else if (kIsWeb) {
      label = 'GYROSCOPE N/A ON WEB · use a real device';
    } else {
      label = 'GYROSCOPE WAITING FOR SENSOR...';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<Offset>(
          valueListenable: _tilt,
          child: widget.child,
          builder: (context, t, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(-t.dy)
                ..rotateY(t.dx),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: Offset(-t.dx * 40, 8 + t.dy * 40),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    child!,
                    // Kilau yang bergeser mengikuti kemiringan
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(
                                  -1.5 + t.dx * 4,
                                  -1.5 + t.dy * 4,
                                ),
                                end: Alignment(1.5 + t.dx * 4, 1.5 + t.dy * 4),
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.35, 0.5, 0.65],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.showStatus) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screen_rotation_rounded,
                size: 13,
                color: _active ? VaultColors.pos : VaultColors.ink3,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: VaultTypography.mono(
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  color: _active ? VaultColors.pos : VaultColors.ink3,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
