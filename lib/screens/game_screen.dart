import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _score = 0;
  int _currentIndex = 0;
  String? _feedback;
  bool? _isCorrect;

  // Real market valuation questions (Higher or Lower challenge)
  final List<Map<String, dynamic>> _questions = [
    {
      'name': 'Sony PlayStation 4 Pro 1TB',
      'category': 'Gaming Hardware',
      'retail_year': 'Released 2016 for \$399',
      'benchmark': '\$180',
      'actual_val': 195.0,
      'benchmark_val': 180.0,
      'explanation': 'Actual market value is ~\$195! PS4 Pro retains solid value for jailbreak & retro gaming.',
      'image': 'https://images.unsplash.com/photo-1507457379470-08b800bebc67?w=300',
    },
    {
      'name': 'Charizard 1st Edition Shadowless (PSA 10)',
      'category': 'Collectibles / TCG',
      'retail_year': 'Released 1999 for \$3.99 Booster Pack',
      'benchmark': '\$250,000',
      'actual_val': 300000.0,
      'benchmark_val': 250000.0,
      'explanation': 'Actual market value is ~\$300,000! One of the holy grails of modern collectibles.',
      'image': 'https://images.pokemontcg.io/base1/4_hires.png',
    },
    {
      'name': 'Apple iPhone 11 64GB',
      'category': 'Tech / Smartphone',
      'retail_year': 'Released 2019 for \$699',
      'benchmark': '\$280',
      'actual_val': 220.0,
      'benchmark_val': 280.0,
      'explanation': 'Actual market value is ~\$220! Standard smartphones suffer ~65% depreciation over 5 years.',
      'image': 'https://images.unsplash.com/photo-1591337676887-a217a6970a8a?w=300',
    },
    {
      'name': 'Nintendo Switch OLED Pokémon Scarlet Edition',
      'category': 'Console Edition',
      'retail_year': 'Released 2022 for \$359',
      'benchmark': '\$290',
      'actual_val': 310.0,
      'benchmark_val': 290.0,
      'explanation': 'Actual market value is ~\$310! Limited Pokémon editions depreciate much slower than standard SKUs.',
      'image': 'https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=300',
    },
  ];

  void _submitGuess(bool isHigher) {
    final q = _questions[_currentIndex];
    final actual = q['actual_val'] as double;
    final bench = q['benchmark_val'] as double;

    final correct = isHigher ? (actual >= bench) : (actual <= bench);

    setState(() {
      _isCorrect = correct;
      _feedback = q['explanation'] as String;
      if (correct) {
        _score += 100;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _feedback = null;
      _isCorrect = null;
      _currentIndex = (_currentIndex + 1) % _questions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: VaultColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('The Appraiser', style: VaultTypography.sectionTitle),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: VaultColors.badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VaultColors.accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: VaultColors.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$_score PTS',
                  style: VaultTypography.mono(fontSize: 12, fontWeight: FontWeight.w600, color: VaultColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink3, letterSpacing: 1),
              ),
              const SizedBox(height: 14),

              // Item Card Presentation
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: VaultColors.cardHover,
                          image: DecorationImage(
                            image: NetworkImage(q['image'] as String),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(q['name'] as String, style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(q['retail_year'] as String, style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink2)),
                      const SizedBox(height: 18),
                      Text('Is the current market value in 2026', style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.body)),
                      const SizedBox(height: 4),
                      Text(
                        'HIGHER or LOWER than ${q['benchmark']}?',
                        style: VaultTypography.mono(fontSize: 15, fontWeight: FontWeight.w600, color: VaultColors.accent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Feedback Banner
              if (_feedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isCorrect! ? VaultColors.posBg : VaultColors.negBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isCorrect! ? VaultColors.pos : VaultColors.neg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isCorrect! ? 'CORRECT! +100 PTS' : 'INCORRECT ESTIMATE',
                        style: VaultTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isCorrect! ? VaultColors.pos : VaultColors.neg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_feedback!, style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VaultColors.ink,
                      foregroundColor: VaultColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Next Item', style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: VaultColors.background)),
                  ),
                ),
              ] else ...[
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitGuess(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.posBg,
                            foregroundColor: VaultColors.pos,
                            side: const BorderSide(color: VaultColors.pos),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                          label: Text('HIGHER', style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitGuess(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.negBg,
                            foregroundColor: VaultColors.neg,
                            side: const BorderSide(color: VaultColors.neg),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                          label: Text('LOWER', style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w700)),
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
