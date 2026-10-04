import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/services/notification_service.dart';
import 'game_screen.dart';

class SearchRadarScreen extends StatefulWidget {
  const SearchRadarScreen({super.key});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedZone = 'WIB'; // 4 Timezones: WIB, WITA, WIT, London
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;

  final currencyFormatter =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  // Global Drop Events with high-res thumbnails & 4 timezone synchronization
  final List<Map<String, dynamic>> _globalDrops = [
    {
      'id': 'drop_1',
      'title': 'Steam Autumn Community Market Sale',
      'subtitle': 'Counter-Strike 2 Rare Skins Liquidity Spike',
      'target_london': '18:00 GMT',
      'target_wib': '01:00 WIB (Besok)',
      'target_wita': '02:00 WITA',
      'target_wit': '03:00 WIT',
      'category': 'CS2 / STEAM',
      'countdown': '14h 22m',
      'floor_price': '\$1,850.00',
      'image':
          'https://community.cloudflare.steamstatic.com/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgpot621FAR17PLfYQJD_9W7m5a0mvLwOq7c2D1VvZJ13-rD99332Q22qUs9YWzwcdTAcwQ5aVDV-Fe3yee7hsfv6MjXiSw07HhTfA/360fx360f',
    },
    {
      'id': 'drop_2',
      'title': 'Pokémon TCG: Destined Fates Booster Drop',
      'subtitle': 'PSA 10 Vintage Base Set & Holographics',
      'target_london': '12:00 GMT',
      'target_wib': '19:00 WIB',
      'target_wita': '20:00 WITA',
      'target_wit': '21:00 WIT',
      'category': 'POKÉMON TCG',
      'countdown': '2d 08h',
      'floor_price': '\$420.00',
      'image': 'https://images.pokemontcg.io/ex15/100_hires.png',
    },
    {
      'id': 'drop_3',
      'title': 'Apple Worldwide Special Event & Trade-in',
      'subtitle': 'M-Series Studio Silicon Hardware Launch',
      'target_london': '17:00 GMT',
      'target_wib': '00:00 WIB',
      'target_wita': '01:00 WITA',
      'target_wit': '02:00 WIT',
      'category': 'TECH HARDWARE',
      'countdown': '5d 11h',
      'floor_price': '\$2,199.00',
      'image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=300',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getItems();
    setState(() {
      _allItems = items;
      _isLoading = false;
    });
  }

  String _getZoneTime(Map<String, dynamic> drop, String zone) {
    switch (zone) {
      case 'WITA':
        return drop['target_wita'] as String? ?? '';
      case 'WIT':
        return drop['target_wit'] as String? ?? '';
      case 'London':
        return drop['target_london'] as String? ?? '';
      case 'WIB':
      default:
        return drop['target_wib'] as String? ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = _allItems.where((item) {
      final nameMatches =
          item['name'].toString().toLowerCase().contains(query);
      final cat = item['category'].toString();

      if (_selectedCategory == 'All') return nameMatches;
      if (_selectedCategory == 'Collectibles') {
        return nameMatches && item['is_collectible'] == 1;
      }
      if (_selectedCategory == 'Tech') {
        return nameMatches && item['is_collectible'] == 0;
      }
      return nameMatches &&
          cat.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();

    final featured = _globalDrops.first;

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CLEAN HEADER (Light on the eyes, calm & refined)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: VaultColors.pos,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE MARKET RADAR',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: VaultColors.ink2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Market Radar',
                        style: VaultTypography.sans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),

                  // Sleek Timezone Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language_rounded,
                            size: 13, color: VaultColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          _selectedZone,
                          style: VaultTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. 4-ZONE SYNC SELECTOR (Clean pill bar)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    _buildZonePill('WIB', 'UTC+7'),
                    _buildZonePill('WITA', 'UTC+8'),
                    _buildZonePill('WIT', 'UTC+9'),
                    _buildZonePill('London', 'GMT+0'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. SPOTLIGHT DROP (Hero Card)
              Text(
                'FEATURED DROP',
                style: VaultTypography.mono(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 8),
              _buildSpotlightCard(featured),
              const SizedBox(height: 22),

              // 4. UPCOMING DROPS
              Text(
                'UPCOMING DROPS',
                style: VaultTypography.mono(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 10),
              ..._globalDrops.skip(1).map((drop) => _buildDropTile(drop)),
              const SizedBox(height: 20),

              // 5. THE APPRAISER MINI-GAME (Clean luxury card)
              _buildAppraiserCard(),
              const SizedBox(height: 24),

              // 6. VAULT CATALOG SEARCH
              Text(
                'CATALOG SEARCH',
                style: VaultTypography.mono(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterChips(),
              const SizedBox(height: 12),
              _buildSearchResults(filteredItems),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildZonePill(String zoneName, String utcOffset) {
    final isSelected = _selectedZone == zoneName;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = zoneName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? VaultColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                zoneName,
                style: VaultTypography.sans(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? VaultColors.background
                      : VaultColors.ink2,
                ),
              ),
              Text(
                utcOffset,
                style: VaultTypography.mono(
                  fontSize: 8.5,
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

  Widget _buildSpotlightCard(Map<String, dynamic> drop) {
    return Container(
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category & Countdown Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: VaultColors.posBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.pos,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  drop['category'] as String,
                  style: VaultTypography.mono(
                    fontSize: 9.5,
                    color: VaultColors.ink3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Artwork + Title + Price
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VaultColors.hairline),
                    image: DecorationImage(
                      image: NetworkImage(drop['image'] as String),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drop['title'] as String,
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drop: ${_getZoneTime(drop, _selectedZone)}',
                        style: VaultTypography.mono(
                          fontSize: 11,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: VaultColors.hairline, height: 1),
            const SizedBox(height: 12),

            // Bottom Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EST. VALUE',
                        style: VaultTypography.mono(
                            fontSize: 9, color: VaultColors.ink3)),
                    Text(
                      drop['floor_price'] as String,
                      style: VaultTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    await NotificationService.instance.showWarrantyAlert(
                      itemName: drop['title'] as String,
                      daysLeft: 1,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: VaultColors.card,
                          content: Text(
                            '🔔 Alert scheduled for ${drop['title']}!',
                            style:
                                VaultTypography.sans(color: VaultColors.pos),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: VaultColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 13, color: VaultColors.background),
                        const SizedBox(width: 5),
                        Text(
                          'Set Alert',
                          style: VaultTypography.sans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.background,
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
      ),
    );
  }

  Widget _buildDropTile(Map<String, dynamic> drop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: VaultColors.background,
              border: Border.all(color: VaultColors.hairline),
              image: DecorationImage(
                image: NetworkImage(drop['image'] as String),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drop['title'] as String,
                  style: VaultTypography.sans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getZoneTime(drop, _selectedZone)} · ${drop['floor_price']}',
                  style: VaultTypography.mono(
                    fontSize: 10.5,
                    color: VaultColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: VaultColors.cardHover,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              drop['countdown'] as String,
              style: VaultTypography.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: VaultColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppraiserCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: VaultColors.badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: VaultColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'The Appraiser',
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: VaultColors.cardHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MINI-GAME',
                          style: VaultTypography.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: VaultColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Higher or lower? Test your market asset valuation intuition.',
                    style: VaultTypography.sans(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: VaultColors.ink3),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: VaultColors.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style:
                  VaultTypography.sans(fontSize: 13.5, color: VaultColors.ink),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search items, serials, gear...',
                hintStyle: TextStyle(fontSize: 13, color: VaultColors.ink3),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: VaultColors.ink2),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ['All', 'Collectibles', 'Tech'].map((cat) {
          final isSel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? VaultColors.ink : VaultColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSel ? VaultColors.ink : VaultColors.hairline),
              ),
              child: Text(
                cat,
                style: VaultTypography.sans(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: isSel ? VaultColors.background : VaultColors.ink2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> items) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'No matching items found.',
          style: VaultTypography.sans(color: VaultColors.ink3),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final val = (item['current_valuation'] as num).toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VaultColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VaultColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: VaultColors.cardHover,
                  image: DecorationImage(
                    image: NetworkImage(
                      item['image_url'] ??
                          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=100',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                    ),
                    Text(
                      item['category'] as String,
                      style: VaultTypography.sans(
                        fontSize: 11,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormatter.format(val),
                style: VaultTypography.mono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
