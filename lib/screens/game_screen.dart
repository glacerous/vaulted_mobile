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
  static const int comboForMultiplier = 5; // tiap N tangkapan beruntun, x naik
  static const int maxMultiplier = 5;
  static const double baseFallSpeed = 210; // px/detik
  static const double maxFallSpeed = 520;
  static const double baseSpawnInterval = 0.85; // detik
  static const double minSpawnInterval = 0.38;
  static const double difficultyRampSeconds =
      90; // waktu sampai kesulitan penuh
  static const double invulnSeconds = 1.1; // kebal sesaat setelah kena
  static const double magnetSeconds = 6;
  static const double slowSeconds = 5;
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
    final playerRect = Rect.fromLTWH(
      _playerX - _playerW / 2 + 6,
      playerTop + 10,
      _playerW - 12,
      _playerH - 10,
    );

    for (final drop in List<_Drop>.from(_drops)) {
      drop.y += drop.vy * slowFactor * dt;
      drop.spin += dt * (drop.kind == DropKind.bomb ? 3 : 1.4);

      // Magnet menarik item bagus ke arah Valto
      if (_magnet > 0 && !_specs[drop.kind]!.bad) {
        final dx = _playerX - drop.x;
        final dist = (dx).abs() + (playerTop - drop.y).abs();
        if (dist < 330) {
          drop.x += dx * dt * 5.5;
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
            _floatText(drop.x, _arena.height - 40, 'MISS', VaultColors.ink3);
          }
        }
      }
    }

    _updateParticles(dt);
  }

  void _spawn() {
    final d = _difficulty;
    final r = _rng.nextDouble();

    // Peluang jebakan naik seiring waktu
    final badChance = 0.16 + d * 0.22;
    DropKind kind;
    if (r < badChance) {
      kind = _rng.nextBool() ? DropKind.bomb : DropKind.scam;
    } else {
      final p = _rng.nextDouble();
      if (p < 0.045 && _lives < GameConfig.startingLives + 2) {
        kind = DropKind.heart;
      } else if (p < 0.08) {
        kind = DropKind.magnet;
      } else if (p < 0.115) {
        kind = DropKind.slow;
      } else if (p < 0.20) {
        kind = DropKind.card;
      } else if (p < 0.40) {
        kind = DropKind.gem;
      } else if (p < 0.68) {
        kind = DropKind.gold;
      } else {
        kind = DropKind.cash;
      }
    }

    final radius = kind == DropKind.card ? 22.0 : 20.0;
    final x =
        radius + 6 + _rng.nextDouble() * (_arena.width - 2 * (radius + 6));
    final base = ui.lerpDouble(
      GameConfig.baseFallSpeed,
      GameConfig.maxFallSpeed,
      _difficulty,
    )!;
    // Item mahal jatuh lebih cepat, bikin makin menantang
    final bonus = switch (kind) {
      DropKind.card => 1.25,
      DropKind.gem => 1.12,
      _ => 1.0,
    };
    final vy = base * bonus * (0.9 + _rng.nextDouble() * 0.25);
    _drops.add(_Drop(kind, x, -radius, vy, radius, _rng.nextDouble() * 6.28));

    // Kadang spawn pasangan agar pemain harus memilih jalur
    if (_difficulty > 0.35 && _rng.nextDouble() < 0.22) {
      final x2 =
          (x + _arena.width * (0.35 + _rng.nextDouble() * 0.3)) %
              (_arena.width - 2 * (radius + 6)) +
          radius +
          6;
      final k2 = _rng.nextDouble() < 0.55
          ? (_rng.nextBool() ? DropKind.bomb : DropKind.scam)
          : DropKind.gold;
      _drops.add(
        _Drop(k2, x2, -radius - 60, vy, radius, _rng.nextDouble() * 6.28),
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
      builder: (context, _, __) {
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
              // Nyawa
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxLives, (i) {
                  final show = i < math.max(_lives, GameConfig.startingLives);
                  if (!show) return const SizedBox.shrink();
                  final alive = i < _lives;
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      alive
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: alive
                          ? VaultColors.neg
                          : VaultColors.ink3.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
              const Spacer(),
              if (_phase == _Phase.playing || _phase == _Phase.paused) ...[
                if (_magnet > 0)
                  _powerChip(
                    'U',
                    const Color(0xFF2563EB),
                    _magnet / GameConfig.magnetSeconds,
                  ),
                if (_slow > 0)
                  _powerChip(
                    '❄',
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

  Widget _powerChip(String glyph, Color c, double ratio) {
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
          Text(
            glyph,
            style: TextStyle(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w800,
            ),
          ),
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
        color: VaultColors.background.withValues(alpha: 0.82),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: VaultColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: VaultColors.hairline),
            boxShadow: [
              BoxShadow(
                color: VaultColors.ink.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _legendRow(DropKind k, String text) {
    final s = _specs[k]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.bad
                  ? const Color(0xFFFEE2E2)
                  : s.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: s.color.withValues(alpha: 0.6)),
            ),
            child: Text(
              s.glyph,
              style: TextStyle(
                fontSize: 12,
                color: s.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: VaultTypography.sans(
                fontSize: 12,
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
        const SizedBox(height: 16),
        _legendRow(DropKind.gold, 'Tangkap aset: cash, emas, gem, skin langka'),
        _legendRow(
          DropKind.bomb,
          'Hindari bom & scam — kena = nyawa berkurang',
        ),
        _legendRow(DropKind.magnet, 'Power-up: magnet, slow-mo, dan +nyawa'),
        _legendRow(DropKind.heart, 'Tangkap beruntun untuk combo skor x2 – x5'),
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
        const Icon(
          Icons.pause_circle_outline_rounded,
          size: 40,
          color: VaultColors.ink2,
        ),
        const SizedBox(height: 8),
        Text(
          'Dijeda',
          style: VaultTypography.sans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: VaultColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
              child: ElevatedButton(
                onPressed: _togglePause,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: VaultColors.ink,
                  foregroundColor: VaultColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lanjut',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.background,
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
      children: [
        Text(
          label,
          style: VaultTypography.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: VaultColors.ink3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: VaultTypography.mono(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: VaultColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildOverOverlay() {
    final rank = _score >= 3000
        ? '👑 Vault Legend'
        : _score >= 1500
        ? '💼 Master Collector'
        : _score >= 600
        ? '🔎 Sharp Appraiser'
        : '🐾 Rookie Guardian';
    return _overlayCard(
      children: [
        Text(
          'GAME OVER',
          style: VaultTypography.sans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rank,
          style: VaultTypography.mono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: VaultColors.accent,
          ),
        ),
        if (_newBest) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: VaultColors.badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'REKOR BARU!',
              style: VaultTypography.mono(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: VaultColors.accent,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: VaultColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VaultColors.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('SKOR', '$_score'),
              _stat('TERTANGKAP', '$_caught'),
              _stat('COMBO', '$_maxCombo'),
              _stat('WAKTU', '${_elapsed.toStringAsFixed(0)}s'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: VaultColors.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: VaultColors.ink,
                  foregroundColor: VaultColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Main Lagi',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.background,
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

      // Bayangan
      canvas.drawCircle(
        c.translate(0, 4),
        r,
        Paint()..color = VaultColors.ink.withValues(alpha: 0.06),
      );

      if (spec.bad) {
        _paintHazard(canvas, d, spec);
        continue;
      }

      // Aura untuk item langka
      if (d.kind == DropKind.card || d.kind == DropKind.gem) {
        final pulse = 0.5 + 0.5 * math.sin(g._elapsed * 6 + d.phase);
        canvas.drawCircle(
          c,
          r + 6 + pulse * 3,
          Paint()..color = spec.color.withValues(alpha: 0.14 + 0.08 * pulse),
        );
      }

      canvas.drawCircle(c, r, Paint()..color = VaultColors.card);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = spec.color,
      );
      canvas.drawCircle(
        c,
        r - 4,
        Paint()..color = spec.color.withValues(alpha: 0.13),
      );
      _text(canvas, spec.glyph, c, r * 1.0, spec.color, bold: true);
    }
  }

  void _paintHazard(Canvas canvas, _Drop d, _DropSpec spec) {
    final c = Offset(d.x, d.y);
    final r = d.radius;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    if (d.kind == DropKind.bomb) {
      canvas.rotate(math.sin(d.spin * 2) * 0.25);
      canvas.drawCircle(Offset.zero, r, Paint()..color = VaultColors.ink);
      canvas.drawCircle(
        Offset(-r * 0.3, -r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      // sumbu
      final fuse = Paint()
        ..color = VaultColors.ink2
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, -r), Offset(r * 0.5, -r - 9), fuse);
      final blink = (math.sin(g._elapsed * 18 + d.phase) > 0);
      canvas.drawCircle(
        Offset(r * 0.5, -r - 9),
        4.2,
        Paint()..color = blink ? VaultColors.warn : VaultColors.neg,
      );
    } else {
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()..color = const Color(0xFF7F1D1D),
      );
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = VaultColors.neg,
      );
      _text(canvas, '☠', Offset.zero, r * 1.05, Colors.white, bold: true);
    }
    canvas.restore();
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
    canvas.restore();

    // Keranjang/dompet vault di depan Valto sebagai area tangkap
    final tray = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, top + 6), width: w + 4, height: 7),
      const Radius.circular(4),
    );
    canvas.drawRRect(tray, Paint()..color = VaultColors.accent);
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
