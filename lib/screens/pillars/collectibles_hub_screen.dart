import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/utils/image_utils.dart';
import 'steam_import_screen.dart';
import 'inventory_screen.dart';
import 'collectibles_screen.dart';

import '../../core/database/database_helper.dart';

class CollectiblesHubScreen extends StatefulWidget {
  const CollectiblesHubScreen({super.key});

  @override
  State<CollectiblesHubScreen> createState() => _CollectiblesHubScreenState();
}

class _CollectiblesHubScreenState extends State<CollectiblesHubScreen> {
  List<Map<String, dynamic>> _steamItems = [];
  double _steamTotal = 0.0;
  String _steamSort = 'Value ↓';

  List<Map<String, dynamic>> get _sortedSteamItems {
    final list = List<Map<String, dynamic>>.from(_steamItems);
    switch (_steamSort) {
      case 'Value ↓':
        list.sort((a, b) => ((b['current_valuation'] as num?)?.toDouble() ?? 0.0)
            .compareTo((a['current_valuation'] as num?)?.toDouble() ?? 0.0));
        break;
      case 'Value ↑':
        list.sort((a, b) => ((a['current_valuation'] as num?)?.toDouble() ?? 0.0)
            .compareTo((b['current_valuation'] as num?)?.toDouble() ?? 0.0));
        break;
      case 'Name A-Z':
        list.sort((a, b) => (a['name'] as String? ?? '').toLowerCase().compareTo((b['name'] as String? ?? '').toLowerCase()));
        break;
      case 'Game':
        list.sort((a, b) => (a['category'] as String? ?? '').toLowerCase().compareTo((b['category'] as String? ?? '').toLowerCase()));
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await DatabaseHelper.instance.getItems();
    final steam = all.where((i) => i['category'].toString().startsWith('Steam')).toList();
    double total = 0.0;
    for (var i in steam) {
      total += (i['current_valuation'] as num).toDouble();
    }
    if (mounted) {
      setState(() {
        _steamItems = steam;
        _steamTotal = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Breadcrumb Header (Screenshot 1: < VAULT      COLLECTIBLES)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: VaultColors.ink2),
                        const SizedBox(width: 6),
                        Text(
                          'VAULT',
                          style: VaultTypography.sans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Text(
                      'COLLECTIBLES',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Grid Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPokemonCard(context),
                  const SizedBox(height: 14),
                  _buildSteamCard(context),
                  const SizedBox(height: 14),
                  _buildFashionCard(context),
                  const SizedBox(height: 14),
                  _buildOnePieceCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Pokémon TCG Card
  Widget _buildPokemonCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CollectiblesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style_outlined, size: 16, color: VaultColors.ink2),
                    const SizedBox(width: 8),
                    Text('Pokémon TCG', style: VaultTypography.cardLabel),
                  ],
                ),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink2),
              ],
            ),
            const SizedBox(height: 2),
            Text('1 card', style: VaultTypography.cardSub),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$27,500.00',
                  style: VaultTypography.mono(fontSize: 24, fontWeight: FontWeight.w500, color: VaultColors.ink),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VaultColors.posBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r'+$27,479.00',
                    style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.pos),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 130,
                width: 95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: const DecorationImage(
                    image: NetworkImage('https://images.pokemontcg.io/ex15/100_hires.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Steam items Card (Live synced)
  Widget _buildSteamCard(BuildContext context) {
    final bool hasItems = _steamItems.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SteamImportScreen()),
        );
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasItems ? VaultColors.pos.withValues(alpha: 0.4) : VaultColors.hairline,
            width: hasItems ? 1.2 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded, size: 16, color: VaultColors.accent),
                    const SizedBox(width: 8),
                    Text('Steam items', style: VaultTypography.cardLabel),
                    if (hasItems) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: VaultColors.posBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SYNCED',
                          style: VaultTypography.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.pos,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink2),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hasItems ? '${_steamItems.length} items · Synced with @xel' : 'Community Cards · Avatars · In-game Items',
              style: VaultTypography.cardSub,
            ),
            const SizedBox(height: 12),

            if (hasItems) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$${_steamTotal.toStringAsFixed(2)}',
                    style: VaultTypography.mono(fontSize: 24, fontWeight: FontWeight.w500, color: VaultColors.ink),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VaultColors.posBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VALVE SYNCED',
                      style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.pos),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Interactive Thumb-Zone Sort Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SORT BY',
                    style: VaultTypography.mono(fontSize: 9.5, letterSpacing: 1.1, color: VaultColors.ink2),
                  ),
                  Row(
                    children: ['Value ↓', 'Value ↑', 'Name A-Z', 'Game'].map((sortKey) {
                      final isSelected = _steamSort == sortKey;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _steamSort = sortKey);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? VaultColors.accent : VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? VaultColors.accent : VaultColors.hairline,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            sortKey,
                            style: VaultTypography.mono(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? VaultColors.background : VaultColors.ink2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Real preview thumbnails
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _sortedSteamItems.map((item) {
                    final imgUrl = vaultImageUrl(item['image_url'] as String?);
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VaultColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.network(
                              imgUrl,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.sports_esports_rounded, size: 36, color: VaultColors.ink2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['name'] as String? ?? '',
                            style: VaultTypography.sans(fontSize: 11, fontWeight: FontWeight.w600, color: VaultColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${(item['current_valuation'] as num).toDouble().toStringAsFixed(2)}',
                            style: VaultTypography.mono(fontSize: 11, fontWeight: FontWeight.w600, color: VaultColors.accent),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (idx) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: VaultColors.cardHover,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: const Icon(Icons.sports_esports_outlined, color: VaultColors.ink3, size: 18),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '1-Tap connect to Steam and your authenticated inventory files itself in — valued off the Community Market.',
                style: VaultTypography.cardDescription,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 3. Fashion & Luxury Card
  Widget _buildFashionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checkroom_rounded, size: 16, color: VaultColors.ink2),
                    const SizedBox(width: 8),
                    Text('Fashion & Luxury', style: VaultTypography.cardLabel),
                  ],
                ),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink2),
              ],
            ),
            const SizedBox(height: 2),
            Text('Add your first', style: VaultTypography.cardSub),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLuxuryIcon(Icons.snowshoeing_rounded),
                  _buildLuxuryIcon(Icons.watch_rounded),
                  _buildLuxuryIcon(Icons.shopping_bag_outlined),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'WATCHES · SNEAKERS · BAGS',
                style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.5, color: VaultColors.ink3),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your grails go here — scan a piece and track what you paid against its resale value.',
              style: VaultTypography.cardDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: VaultColors.cardHover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Icon(icon, color: VaultColors.accent.withValues(alpha: 0.8), size: 20),
    );
  }

  // 4. One Piece TCG Card
  Widget _buildOnePieceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.style_outlined, size: 16, color: VaultColors.ink2),
                  const SizedBox(width: 8),
                  Text('One Piece TCG', style: VaultTypography.cardLabel),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: VaultColors.cardHover,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Text(
                  'COMING SOON',
                  style: VaultTypography.mono(fontSize: 9, fontWeight: FontWeight.w600, color: VaultColors.ink2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text("Bandai's card game", style: VaultTypography.cardSub),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 36,
                  height: 52,
                  decoration: BoxDecoration(
                    color: VaultColors.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VaultColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.wb_sunny_outlined, color: VaultColors.accent, size: 18),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'The straw-hat grails are next — same live-market tracking as Pokémon.',
            style: VaultTypography.cardDescription,
          ),
        ],
      ),
    );
  }
}
