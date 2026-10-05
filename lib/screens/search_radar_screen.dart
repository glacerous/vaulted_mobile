import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/services/notification_service.dart';
import 'game_screen.dart';

class SearchRadarScreen extends StatefulWidget {
  const SearchRadarScreen({super.key});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen> {
  String _selectedCategory = 'All';
  String _selectedZone = 'WIB'; // 4 Timezones: WIB, WITA, WIT, LON (London)

  // Global Drop Events with real artwork & multi-timezone synchronization
  final List<Map<String, dynamic>> _globalDrops = [
    {
      'id': 'drop_1',
      'title': 'Steam Autumn Market Sale',
      'subtitle': 'Counter-Strike 2 Liquidity Spike',
      'target_london': '18:00 GMT',
      'target_wib': '01:00 WIB (Tomorrow)',
      'target_wita': '02:00 WITA (Tomorrow)',
      'target_wit': '03:00 WIT (Tomorrow)',
      'category': 'Gaming',
      'countdown': '14h 22m',
      'floor_price': '\$1,850.00',
      'image':
          'https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=300',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'drop_2',
      'title': 'Pokémon TCG Booster Drop',
      'subtitle': 'PSA 10 Vintage Base Set',
      'target_london': '12:00 GMT',
      'target_wib': '19:00 WIB',
      'target_wita': '20:00 WITA',
      'target_wit': '21:00 WIT',
      'category': 'Collectibles',
      'countdown': '2d 08h',
      'floor_price': '\$420.00',
      'image': 'https://images.pokemontcg.io/ex15/100_hires.png',
      'icon': Icons.layers_outlined,
    },
    {
      'id': 'drop_3',
      'title': 'Apple Worldwide Special Event',
      'subtitle': 'M-Series Studio Silicon Launch',
      'target_london': '17:00 GMT',
      'target_wib': '00:00 WIB',
      'target_wita': '01:00 WITA',
      'target_wit': '02:00 WIT',
      'category': 'Hardware',
      'countdown': '5d 11h',
      'floor_price': '\$2,199.00',
      'image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=300',
      'icon': Icons.devices_other_rounded,
    },
    {
      'id': 'drop_4',
      'title': 'Phillips Geneva Watch Auction',
      'subtitle': 'Vintage Cosmograph Daytona Lot',
      'target_london': '14:00 GMT',
      'target_wib': '21:00 WIB',
      'target_wita': '22:00 WITA',
      'target_wit': '23:00 WIT',
      'category': 'Luxury',
      'countdown': '8d 04h',
      'floor_price': '\$34,500.00',
      'image':
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300',
      'icon': Icons.watch_outlined,
    },
  ];

  String _getZoneTime(Map<String, dynamic> drop, String zone) {
    switch (zone) {
      case 'WITA':
        return drop['target_wita'] as String? ?? '';
      case 'WIT':
        return drop['target_wit'] as String? ?? '';
      case 'LON':
      case 'London':
        return drop['target_london'] as String? ?? '';
      case 'WIB':
      default:
        return drop['target_wib'] as String? ?? '';
    }
  }

  Future<void> _triggerAlert(String title) async {
    await NotificationService.instance.showWarrantyAlert(
      itemName: title,
      daysLeft: 1,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VaultColors.card,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: VaultColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alert scheduled for $title',
                  style: VaultTypography.sans(
                      fontSize: 12.5, color: VaultColors.ink),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrops = _globalDrops.where((drop) {
      if (_selectedCategory == 'All') return true;
      return drop['category'] == _selectedCategory;
    }).toList();

    final heroDrop = _globalDrops.first;
    final otherDrops = filteredDrops.where((d) => d['id'] != heroDrop['id']).toList();

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BRAND HEADER (Matching HomeVaultScreen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.brightness_low_rounded,
                        color: VaultColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VAULT',
                        style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·  RADAR',
                        style: VaultTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VaultColors.card,
                      border: Border.all(color: VaultColors.hairline, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'A',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. TITLE & CONTEXT
              Text(
                'Market Radar',
                style: VaultTypography.sans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Synchronized drop events across international markets.',
                style: VaultTypography.sans(
                  fontSize: 13,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 16),

              // 3. SYNCHRONIZED TIMEZONE BAR (Full-width, tactile thumb switcher)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    _buildZoneSegment('WIB', 'UTC+7'),
                    _buildZoneSegment('WITA', 'UTC+8'),
                    _buildZoneSegment('WIT', 'UTC+9'),
                    _buildZoneSegment('LON', 'GMT+0'),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. SPOTLIGHT / HERO DROP
              _buildSpotlightCard(heroDrop),
              const SizedBox(height: 24),

              // 5. CATEGORY FILTER CHIPS FOR DROPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Gaming', 'Collectibles', 'Hardware', 'Luxury']
                      .map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? VaultColors.ink : VaultColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? VaultColors.ink : VaultColors.hairline,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: VaultTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? VaultColors.background
                                  : VaultColors.ink2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // 6. UPCOMING RELEASES (Full-width un-cramped cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UPCOMING RELEASES',
                    style: VaultTypography.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: VaultColors.ink2,
                    ),
                  ),
                  Text(
                    '${otherDrops.length} drops scheduled',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      color: VaultColors.ink3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (otherDrops.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'No scheduled drops in this category.',
                    style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink3),
                  ),
                )
              else
                ...otherDrops.map((drop) => _buildUpcomingDropTile(drop)),
              const SizedBox(height: 16),

              // 7. THE APPRAISER (Full width interactive banner)
              _buildAppraiserBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUBCOMPONENTS ---

  Widget _buildZoneSegment(String zone, String offset) {
    final isSelected = _selectedZone == zone;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = zone),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? VaultColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                zone,
                style: VaultTypography.mono(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? VaultColors.background : VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                offset,
                style: VaultTypography.mono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? VaultColors.background.withValues(alpha: 0.7)
                      : VaultColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Full-Width Spotlight Hero Drop
  Widget _buildSpotlightCard(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Container(
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FEATURED DROP',
                style: VaultTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: VaultColors.posBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VaultColors.pos,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live in ${drop['countdown']}',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.pos,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVaultArtwork(drop['image'] as String, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop['title'] as String,
                      style: VaultTypography.sans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: VaultColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      drop['subtitle'] as String,
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Divider(color: VaultColors.hairline, height: 1),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drop['floor_price'] as String,
                    style: VaultTypography.mono(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dropTime,
                    style: VaultTypography.mono(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _triggerAlert(drop['title'] as String),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: VaultColors.cardHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          size: 14, color: VaultColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Set Alert',
                        style: VaultTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Full-Width Upcoming Drop Tile
  Widget _buildUpcomingDropTile(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Row(
        children: [
          _buildVaultArtwork(drop['image'] as String, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drop['title'] as String,
                  style: VaultTypography.sans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dropTime,
                      style: VaultTypography.mono(
                        fontSize: 10.5,
                        color: VaultColors.ink2,
                      ),
                    ),
                    Text(' · ',
                        style: VaultTypography.mono(
                            fontSize: 10, color: VaultColors.ink3)),
                    Text(
                      'in ${drop['countdown']}',
                      style: VaultTypography.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: VaultColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                drop['floor_price'] as String,
                style: VaultTypography.mono(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _triggerAlert(drop['title'] as String),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: VaultColors.cardHover,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Text(
                    'Alert',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Full-Width Appraiser Banner
  Widget _buildAppraiserBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VaultColors.hairline),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.sports_esports_outlined,
                  size: 22, color: VaultColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'THE APPRAISER',
                        style: VaultTypography.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: VaultColors.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: VaultColors.posBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MINIGAME',
                          style: VaultTypography.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.pos,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Test your valuation accuracy.',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Guess prices on live collectible items.',
                    style: VaultTypography.sans(
                      fontSize: 11.5,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: VaultColors.cardHover,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VaultColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Play',
                    style: VaultTypography.sans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 11, color: VaultColors.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Artwork Thumbnail
  Widget _buildVaultArtwork(String url, {double size = 42}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: VaultColors.background,
        border: Border.all(color: VaultColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.inventory_2_outlined,
                size: size * 0.45, color: VaultColors.ink3),
          ),
        ),
      ),
    );
  }
}
