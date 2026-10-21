import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/widgets/valto_mascot.dart';

/// 🎮 PILIHAN TAMPILAN HEALTHBAR
enum HealthbarStyle {
  hearts, // Hanya ikon hati
  bar,    // Bar HP gaming RPG / Fighting (dengan persentase & warna dinamis)
  both,   // Ikon hati + Smooth Healthbar (Paling lengkap & fleksibel)
}

/// ============================================================================
/// 🎓 DOSEN LIVE CHALLENGE: GAME CONFIGURATION
/// 
/// Dosen sering menguji fleksibilitas kode dengan tantangan:
/// 1. "Coba ubah nyawa awal (health bar) jadi 5 atau 10!"
///    -> Cukup ubah `startingLives = 5;` di bawah ini.
/// 2. "Coba ganti style healthbar-nya!"
///    -> Ubah `healthbarStyle = HealthbarStyle.bar;` atau `HealthbarStyle.hearts;`
/// 3. "Coba ubah poinnya jadi 200 per soal!"
///    -> Ubah `pointsPerCorrect = 200;`
/// 4. "Coba tambahkan soal baru dengan harga dan penjelasan sendiri!"
///    -> Lihat template soal di daftar `_questions`.
/// ============================================================================
class GameConfig {
  /// 💖 HEALTH / NYAWA AWAL PEMAIN
  /// Ubah nilai ini jika dosen menantang ganti nyawa saat presentasi
  static const int startingLives = 3;

  /// 📊 GAYA HEALTHBAR (hearts, bar, atau both)
  static const HealthbarStyle healthbarStyle = HealthbarStyle.both;

  /// 🎯 POIN DASAR PER JAWABAN BENAR
  static const int pointsPerCorrect = 100;

  /// 🔥 BONUS POIN PER STREAK
  static const int streakBonusPoints = 25;

  /// ⏱️ DURASI JEDA REVEAL HARGA (ms)
  static const Duration feedbackDuration = Duration(milliseconds: 1400);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  int _score = 0;
  int _streak = 0;
  int _lives = GameConfig.startingLives;
  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _isGameOver = false;

  String? _feedback;
  bool? _isCorrect;
  double? _revealedPrice;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  /// ==========================================================================
  /// 💡 DAFTAR SOAL GAME (Bisa langsung diedit / ditambah saat demo di depan dosen)
  /// Aturan Jawaban:
  /// - actual_val >= benchmark_val  =>  Jawaban Benar: HIGHER
  /// - actual_val < benchmark_val   =>  Jawaban Benar: LOWER
  ///
  /// 📝 TEMPLATE SOAL BARU UNTUK TEST DOSEN:
  /// {
  ///   'name': 'HP Victus Gaming Laptop 15',
  ///   'category': 'Gaming Hardware',
  ///   'retail_year': 'Released 2023 for $899.00',
  ///   'benchmark': '$650.00',
  ///   'benchmark_val': 650.0,
  ///   'actual_val': 720.0, // actual >= benchmark -> HIGHER
  ///   'explanation': 'Actual market value is ~$720! RTX 3050 laptops maintain solid resale demand.',
  ///   'image': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=300',
  /// },
  /// ==========================================================================
  final List<Map<String, dynamic>> _questions = [
    {
      'name': 'Valve Steam Deck OLED 512GB',
      'category': 'Gaming Hardware',
      'retail_year': 'Released Nov 2023 for \$549.00',
      'benchmark': '\$480.00',
      'benchmark_val': 480.0,
      'actual_val': 515.0, // actual >= bench -> HIGHER
      'explanation': 'Actual market value is ~\$515! OLED Steam Decks retain 94% value due to exceptional Linux gaming optimization.',
      'image': 'https://images.unsplash.com/photo-1612287232213-9111c1070e17?w=300',
    },
    {
      'name': 'Sony PlayStation 4 Pro 1TB',
      'category': 'Retro Gaming Console',
      'retail_year': 'Released 2016 for \$399.00',
      'benchmark': '\$180.00',
      'benchmark_val': 180.0,
      'actual_val': 195.0, // actual >= bench -> HIGHER
      'explanation': 'Actual market value is ~\$195! PS4 Pro retains strong liquidity for jailbreak enthusiasts and local couch co-op.',
      'image': 'https://images.unsplash.com/photo-1507457379470-08b800bebc67?w=300',
    },
    {
      'name': 'Apple iPhone 11 64GB',
      'category': 'Smartphone / Tech',
      'retail_year': 'Released 2019 for \$699.00',
      'benchmark': '\$280.00',
      'benchmark_val': 280.0,
      'actual_val': 210.0, // actual < bench -> LOWER
      'explanation': 'Actual market value is ~\$210! Mass-market smartphones suffer ~70% steep depreciation over 5+ years.',
      'image': 'https://images.unsplash.com/photo-1591337676887-a217a6970a8a?w=300',
    },
    {
      'name': 'AK-47 | Case Hardened (Tier 1 Blue Gem)',
      'category': 'CS2 Contraband Skin',
      'retail_year': 'Arms Deal Collection (Original Case)',
      'benchmark': '\$15,000.00',
      'benchmark_val': 15000.0,
      'actual_val': 42000.0, // actual >= bench -> HIGHER
      'explanation': 'Actual market value is ~\$42,000+! Pattern #661 Scar Blue Gems command immense luxury premiums in the CS2 collector community.',
      'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=300',
    },
    {
      'name': 'Nintendo Switch OLED Pokémon Scarlet Edition',
      'category': 'Limited Edition Console',
      'retail_year': 'Released 2022 for \$359.00',
      'benchmark': '\$290.00',
      'benchmark_val': 290.0,
      'actual_val': 310.0, // actual >= bench -> HIGHER
      'explanation': 'Actual market value is ~\$310! Limited Pokémon SKUs depreciate significantly slower than standard consumer electronics.',
      'image': 'https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=300',
    },
    {
      'name': 'Sony WH-1000XM5 Noise Cancelling',
      'category': 'Audiophile Hardware',
      'retail_year': 'Released 2022 for \$399.00',
      'benchmark': '\$320.00',
      'benchmark_val': 320.0,
      'actual_val': 265.0, // actual < bench -> LOWER
      'explanation': 'Actual market value is ~\$265! Second-hand audio hardware loses value as battery wear and newer revisions release.',
      'image': 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=300',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _submitGuess(bool isHigher) {
    if (_feedback != null || _isGameOver) return;

    final q = _questions[_currentIndex];
    final actual = (q['actual_val'] as num).toDouble();
    final bench = (q['benchmark_val'] as num).toDouble();

    final isCorrectGuess = isHigher ? (actual >= bench) : (actual <= bench);

    if (isCorrectGuess) {
      HapticFeedback.mediumImpact();
      _streak++;
      _correctAnswers++;
      final gained = GameConfig.pointsPerCorrect + (_streak > 1 ? (_streak - 1) * GameConfig.streakBonusPoints : 0);
      _score += gained;
    } else {
      HapticFeedback.heavyImpact();
      _streak = 0;
      _lives--;
    }

    _animController.forward().then((_) => _animController.reverse());

    setState(() {
      _isCorrect = isCorrectGuess;
      _revealedPrice = actual;
      _feedback = q['explanation'] as String;
      if (_lives <= 0) {
        _isGameOver = true;
      }
    });

    if (_lives <= 0) {
      _showGameOverModal(isVictory: false);
    }
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      setState(() => _isGameOver = true);
      _showGameOverModal(isVictory: true);
      return;
    }

    setState(() {
      _feedback = null;
      _isCorrect = null;
      _revealedPrice = null;
      _currentIndex++;
    });
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _streak = 0;
      _lives = GameConfig.startingLives;
      _currentIndex = 0;
      _correctAnswers = 0;
      _isGameOver = false;
      _feedback = null;
      _isCorrect = null;
      _revealedPrice = null;
    });
  }

  void _showGameOverModal({required bool isVictory}) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final accuracy = (_correctAnswers / _questions.length * 100).toStringAsFixed(0);
          final rank = _score >= 500
              ? '👑 Market Oracle'
              : _score >= 300
                  ? '💼 Senior Appraiser'
                  : '🔎 Junior Valuer';

          return Container(
            decoration: const BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VaultColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ValtoMascot(
                  size: 64,
                  mood: isVictory ? ValtoMood.happy : ValtoMood.vigilant,
                  showHat: true,
                ),
                const SizedBox(height: 14),
                Text(
                  isVictory ? 'Appraisal Trial Complete!' : 'Out of Lives!',
                  style: VaultTypography.sans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.ink,
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('FINAL SCORE', '$_score PTS'),
                      Container(width: 1, height: 32, color: VaultColors.hairline),
                      _buildStatColumn('ACCURACY', '$accuracy%'),
                      Container(width: 1, height: 32, color: VaultColors.hairline),
                      _buildStatColumn('SOLVED', '$_correctAnswers/${_questions.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: VaultColors.hairline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Exit to Vault',
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          _restartGame();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: VaultColors.ink,
                          foregroundColor: VaultColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Play Again',
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
            ),
          );
        },
      );
    });
  }

  Widget _buildStatColumn(String label, String value) {
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: VaultColors.ink,
          ),
        ),
      ],
    );
  }

  /// 💖 HEALTHBAR WIDGET (Otomatis menyesuaikan jumlah startingLives tanpa overflow)
  Widget _buildHealthBar() {
    final maxLives = GameConfig.startingLives;
    final hpRatio = (_lives / maxLives).clamp(0.0, 1.0);

    // Warna dinamis: Hijau (>50%) -> Oranye/Kuning (>25%) -> Merah (<=25%)
    final Color barColor = hpRatio > 0.5
        ? VaultColors.pos
        : hpRatio > 0.25
            ? VaultColors.warn
            : VaultColors.neg;

    // Style 1: Hanya Ikon Hati
    if (GameConfig.healthbarStyle == HealthbarStyle.hearts) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLives, (i) {
          final isAlive = i < _lives;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(
              isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isAlive ? VaultColors.neg : VaultColors.ink3.withValues(alpha: 0.3),
              size: 18,
            ),
          );
        }),
      );
    }

    // Style 2: Hanya Bar HP Gaming
    if (GameConfig.healthbarStyle == HealthbarStyle.bar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, size: 13, color: VaultColors.neg),
              const SizedBox(width: 4),
              Text(
                'HP $_lives/$maxLives',
                style: VaultTypography.mono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${(hpRatio * 100).toInt()}%)',
                style: VaultTypography.mono(fontSize: 9.5, color: VaultColors.ink2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 105,
            height: 7,
            decoration: BoxDecoration(
              color: VaultColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: hpRatio,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Style 3 (both): Hati + HP Bar (Aman tidak pernah overflow berapapun nyawanya)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (maxLives <= 5)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxLives, (i) {
                  final isAlive = i < _lives;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isAlive ? VaultColors.neg : VaultColors.ink3.withValues(alpha: 0.3),
                      size: 15,
                    ),
                  );
                }),
              )
            else
              Text(
                'HP $_lives/$maxLives',
                style: VaultTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '${(hpRatio * 100).toInt()}%',
              style: VaultTypography.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 100,
          height: 6,
          decoration: BoxDecoration(
            color: VaultColors.background,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: VaultColors.hairline),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hpRatio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The Appraiser',
              style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w700, color: VaultColors.ink),
            ),
            Text(
              'Asset Valuation Challenge',
              style: VaultTypography.mono(fontSize: 10.5, color: VaultColors.ink2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restart Game',
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: VaultColors.ink2,
            ),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // 1. GAME STATUS HUD (Lives, Score, Streak)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Health Bar (Hearts / Animated Gauge)
                    _buildHealthBar(),
                    // Streak Pill
                    if (_streak > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VaultColors.badgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: VaultColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              '${_streak}x STREAK',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: VaultColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VaultColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Text(
                        '$_score PTS',
                        style: VaultTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: VaultColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. ROUND PROGRESS BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROUND ${_currentIndex + 1} OF ${_questions.length}',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% COMPLETE',
                    style: VaultTypography.mono(fontSize: 9.5, color: VaultColors.ink3),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: VaultColors.hairline,
                  valueColor: const AlwaysStoppedAnimation<Color>(VaultColors.accent),
                ),
              ),
              const SizedBox(height: 14),

              // 3. MASCOT DIALOGUE BUBBLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValtoMascot(
                    size: 40,
                    mood: _feedback == null
                        ? ValtoMood.detective
                        : (_isCorrect == true ? ValtoMood.happy : ValtoMood.vigilant),
                    showHat: true,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Text(
                        _feedback == null
                            ? "Valto: 'Is this asset higher or lower than the benchmark?'"
                            : (_isCorrect == true
                                ? "Valto: 'Bullseye! You know your market value!'"
                                : "Valto: 'Ouch! The market took a surprising turn.'"),
                        style: VaultTypography.sans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _feedback == null
                              ? VaultColors.ink2
                              : (_isCorrect == true ? VaultColors.pos : VaultColors.neg),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. MAIN ITEM VALUATION CARD
              Expanded(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: VaultColors.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: VaultColors.ink.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: VaultColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: Text(
                            q['category'] as String,
                            style: VaultTypography.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Item Artwork
                        Container(
                          height: 130,
                          width: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: VaultColors.background,
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              q['image'] as String,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.inventory_2_outlined, size: 48, color: VaultColors.ink3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Item Name
                        Text(
                          q['name'] as String,
                          style: VaultTypography.sans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: VaultColors.ink,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q['retail_year'] as String,
                          style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink3),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),

                        // Benchmark Value
                        Text(
                          'MARKET BENCHMARK',
                          style: VaultTypography.mono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: VaultColors.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q['benchmark'] as String,
                          style: VaultTypography.mono(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: VaultColors.accent,
                          ),
                        ),

                        // Revealed Price after answer
                        if (_revealedPrice != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isCorrect == true ? VaultColors.posBg : VaultColors.negBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Actual Value: \$${_revealedPrice!.toStringAsFixed(2)}',
                              style: VaultTypography.mono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _isCorrect == true ? VaultColors.pos : VaultColors.neg,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. ACTION AREA (HIGHER / LOWER OR NEXT BUTTON)
              if (_feedback != null) ...[
                // Feedback Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isCorrect == true ? VaultColors.posBg : VaultColors.negBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect == true
                          ? VaultColors.pos.withValues(alpha: 0.4)
                          : VaultColors.neg.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCorrect == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 16,
                            color: _isCorrect == true ? VaultColors.pos : VaultColors.neg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCorrect == true
                                ? 'CORRECT! +${GameConfig.pointsPerCorrect}${_streak > 1 ? " (+${(_streak - 1) * GameConfig.streakBonusPoints} STREAK)" : ""}'
                                : 'INCORRECT! (-1 LIFE)',
                            style: VaultTypography.mono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect == true ? VaultColors.pos : VaultColors.neg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _feedback!,
                        style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Next Item Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VaultColors.ink,
                      foregroundColor: VaultColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex + 1 >= _questions.length ? 'See Final Results' : 'Next Item',
                          style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // HIGHER / LOWER BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitGuess(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.posBg,
                            foregroundColor: VaultColors.pos,
                            elevation: 0,
                            side: const BorderSide(color: VaultColors.pos, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                          label: Text(
                            'HIGHER',
                            style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitGuess(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.negBg,
                            foregroundColor: VaultColors.neg,
                            elevation: 0,
                            side: const BorderSide(color: VaultColors.neg, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                          label: Text(
                            'LOWER',
                            style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
