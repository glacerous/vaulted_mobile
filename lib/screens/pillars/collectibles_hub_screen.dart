import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import 'steam_import_screen.dart';
import 'inventory_screen.dart';
import 'collectibles_screen.dart';

class CollectiblesHubScreen extends StatelessWidget {
  const CollectiblesHubScreen({super.key});

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

            // Main Grid Section (Screenshot 1)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Row 1: Pokémon TCG & Steam items
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

  // 2. Steam items Card
  Widget _buildSteamCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SteamImportScreen()),
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
                    const Icon(Icons.sports_esports_rounded, size: 16, color: VaultColors.ink2),
                    const SizedBox(width: 8),
                    Text('Steam items', style: VaultTypography.cardLabel),
                  ],
                ),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink2),
              ],
            ),
            const SizedBox(height: 2),
            Text('CS2 · Dota 2 · TF2 · cards', style: VaultTypography.cardSub),
            const SizedBox(height: 20),
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
            const SizedBox(height: 18),
            Text(
              'Paste your profile link and your public inventory files itself in — CS2, Dota 2, TF2, cards — valued off the Community Market.',
              style: VaultTypography.cardDescription,
            ),
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
