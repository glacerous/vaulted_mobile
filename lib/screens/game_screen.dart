import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

/// ============================================================================
/// VALTO'S VAULT RUSH — game aksi real-time
///
/// Valto (kucing penjaga vault) menggeser badan kiri-kanan untuk MENANGKAP aset
/// berharga yang jatuh dan MENGHINDARI jebakan (scam, bom, rug pull).
/// Makin lama makin cepat. Nyawa habis = game over.
///
/// Semua angka balance ada di GameConfig supaya gampang diubah saat demo.
/// ============================================================================
class GameConfig {
  static const int startingLives = 3;
  static const int comboForMultiplier = 4; // tiap 4 tangkapan beruntun, x naik
  static const int maxMultiplier = 5;
  static const double baseFallSpeed = 290; // px/detik (lebih kencang & menantang)
  static const double maxFallSpeed = 720;
  static const double baseSpawnInterval = 0.62; // detik (tempo lebih rapat)
  static const double minSpawnInterval = 0.22;
  static const double difficultyRampSeconds =
      48; // waktu sampai kesulitan puncak (48 detik)
  static const double invulnSeconds = 0.75; // kebal sesaat setelah kena
  static const double magnetSeconds = 4.0;
  static const double slowSeconds = 4.0;
}

enum DropKind { gold, gem, cash, card, heart, magnet, slow, bomb, scam }

class _DropSpec {
  final String label;
  final String glyph;
  final int points;
  final Color color;
  final bool bad;
  const _DropSpec(this.label, this.glyph, this.points, this.color, this.bad);
}

const Map<DropKind, _DropSpec> _specs = {
  DropKind.cash: _DropSpec('CASH', '\$', 10, Color(0xFF16A34A), false),
  DropKind.gold: _DropSpec('GOLD', '▬', 25, Color(0xFFC0A85C), false),
  DropKind.gem: _DropSpec('GEM', '◆', 60, Color(0xFF38BDF8), false),
  DropKind.card: _DropSpec('SKIN', '★', 120, Color(0xFFA855F7), false),
  DropKind.heart: _DropSpec('LIFE', '♥', 0, Color(0xFFDC2626), false),
  DropKind.magnet: _DropSpec('MAGNET', 'U', 0, Color(0xFF2563EB), false),
  DropKind.slow: _DropSpec('SLOW', '❄', 0, Color(0xFF0EA5E9), false),
  DropKind.bomb: _DropSpec('BOMB', '✹', 0, Color(0xFF141413), true),
  DropKind.scam: _DropSpec('SCAM', '☠', 0, Color(0xFF7F1D1D), true),
};

/// Engine renderer sprite pixel art 8x8 yang tajam dan stylish untuk Valto's Vault Rush
class PixelSprite {
  PixelSprite._();

  static const Map<DropKind, List<String>> _matrices = {
    DropKind.gold: [
      '..BBBB..',
      '.BYYYYB.',
      'BYWYYYGB',
      'BGGVGGGB',
      'BGGVGGGB',
      'BDGGGGDB',
      '.BBBBBB.',
      '........',
    ],
    DropKind.cash: [
      '.BBBBBB.',
      'BLLEELLB',
      'BLEWWELL',
      'BLEEWELB',
      'BLEWWELL',
      'BLEWEELB',
      'BLLEELLB',
      '.BBBBBB.',
    ],
    DropKind.gem: [
      '..BBBB..',
      '.BCCCCB.',
      'BCWCCCCB',
      'BDCCCCDB',
      '.BDCCDB.',
      '..BEEB..',
      '...BB...',
      '........',
    ],
    DropKind.card: [
      '.BBBBBB.',
      'BPPPPPPB',
      'BPVYVPB.',
      'BPYYYYPB',
      'BPYYYYPB',
      'BPVYVPB.',
      'BPPPPPPB',
      '.BBBBBB.',
    ],
    DropKind.heart: [
      '.BB..BB.',
      'BRWB.BRRB',
      'BRWRRRRD',
      'BRRRRRRD',
      '.BRRRRD.',
      '..BRRD..',
      '...BB...',
      '........',
    ],
    DropKind.magnet: [
      'LW....WL',
      'BR....RB',
      'BR....RB',
      'BS....SB',
      'BS....SB',
      '.BSSSSB.',
      '..BBBB..',
      '........',
    ],
    DropKind.slow: [
      'BGGGGGGB',
      '.BCCCCB.',
      '..BCCB..',
      '...BB...',
      '..BCCB..',
      '.BCWWCB.',
      'BGGGGGGB',
      '.BBBBBB.',
    ],
    DropKind.bomb: [
      '.....SSF',
      '....FF..',
      '..BBBB..',
      '.BKWKB..',
      'BKKKKKKB',
      'BKKKKKKB',
      '.BKKKKB.',
      '..BBBB..',
    ],
    DropKind.scam: [
      '..BBBB..',
      '.BWWWWWB.',
      'BWRWWRWB',
      'BWRWWRWB',
      'BWWBBWWB',
      '.BWWWWWB.',
      '..BKBKB..',
      '..BBBBB..',
    ],
  };

  static Map<String, Color> _getPalette(DropKind kind, {double anim = 0}) {
    switch (kind) {
      case DropKind.gold:
        return {
          'B': const Color(0xFF6B4E12),
          'Y': const Color(0xFFFDE047),
          'W': const Color(0xFFFFFBEB),
          'G': const Color(0xFFEAB308),
          'D': const Color(0xFFCA8A04),
          'V': const Color(0xFF854D0E),
        };
      case DropKind.cash:
        return {
          'B': const Color(0xFF064E3B),
          'L': const Color(0xFF86EFAC),
          'E': const Color(0xFF16A34A),
          'W': const Color(0xFFFFFFFF),
        };
      case DropKind.gem:
        return {
          'B': const Color(0xFF075985),
          'W': const Color(0xFFFFFFFF),
          'C': const Color(0xFF38BDF8),
          'D': const Color(0xFF0284C7),
          'E': const Color(0xFF0C4A6E),
        };
      case DropKind.card:
        return {
          'B': const Color(0xFFFBBF24),
          'P': const Color(0xFF6B21A8),
          'V': const Color(0xFFA855F7),
          'Y': const Color(0xFFFDE047),
        };
      case DropKind.heart:
        return {
          'B': const Color(0xFF581C1C),
          'R': const Color(0xFFEF4444),
          'W': const Color(0xFFFFFFFF),
          'D': const Color(0xFFB91C1C),
        };
      case DropKind.magnet:
        final spark = (math.sin(anim * 14) > 0)
            ? const Color(0xFF60A5FA)
            : const Color(0xFF93C5FD);
        return {
          'B': const Color(0xFF0F172A),
          'R': const Color(0xFFEF4444),
          'S': const Color(0xFFCBD5E1),
          'L': spark,
          'W': const Color(0xFFFFFFFF),
        };
      case DropKind.slow:
        return {
          'B': const Color(0xFF0C4A6E),
          'G': const Color(0xFFC0A85C),
          'C': const Color(0xFF38BDF8),
          'W': const Color(0xFFE0F2FE),
        };
      case DropKind.bomb:
        final sparkColor = (math.sin(anim * 22) > 0)
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
        return {
          'S': sparkColor,
          'F': const Color(0xFF92400E),
          'B': const Color(0xFF09090B),
          'K': const Color(0xFF27272A),
          'W': const Color(0xFF71717A),
        };
      case DropKind.scam:
        final eyeGlow = (math.sin(anim * 10) > 0)
            ? const Color(0xFFEF4444)
            : const Color(0xFFB91C1C);
        return {
          'B': const Color(0xFF7F1D1D),
          'W': const Color(0xFFF8FAFC),
          'R': eyeGlow,
          'K': const Color(0xFF450A0A),
        };
    }
  }

  static void paint(
    Canvas canvas,
    Offset center,
    DropKind kind,
    double size, {
    double anim = 0,
    double opacity = 1.0,
    bool isShadow = false,
  }) {
    final matrix = _matrices[kind]!;
    final palette = _getPalette(kind, anim: anim);
    final pixelSize = size / 8.0;
    final startX = center.dx - size / 2.0;
    final startY = center.dy - size / 2.0;

    for (int y = 0; y < 8; y++) {
      final row = matrix[y];
      for (int x = 0; x < 8; x++) {
        final char = row[x];
        if (char == '.') continue;
        final color = isShadow ? const Color(0xFF141413) : palette[char];
        if (color == null) continue;
        final paint = Paint()
          ..color = isShadow
              ? color.withValues(alpha: 0.14 * opacity)
              : (opacity < 1.0
                  ? color.withValues(alpha: color.a * opacity)
                  : color)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            startX + x * pixelSize,
            startY + y * pixelSize,
            pixelSize + 0.35,
            pixelSize + 0.35,
          ),
          paint,
        );
      }
    }
  }
}

class PixelSpriteWidget extends StatelessWidget {
  final DropKind kind;
  final double size;
  final double opacity;
  final double anim;

  const PixelSpriteWidget({
    super.key,
    required this.kind,
    this.size = 24,
    this.opacity = 1.0,
    this.anim = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelWidgetPainter(kind: kind, opacity: opacity, anim: anim),
    );
  }
}

class _PixelWidgetPainter extends CustomPainter {
  final DropKind kind;
  final double opacity;
  final double anim;

  _PixelWidgetPainter({
    required this.kind,
    required this.opacity,
    required this.anim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    PixelSprite.paint(
      canvas,
      Offset(size.width / 2, size.height / 2),
      kind,
      size.width,
      opacity: opacity,
      anim: anim,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelWidgetPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.opacity != opacity ||
      oldDelegate.anim != anim;
}

class _Drop {
  DropKind kind;
  double x, y;
  double vy;
  double radius;
  double spin;
  double phase;
  _Drop(this.kind, this.x, this.y, this.vy, this.radius, this.phase) : spin = 0;
}

class _Particle {
  double x, y, vx, vy, life, maxLife, size;
  Color color;
  String? text;
  _Particle(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.life,
    this.size,
    this.color, {
    this.text,
  }) : maxLife = life;
}

enum _Phase { ready, playing, paused, over }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  // Ukuran arena (diisi dari LayoutBuilder)
  Size _arena = Size.zero;

  // State permainan
  _Phase _phase = _Phase.ready;
  final List<_Drop> _drops = [];
  final List<_Particle> _particles = [];
  double _playerX = 0; // pusat Valto
  double _targetX = 0;
  double _playerVx = 0;
  double _elapsed = 0;
  double _spawnTimer = 0;
  int _score = 0;
  int _best = 0;
  int _lives = GameConfig.startingLives;
  int _combo = 0;
  int _maxCombo = 0;
  int _caught = 0;
  int _missed = 0;
  double _invuln = 0;
  double _magnet = 0;
  double _slow = 0;
  double _shake = 0;
  double _flash = 0; // 1 = flash merah
  bool _newBest = false;

  // Ukuran visual
  static const double _playerW = 78;
  static const double _playerH = 66;

  ui.Image? _valto;

  // HUD diperbarui lewat notifier supaya tidak rebuild seluruh widget tiap frame
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadSprite();
  }

  Future<void> _loadSprite() async {
    try {
      final data = await rootBundle.load('assets/images/valto_vigilant.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _valto = frame.image);
    } catch (_) {
      // Fallback: Valto digambar dengan canvas jika aset gagal dimuat.
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _valto?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- kontrol

  void _startGame() {
    HapticFeedback.mediumImpact();
    _drops.clear();
    _particles.clear();
    _elapsed = 0;
    _spawnTimer = 0.4;
    _score = 0;
    _lives = GameConfig.startingLives;
    _combo = 0;
    _maxCombo = 0;
    _caught = 0;
    _missed = 0;
    _invuln = 0;
    _magnet = 0;
    _slow = 0;
    _shake = 0;
    _flash = 0;
    _newBest = false;
    _playerX = _arena.width / 2;
    _targetX = _playerX;
    _playerVx = 0;
    setState(() => _phase = _Phase.playing);
  }

  void _togglePause() {
    if (_phase == _Phase.playing) {
      setState(() => _phase = _Phase.paused);
    } else if (_phase == _Phase.paused) {
      setState(() => _phase = _Phase.playing);
    }
  }

  void _dragTo(double dx) {
    if (_phase != _Phase.playing) return;
    _targetX = dx.clamp(_playerW / 2, _arena.width - _playerW / 2);
  }

  // -------------------------------------------------------------- game loop

  void _onTick(Duration now) {
    final dtRaw = (now - _lastTick).inMicroseconds / 1e6;
    _lastTick = now;
    final dt = dtRaw.clamp(0.0, 0.05); // cegah lompatan saat lag

    if (_phase == _Phase.playing && _arena != Size.zero) {
      _update(dt);
    } else {
      _updateParticles(dt); // efek tetap bergerak di layar game over
      _shake = math.max(0, _shake - dt * 3);
      _flash = math.max(0, _flash - dt * 2.5);
    }
    _frame.value++;
  }

  double get _difficulty =>
      (_elapsed / GameConfig.difficultyRampSeconds).clamp(0.0, 1.0);

  int get _multiplier => math.min(
    GameConfig.maxMultiplier,
    1 + _combo ~/ GameConfig.comboForMultiplier,
  );

  void _update(double dt) {
    _elapsed += dt;
    final d = _difficulty;

    // Gerak Valto: mengejar jari dengan sedikit inersia (terasa "hidup")
    final diff = _targetX - _playerX;
    final accel = diff * 38 - _playerVx * 9;
    _playerVx += accel * dt;
    _playerX += _playerVx * dt;
    _playerX = _playerX.clamp(_playerW / 2, _arena.width - _playerW / 2);

    // Timer efek
    _invuln = math.max(0, _invuln - dt);
    _magnet = math.max(0, _magnet - dt);
    _slow = math.max(0, _slow - dt);
    _shake = math.max(0, _shake - dt * 3);
    _flash = math.max(0, _flash - dt * 2.5);

    // Spawn
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawn();
      final interval = ui.lerpDouble(
        GameConfig.baseSpawnInterval,
        GameConfig.minSpawnInterval,
        d,
      )!;
      _spawnTimer = interval * (0.7 + _rng.nextDouble() * 0.6);
    }

    final slowFactor = _slow > 0 ? 0.55 : 1.0;
    final playerTop = _arena.height - _playerH - 14;
    final trayTop = playerTop - 12;
    final playerRect = Rect.fromLTWH(
      _playerX - (_playerW + 12) / 2,
      trayTop,
      _playerW + 12,
      _playerH + 12,
    );

    for (final drop in List<_Drop>.from(_drops)) {
      drop.y += drop.vy * slowFactor * dt;
      drop.spin += dt * (drop.kind == DropKind.bomb ? 3 : 1.4);

      // Pada tingkat kesulitan menengah-tinggi, bom & scam bergeser zig-zag
      if (_specs[drop.kind]!.bad && d > 0.25) {
        drop.x += math.sin(_elapsed * 4.2 + drop.phase) * (36.0 * d) * dt;
        drop.x = drop.x.clamp(drop.radius + 6, _arena.width - drop.radius - 6);
      }

      // Magnet menarik item bagus ke arah Valto
      if (_magnet > 0 && !_specs[drop.kind]!.bad) {
        final dx = _playerX - drop.x;
        final dist = (dx).abs() + (playerTop - drop.y).abs();
        if (dist < 260) {
          drop.x += dx * dt * 4.8;
        }
      }

      final dropRect = Rect.fromCircle(
        center: Offset(drop.x, drop.y),
        radius: drop.radius * 0.85,
      );

      if (dropRect.overlaps(playerRect)) {
        _drops.remove(drop);
        _onCollect(drop);
        continue;
      }

      if (drop.y - drop.radius > _arena.height) {
        _drops.remove(drop);
        if (!_specs[drop.kind]!.bad &&
            drop.kind != DropKind.heart &&
            drop.kind != DropKind.magnet &&
            drop.kind != DropKind.slow) {
          _missed++;
          if (_combo > 0) {
            _combo = 0; // aset terlewat = combo putus
            _floatText(drop.x, _arena.height - 40, 'MISS!', VaultColors.ink3);
          }
          if (drop.kind == DropKind.card || drop.kind == DropKind.gem) {
            final penalty = drop.kind == DropKind.card ? 25 : 15;
            _score = math.max(0, _score - penalty);
            _floatText(drop.x, _arena.height - 58, '-$penalty', VaultColors.neg);
          }
        }
      }
    }

    _updateParticles(dt);
  }

  void _spawn() {
    final d = _difficulty;
    final r = _rng.nextDouble();

    // Peluang jebakan lebih tinggi & progresif (22% hingga 46%)
    final badChance = 0.22 + d * 0.24;
    DropKind kind;
    if (r < badChance) {
      kind = _rng.nextBool() ? DropKind.bomb : DropKind.scam;
    } else {
      final p = _rng.nextDouble();
      if (p < 0.04 && _lives < GameConfig.startingLives + 1) {
        kind = DropKind.heart;
      } else if (p < 0.08) {
        kind = DropKind.magnet;
      } else if (p < 0.12) {
        kind = DropKind.slow;
      } else if (p < 0.22) {
        kind = DropKind.card;
      } else if (p < 0.44) {
        kind = DropKind.gem;
      } else if (p < 0.72) {
        kind = DropKind.gold;
      } else {
        kind = DropKind.cash;
      }
    }

    final radius = switch (kind) {
      DropKind.card => 22.0,
      DropKind.bomb || DropKind.scam => 21.0,
      _ => 20.0,
    };
    final x =
        radius + 6 + _rng.nextDouble() * (_arena.width - 2 * (radius + 6));
    final base = ui.lerpDouble(
      GameConfig.baseFallSpeed,
      GameConfig.maxFallSpeed,
      _difficulty,
    )!;
    // Item bernilai tinggi & scam jatuh lebih kencang
    final bonus = switch (kind) {
      DropKind.card => 1.28,
      DropKind.gem => 1.15,
      DropKind.scam => 1.12,
      _ => 1.0,
    };
    final vy = base * bonus * (0.92 + _rng.nextDouble() * 0.22);
    _drops.add(_Drop(kind, x, -radius, vy, radius, _rng.nextDouble() * 6.28));

    // Spawn ganda pada tingkat kesulitan lebih tinggi (pemain harus bermanuver cepat)
    if (_difficulty > 0.22 && _rng.nextDouble() < (0.26 + d * 0.20)) {
      final x2 =
          (x + _arena.width * (0.32 + _rng.nextDouble() * 0.36)) %
              (_arena.width - 2 * (radius + 6)) +
          radius +
          6;
      final k2 = _rng.nextDouble() < 0.55
          ? (_rng.nextBool() ? DropKind.bomb : DropKind.scam)
          : (_rng.nextBool() ? DropKind.gold : DropKind.cash);
      _drops.add(
        _Drop(k2, x2, -radius - 50, vy * 1.05, radius, _rng.nextDouble() * 6.28),
      );
    }
  }

  void _onCollect(_Drop drop) {
    final spec = _specs[drop.kind]!;
    final playerTop = _arena.height - _playerH - 14;

    switch (drop.kind) {
      case DropKind.bomb:
      case DropKind.scam:
        _hit(drop);
        return;
      case DropKind.heart:
        HapticFeedback.lightImpact();
        if (_lives < GameConfig.startingLives + 2) _lives++;
        _floatText(drop.x, playerTop - 8, '+1 LIFE', VaultColors.neg);
        _burst(drop.x, drop.y, spec.color, 10);
        return;
      case DropKind.magnet:
        HapticFeedback.lightImpact();
        _magnet = GameConfig.magnetSeconds;
        _floatText(drop.x, playerTop - 8, 'MAGNET!', spec.color);
        _burst(drop.x, drop.y, spec.color, 10);
        return;
      case DropKind.slow:
        HapticFeedback.lightImpact();
        _slow = GameConfig.slowSeconds;
        _floatText(drop.x, playerTop - 8, 'SLOW-MO!', spec.color);
        _burst(drop.x, drop.y, spec.color, 10);
        return;
      default:
        break;
    }

    HapticFeedback.selectionClick();
    _combo++;
    _caught++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    final gained = spec.points * _multiplier;
    _score += gained;
    _floatText(drop.x, playerTop - 8, '+$gained', spec.color);
    _burst(drop.x, drop.y, spec.color, drop.kind == DropKind.card ? 16 : 8);
    if (_combo > 0 &&
        _combo % GameConfig.comboForMultiplier == 0 &&
        _multiplier <= GameConfig.maxMultiplier) {
      _floatText(
        _playerX,
        playerTop - 34,
        'x$_multiplier COMBO!',
        VaultColors.accent,
      );
    }
  }

  void _hit(_Drop drop) {
    final playerTop = _arena.height - _playerH - 14;
    _burst(
      drop.x,
      drop.y,
      drop.kind == DropKind.bomb ? VaultColors.warn : VaultColors.neg,
      18,
    );
    if (_invuln > 0) return; // masih kebal
    HapticFeedback.heavyImpact();
    _lives--;
    _combo = 0;
    _invuln = GameConfig.invulnSeconds;
    _shake = 1;
    _flash = 1;
    _floatText(
      _playerX,
      playerTop - 8,
      drop.kind == DropKind.bomb ? 'BOOM!' : 'SCAMMED!',
      VaultColors.neg,
    );
    if (_lives <= 0) _endGame();
  }

  void _endGame() {
    _lives = 0;
    // Bersihkan sisa drop agar arena bersih dan tenang saat Game Over
    for (final d in _drops) {
      _burst(d.x, d.y, _specs[d.kind]!.color, 6);
    }
    _drops.clear();

    if (_score > _best) {
      _best = _score;
      _newBest = _score > 0;
    }
    _phase = _Phase.over;
    setState(() {});
  }

  // --------------------------------------------------------------- partikel

  void _burst(double x, double y, Color c, int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final s = 60 + _rng.nextDouble() * 180;
      _particles.add(
        _Particle(
          x,
          y,
          math.cos(a) * s,
          math.sin(a) * s - 60,
          0.45 + _rng.nextDouble() * 0.3,
          2 + _rng.nextDouble() * 3,
          c,
        ),
      );
    }
  }

  void _floatText(double x, double y, String t, Color c) {
    _particles.add(_Particle(x, y, 0, -55, 0.9, 13, c, text: t));
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.text == null) p.vy += 420 * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),
            Expanded(child: _buildArena()),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, _, _) {
        final maxLives = GameConfig.startingLives + 2;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 14, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 19,
                  color: VaultColors.ink,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              // Nyawa (Stylish Pixel Hearts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxLives, (i) {
                  final show = i < math.max(_lives, GameConfig.startingLives);
                  if (!show) return const SizedBox.shrink();
                  final alive = i < _lives;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: PixelSpriteWidget(
                      kind: DropKind.heart,
                      size: 18,
                      opacity: alive ? 1.0 : 0.22,
                    ),
                  );
                }),
              ),
              const Spacer(),
              if (_phase == _Phase.playing || _phase == _Phase.paused) ...[
                if (_magnet > 0)
                  _powerChip(
                    DropKind.magnet,
                    const Color(0xFF2563EB),
                    _magnet / GameConfig.magnetSeconds,
                  ),
                if (_slow > 0)
                  _powerChip(
                    DropKind.slow,
                    const Color(0xFF0EA5E9),
                    _slow / GameConfig.slowSeconds,
                  ),
                if (_multiplier > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: VaultColors.badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: VaultColors.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'x$_multiplier',
                      style: VaultTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: VaultColors.accent,
                      ),
                    ),
                  ),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_score',
                    style: VaultTypography.mono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: VaultColors.ink,
                    ),
                  ),
                  Text(
                    'BEST ${math.max(_best, _score)}',
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      color: VaultColors.ink3,
                    ),
                  ),
                ],
              ),
              if (_phase == _Phase.playing || _phase == _Phase.paused)
                IconButton(
                  icon: Icon(
                    _phase == _Phase.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: VaultColors.ink2,
                  ),
                  onPressed: _togglePause,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _powerChip(DropKind kind, Color c, double ratio) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelSpriteWidget(kind: kind, size: 14),
          const SizedBox(width: 5),
          SizedBox(
            width: 26,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: c.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArena() {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        if (_arena != size) {
          final first = _arena == Size.zero;
          _arena = size;
          if (first || _phase != _Phase.playing) {
            _playerX = size.width / 2;
            _targetX = _playerX;
          }
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _dragTo(d.localPosition.dx),
          onPanUpdate: (d) => _dragTo(d.localPosition.dx),
          onTapDown: (d) => _dragTo(d.localPosition.dx),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _frame,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _GamePainter(this),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
              if (_phase == _Phase.ready) _buildReadyOverlay(),
              if (_phase == _Phase.paused) _buildPausedOverlay(),
              if (_phase == _Phase.over) _buildOverOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _overlayCard({required List<Widget> children}) {
    return Positioned.fill(
      child: Container(
        color: VaultColors.ink.withValues(alpha: 0.40),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
          decoration: BoxDecoration(
            color: VaultColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: VaultColors.hairline),
            boxShadow: [
              BoxShadow(
                color: VaultColors.ink.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: VaultColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow({
    required List<DropKind> kinds,
    required String text,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: kinds.map((k) {
              final spec = _specs[k]!;
              return Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDanger
                      ? const Color(0xFFFEF2F2)
                      : VaultColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDanger
                        ? VaultColors.neg.withValues(alpha: 0.35)
                        : spec.color.withValues(alpha: 0.35),
                  ),
                ),
                child: PixelSpriteWidget(kind: k, size: 18),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: VaultTypography.sans(
                fontSize: 11.5,
                color: VaultColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return _overlayCard(
      children: [
        Text(
          "VALTO'S VAULT RUSH",
          style: VaultTypography.sans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Geser jari untuk menggerakkan Valto',
          style: VaultTypography.mono(fontSize: 10.5, color: VaultColors.ink2),
        ),
        const SizedBox(height: 14),
        _legendRow(
          kinds: [DropKind.cash, DropKind.gold, DropKind.gem, DropKind.card],
          text: 'Aset: Cash, Emas, Gem, & Skin Langka',
        ),
        _legendRow(
          kinds: [DropKind.bomb, DropKind.scam],
          text: 'Bahaya: Bom & Scam — kena = -1 nyawa!',
          isDanger: true,
        ),
        _legendRow(
          kinds: [DropKind.magnet, DropKind.slow, DropKind.heart],
          text: 'Power-up: Magnet, Slow-mo, & +1 Nyawa',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: VaultColors.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: VaultColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'x2-x5',
                  style: VaultTypography.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: VaultColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Combo skor beruntun tanpa terlewat',
                  style: VaultTypography.sans(
                    fontSize: 11.5,
                    color: VaultColors.body,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: VaultColors.ink,
              foregroundColor: VaultColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'MULAI MAIN',
              style: VaultTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VaultColors.background,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    return _overlayCard(
      children: [
        Text(
          'GAME PAUSED',
          style: VaultTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: VaultColors.ink2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Skor Sementara: $_score',
          style: VaultTypography.sans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VaultColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: VaultColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Keluar',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: _togglePause,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: VaultColors.background,
                ),
                label: Text(
                  'Lanjutkan',
                  style: VaultTypography.sans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.background,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: VaultColors.ink,
                  foregroundColor: VaultColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: VaultTypography.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: VaultColors.ink3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: VaultTypography.mono(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: VaultColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildOverOverlay() {
    final rank = _score >= 3000
        ? 'VAULT LEGEND'
        : _score >= 1500
        ? 'MASTER APPRAISER'
        : _score >= 600
        ? 'SHARP GUARDIAN'
        : 'ROOKIE GUARDIAN';

    final totalAssets = _caught + _missed;
    final accuracy = totalAssets > 0
        ? ((_caught / totalAssets) * 100).toStringAsFixed(0)
        : '100';

    return _overlayCard(
      children: [
        // Badge Status / Personal Best
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: VaultColors.badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: VaultColors.accent.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _newBest ? 'NEW PERSONAL BEST' : rank,
                style: VaultTypography.mono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: VaultColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Hero Score Display
        Text(
          '$_score',
          style: VaultTypography.mono(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: VaultColors.ink,
          ),
        ),
        Text(
          'TOTAL VAULT SCORE',
          style: VaultTypography.mono(
            fontSize: 9.5,
            letterSpacing: 1.5,
            color: VaultColors.ink3,
          ),
        ),
        const SizedBox(height: 18),

        // 4-Column Performance Telemetry Dashboard
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: VaultColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VaultColors.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('TERTANGKAP', '$_caught'),
              Container(width: 1, height: 24, color: VaultColors.hairline),
              _stat('TERLEWAT', '$_missed'),
              Container(width: 1, height: 24, color: VaultColors.hairline),
              _stat('AKURASI', '$accuracy%'),
              Container(width: 1, height: 24, color: VaultColors.hairline),
              _stat(
                'MAX COMBO',
                'x${1 + _maxCombo ~/ GameConfig.comboForMultiplier}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bottom Ergonomic Thumb Actions
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: VaultColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Keluar',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: VaultColors.background,
                ),
                label: Text(
                  'MAIN LAGI',
                  style: VaultTypography.sans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: VaultColors.background,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VaultColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// RENDERER
// ============================================================================
class _GamePainter extends CustomPainter {
  final _GameScreenState g;
  _GamePainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (g._shake > 0) {
      final m = g._shake * 7;
      canvas.translate(
        (g._rng.nextDouble() - 0.5) * m,
        (g._rng.nextDouble() - 0.5) * m,
      );
    }

    _paintBackground(canvas, size);
    _paintDrops(canvas);
    _paintPlayer(canvas, size);
    _paintParticles(canvas);

    canvas.restore();

    if (g._flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = VaultColors.neg.withValues(alpha: 0.22 * g._flash),
      );
    }
    if (g._slow > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF0EA5E9).withValues(alpha: 0.06),
      );
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VaultColors.sunsetTop,
            VaultColors.sunsetMid,
            VaultColors.background,
          ],
        ).createShader(rect),
    );

    // Garis lajur vault yang bergerak (memberi kesan kecepatan)
    final speed = 40 + g._difficulty * 160;
    final offset = (g._elapsed * speed) % 60;
    final line = Paint()
      ..color = VaultColors.hairline.withValues(alpha: 0.9)
      ..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    final dash = Paint()
      ..color = VaultColors.hairline.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (double y = -60 + offset; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dash);
    }

    // Lantai vault
    final floorY = size.height - 10;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, 10),
      Paint()..color = VaultColors.ink,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, 2),
      Paint()..color = VaultColors.accent,
    );
  }

  void _paintDrops(Canvas canvas) {
    for (final d in g._drops) {
      final spec = _specs[d.kind]!;
      final c = Offset(d.x, d.y);
      final r = d.radius;

      if (spec.bad) {
        _paintHazard(canvas, d, spec);
        continue;
      }

      // Bayangan pixel art halus di bawah aset (tanpa kotak container)
      PixelSprite.paint(
        canvas,
        c.translate(2.0, 3.5),
        d.kind,
        r * 1.85,
        opacity: 0.20,
        isShadow: true,
      );

      // Aura berpendar untuk item langka (Card & Gem)
      if (d.kind == DropKind.card || d.kind == DropKind.gem) {
        final pulse = 0.5 + 0.5 * math.sin(g._elapsed * 6 + d.phase);
        canvas.drawCircle(
          c,
          r + 4 + pulse * 4,
          Paint()..color = spec.color.withValues(alpha: 0.18 + 0.12 * pulse),
        );
      }

      // Gambar sprite pixel art 8x8 langsung TANPA container kotak
      PixelSprite.paint(canvas, c, d.kind, r * 1.85, anim: g._elapsed);
    }
  }

  void _paintHazard(Canvas canvas, _Drop d, _DropSpec spec) {
    final c = Offset(d.x, d.y);
    final r = d.radius;
    canvas.save();
    canvas.translate(c.dx, c.dy);

    final pulse = 0.5 + 0.5 * math.sin(g._elapsed * 8 + d.phase);
    final hazardColor =
        d.kind == DropKind.bomb ? VaultColors.warn : VaultColors.neg;
    canvas.drawCircle(
      Offset.zero,
      r + 3 + pulse * 3,
      Paint()..color = hazardColor.withValues(alpha: 0.18 + 0.10 * pulse),
    );

    // Bayangan hazard pixel art
    PixelSprite.paint(
      canvas,
      const Offset(2.0, 3.5),
      d.kind,
      r * 1.95,
      opacity: 0.22,
      isShadow: true,
    );

    if (d.kind == DropKind.bomb) {
      canvas.rotate(math.sin(d.spin * 2) * 0.18);
      // Gambar bom pixel art langsung TANPA kotak container
      PixelSprite.paint(
        canvas,
        Offset.zero,
        DropKind.bomb,
        r * 1.95,
        anim: g._elapsed + d.phase,
      );
    } else {
      // Gambar tengkorak scam pixel art langsung TANPA kotak container
      PixelSprite.paint(
        canvas,
        Offset.zero,
        DropKind.scam,
        r * 1.95,
        anim: g._elapsed,
      );
    }
    canvas.restore();
  }

  void _paintPixelTray(Canvas canvas, double cx, double trayY, double width) {
    const matrix = [
      'BB................BB',
      'BYYYYYYYYYYYYYYYYYYB',
      'BGGGGGGGGGGGGGGGGGGB',
      'BDDDDDDDDDDDDDDDDDDB',
      '.BBBBBBBBBBBBBBBBBB.',
      '........BBBB........',
      '........BGGB........',
    ];

    const palette = {
      'B': Color(0xFF18181B),
      'Y': Color(0xFFFEF08A),
      'G': Color(0xFFEAB308),
      'D': Color(0xFFB45309),
    };

    const cols = 20;
    const rows = 7;
    final pixelSize = width / cols;
    final startX = cx - width / 2.0;
    final startY = trayY;

    // Bayangan pixel tray di atas Valto
    canvas.drawRect(
      Rect.fromLTWH(startX + 2, startY + 4 * pixelSize + 1, width - 4, 2.5),
      Paint()..color = VaultColors.ink.withValues(alpha: 0.14),
    );

    for (int y = 0; y < rows; y++) {
      final row = matrix[y];
      for (int x = 0; x < cols; x++) {
        final char = row[x];
        if (char == '.') continue;
        final color = palette[char];
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            startX + x * pixelSize,
            startY + y * pixelSize,
            pixelSize + 0.35,
            pixelSize + 0.35,
          ),
          Paint()..color = color,
        );
      }
    }
  }

  void _paintPlayer(Canvas canvas, Size size) {
    final w = _GameScreenState._playerW;
    final h = _GameScreenState._playerH;
    final top = size.height - h - 14;
    final cx = g._playerX;

    // Kedip saat kebal
    if (g._invuln > 0 && (g._elapsed * 14).floor().isEven) return;

    // Aura magnet
    if (g._magnet > 0) {
      final pulse = 0.5 + 0.5 * math.sin(g._elapsed * 8);
      canvas.drawCircle(
        Offset(cx, top + h / 2),
        h * 0.9 + pulse * 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF2563EB)
              .withValues(alpha: 0.25 + 0.2 * pulse),
      );
    }

    // Bayangan di lantai
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 12),
        width: w * 0.8,
        height: 8,
      ),
      Paint()..color = VaultColors.ink.withValues(alpha: 0.12),
    );

    // Squash & stretch kecil mengikuti kecepatan gerak
    final lean = (g._playerVx / 900).clamp(-0.18, 0.18);
    canvas.save();
    canvas.translate(cx, top + h);
    canvas.rotate(lean);
    canvas.translate(-cx, -(top + h));

    final dst = Rect.fromLTWH(cx - w / 2, top, w, h);
    final img = g._valto;
    if (img != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      // Pertahankan rasio sprite
      final scale = math.min(dst.width / src.width, dst.height / src.height);
      final fw = src.width * scale;
      final fh = src.height * scale;
      final fit = Rect.fromLTWH(cx - fw / 2, top + h - fh, fw, fh);
      canvas.drawImageRect(
        img,
        src,
        fit,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(dst, const Radius.circular(12)),
        Paint()..color = VaultColors.vowlCharcoal,
      );
    }

    // Gambar pixel catching tray yang serasi di atas kepala Valto (ikut miring saat bergerak)
    _paintPixelTray(canvas, cx, top - 12, w + 12);

    canvas.restore();
  }

  void _paintParticles(Canvas canvas) {
    for (final p in g._particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      if (p.text != null) {
        _text(
          canvas,
          p.text!,
          Offset(p.x, p.y),
          p.size,
          p.color.withValues(alpha: t),
          bold: true,
          mono: true,
        );
      } else {
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size * t,
          Paint()..color = p.color.withValues(alpha: t),
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String s,
    Offset center,
    double size,
    Color color, {
    bool bold = false,
    bool mono = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style:
            (mono
                    ? VaultTypography.mono(fontSize: size, color: color)
                    : TextStyle(fontSize: size, color: color))
                .copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
