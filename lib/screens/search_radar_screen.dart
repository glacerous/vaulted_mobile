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

  // Global Drop Events with real artwork & timezone synchronization
  final List<Map<String, dynamic>> _globalDrops = [
    {
      'id': 'drop_1',
      'title': 'Steam Autumn Community Market Sale',
      'subtitle': 'Counter-Strike 2 Rare Skins Liquidity Spike',
      'target_london': '18:00 GMT',
      'target_wib': '01:00 WIB (Besok)',
      'target_wita': '02:00 WITA',
      'target_wit': '03:00 WIT',
      'category': 'CS2 / Steam Market',
      'countdown': '14h 22m',
      'floor_price': '\$1,850.00',
      'image':
          'https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=300',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'drop_2',
      'title': 'Pokémon TCG: Destined Fates Booster Drop',
      'subtitle': 'PSA 10 Vintage Base Set & Holographics',
      'target_london': '12:00 GMT',
      'target_wib': '19:00 WIB',
      'target_wita': '20:00 WITA',
      'target_wit': '21:00 WIT',
      'category': 'Pokémon TCG',
      'countdown': '2d 08h',
      'floor_price': '\$420.00',
      'image': 'https://images.pokemontcg.io/ex15/100_hires.png',
      'icon': Icons.layers_outlined,
    },
    {
      'id': 'drop_3',
      'title': 'Apple Worldwide Special Event & Trade-in',
      'subtitle': 'M-Series Studio Silicon Hardware Launch',
      'target_london': '17:00 GMT',
      'target_wib': '00:00 WIB',
      'target_wita': '01:00 WITA',
      'target_wit': '02:00 WIT',
      'category': 'Tech Hardware',
      'countdown': '5d 11h',
      'floor_price': '\$2,199.00',
      'image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=300',
      'icon': Icons.devices_other_rounded,
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

  String _getZoneOffset(String zone) {
    switch (zone) {
      case 'WITA':
        return 'UTC+8';
      case 'WIT':
        return 'UTC+9';
      case 'London':
        return 'GMT+0';
      case 'WIB':
      default:
        return 'UTC+7';
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

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 1. REFINED EDITORIAL HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MARKET DROPS',
                              style: VaultTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: VaultColors.accent,
                              ),
                            ),
                            Text(
                              '$_selectedZone (${_getZoneOffset(_selectedZone)})',
                              style: VaultTypography.mono(
                                fontSize: 10.5,
                                color: VaultColors.ink3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                          'Track upcoming releases synchronized to your local time.',
                          style: VaultTypography.sans(
                            fontSize: 13.5,
                            color: VaultColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  const Divider(color: VaultColors.hairline, height: 1),

                  // 2. UPCOMING DROPS SECTION
                  _buildUpcomingDropsSection(),

                  const SizedBox(height: 14),

                  // 3. THE APPRAISER (MINIGAME)
                  _buildAppraiserBanner(),

                  const SizedBox(height: 18),

                  // 4. CATALOG & INVENTORY SEARCH
                  _buildCatalogSection(filteredItems),
                ],
              ),
            ),

            // 5. ERGONOMIC BOTTOM TIMEZONE DOCK
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomZoneDock(),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION: UPCOMING DROPS ---

  Widget _buildUpcomingDropsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPCOMING DROPS',
                style: VaultTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              Text(
                '${_globalDrops.length} drops scheduled',
                style: VaultTypography.sans(
                  fontSize: 12,
                  color: VaultColors.ink3,
                ),
              ),
            ],
          ),
        ),

        // Hero Drop (Featured)
        _buildHeroDropItem(_globalDrops[0]),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: VaultColors.hairline, height: 1),
        ),
        const SizedBox(height: 12),

        // Subsequent Drops
        _buildSubsequentDropItem(_globalDrops[1]),
        _buildSubsequentDropItem(_globalDrops[2]),
      ],
    );
  }

  Widget _buildHeroDropItem(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time & Countdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(width: 8),
                  Text(
                    dropTime,
                    style: VaultTypography.mono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  ),
                ],
              ),
              Text(
                'Live in ${drop['countdown']}',
                style: VaultTypography.mono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.pos,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            drop['title'] as String,
            style: VaultTypography.sans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: VaultColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            drop['subtitle'] as String,
            style: VaultTypography.sans(
              fontSize: 13,
              color: VaultColors.ink2,
            ),
          ),

          const SizedBox(height: 14),

          // Artwork + Price + Set Alert Row
          Row(
            children: [
              _buildArtwork(
                drop['image'] as String,
                size: 50,
                fallbackIcon: drop['icon'] as IconData? ??
                    Icons.sports_esports_rounded,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EST. FLOOR PRICE',
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      color: VaultColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    drop['floor_price'] as String,
                    style: VaultTypography.mono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Set Alert Action Button
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
                          '🔔 Alert set for ${drop['title']}!',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: VaultColors.hairline, width: 1.1),
                    borderRadius: BorderRadius.circular(8),
                    color: VaultColors.cardHover,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_outlined,
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

  Widget _buildSubsequentDropItem(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildArtwork(
            drop['image'] as String,
            size: 42,
            fallbackIcon:
                drop['icon'] as IconData? ?? Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dropTime,
                      style: VaultTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· in ${drop['countdown']}',
                      style: VaultTypography.mono(
                        fontSize: 11,
                        color: VaultColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  drop['title'] as String,
                  style: VaultTypography.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  drop['category'] as String,
                  style: VaultTypography.sans(
                    fontSize: 11.5,
                    color: VaultColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            drop['floor_price'] as String,
            style: VaultTypography.mono(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: VaultColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION: THE APPRAISER (MINIGAME) ---

  Widget _buildAppraiserBanner() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: VaultColors.hairline, width: 0.9),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: VaultColors.badgeBg,
                border: Border.all(color: VaultColors.hairline),
              ),
              child: const Icon(
                Icons.sports_esports_outlined,
                size: 18,
                color: VaultColors.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'The Appraiser',
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: VaultColors.cardHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MINIGAME',
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
                    'Higher or lower? Test your market pricing knowledge',
                    style: VaultTypography.sans(
                      fontSize: 12.5,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  'Play',
                  style: VaultTypography.sans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: VaultColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION: CATALOG & INVENTORY SEARCH ---

  Widget _buildCatalogSection(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATALOG',
                style: VaultTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              Text(
                '${items.length} items',
                style: VaultTypography.sans(
                  fontSize: 11.5,
                  color: VaultColors.ink3,
                ),
              ),
            ],
          ),
        ),

        // Ergonomic Search Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: VaultColors.ink3),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: VaultTypography.sans(
                        fontSize: 13.5, color: VaultColors.ink),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Search items, serials...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: VaultColors.ink3),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: VaultColors.ink2),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Flat Category Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['All', 'Collectibles', 'Tech'].map((cat) {
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSel ? VaultColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: VaultTypography.sans(
                      fontSize: 12.5,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? VaultColors.ink : VaultColors.ink3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(color: VaultColors.hairline, height: 1),

        // Ledger Rows
        _buildOrderBookRows(items),
      ],
    );
  }

  Widget _buildOrderBookRows(List<Map<String, dynamic>> items) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(36),
        alignment: Alignment.center,
        child: Text(
          'No items matching query.',
          style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final val = (item['current_valuation'] as num).toDouble();
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: VaultColors.hairline, width: 0.8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              _buildArtwork(
                item['image_url'] ??
                    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=100',
                size: 44,
                fallbackIcon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: VaultTypography.sans(
                        fontSize: 14,
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
                          item['category'] as String,
                          style: VaultTypography.sans(
                            fontSize: 11.5,
                            color: VaultColors.ink2,
                          ),
                        ),
                        if (item['serial_number'] != null &&
                            item['serial_number'].toString().isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              color: VaultColors.ink3,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item['serial_number'].toString(),
                              style: VaultTypography.mono(
                                fontSize: 10.5,
                                color: VaultColors.ink3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                currencyFormatter.format(val),
                style: VaultTypography.mono(
                  fontSize: 14.5,
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

  // --- SECTION: ERGONOMIC FLUSH BOTTOM TIMEZONE DOCK ---

  Widget _buildBottomZoneDock() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFA131312),
        border: Border(
          top: BorderSide(color: VaultColors.hairline, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _buildZoneTab('WIB', 'UTC+7'),
          _buildZoneTab('WITA', 'UTC+8'),
          _buildZoneTab('WIT', 'UTC+9'),
          _buildZoneTab('London', 'GMT+0'),
        ],
      ),
    );
  }

  Widget _buildZoneTab(String zone, String offset) {
    final isSelected = _selectedZone == zone;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedZone = zone),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? VaultColors.accent : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone,
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? VaultColors.accent : VaultColors.ink2,
                ),
              ),
              Text(
                offset,
                style: VaultTypography.mono(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? VaultColors.accent.withValues(alpha: 0.85)
                      : VaultColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE ARTWORK HELPER ---

  Widget _buildArtwork(String url,
      {double size = 44, IconData fallbackIcon = Icons.inventory_2_outlined}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: VaultColors.cardHover,
        border: Border.all(color: VaultColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: VaultColors.cardHover,
            alignment: Alignment.center,
            child: Icon(fallbackIcon,
                size: size * 0.45, color: VaultColors.accent),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: VaultColors.cardHover,
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: VaultColors.ink3,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
