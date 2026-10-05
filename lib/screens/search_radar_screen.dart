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
      'date_tag': 'SAT · OCT 12',
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
      'date_tag': 'TUE · OCT 15',
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

  String _getZoneCity(String zone) {
    switch (zone) {
      case 'WITA':
        return 'Makassar';
      case 'WIT':
        return 'Jayapura';
      case 'London':
        return 'London';
      case 'WIB':
      default:
        return 'Jakarta';
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

    final heroDrop = _globalDrops.first;

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. REFINED EDITORIAL HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MARKET RADAR',
                            style: VaultTypography.mono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                              color: VaultColors.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Drop Radar',
                            style: VaultTypography.sans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: VaultColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_selectedZone · ${_getZoneOffset(_selectedZone)}',
                        style: VaultTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. BENTO CELL 1: HERO SPOTLIGHT (Warm Titanium Glow + Live Pulse)
                  _buildHeroBentoCard(heroDrop),
                  const SizedBox(height: 12),

                  // 3. BENTO ROW 2: DISTINCT CELLS (Obsidian Clock Tool + Amber Minigame)
                  Row(
                    children: [
                      Expanded(child: _buildTimezoneClockTile()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAppraiserGameTile()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. BENTO ROW 3: CALENDAR DROP TILES (Date Stamp Badges)
                  Row(
                    children: [
                      Expanded(
                          child:
                              _buildCalendarDropTile(_globalDrops[1])),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              _buildCalendarDropTile(_globalDrops[2])),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. BENTO CELL 4: VAULT CATALOG & LEDGER (Data Table Canvas)
                  _buildCatalogBentoCard(filteredItems),
                ],
              ),
            ),

            // 6. ERGONOMIC BOTTOM TIMEZONE DOCK
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

  // --- BENTO CELLS WITH DISTINCT VISUAL IDENTITIES ---

  // CELL 1: HERO DROP (Warm Titanium Atmosphere & Live Pulse)
  Widget _buildHeroBentoCard(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF222019), // Warm Champagne/Titanium sheen
            Color(0xFF161513),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VaultColors.accent.withValues(alpha: 0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: VaultColors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category chip & Live countdown badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: VaultColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: VaultColors.accent.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded,
                        size: 11, color: VaultColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'FEATURED DROP',
                      style: VaultTypography.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: VaultColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                    const SizedBox(width: 6),
                    Text(
                      'Live in ${drop['countdown']}',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.pos,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Artwork + Title + Description Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtwork(
                drop['image'] as String,
                size: 58,
                fallbackIcon: drop['icon'] as IconData? ??
                    Icons.sports_esports_rounded,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop['title'] as String,
                      style: VaultTypography.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      drop['subtitle'] as String,
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        color: VaultColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            color: VaultColors.accent.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Bottom Action & Valuation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DROP: $dropTime',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.accent,
                    ),
                  ),
                  const SizedBox(height: 1),
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
                          style: VaultTypography.sans(color: VaultColors.pos),
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
                    color: VaultColors.ink,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          size: 13, color: VaultColors.background),
                      const SizedBox(width: 6),
                      Text(
                        'Set Alert',
                        style: VaultTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }

  // CELL 2: TIMEZONE CLOCK TOOL (Obsidian Blue Precision Instrument)
  Widget _buildTimezoneClockTile() {
    final heroDrop = _globalDrops.first;
    final convertedDropTime = _getZoneTime(heroDrop, _selectedZone);
    final timeOnly = convertedDropTime.contains(' ')
        ? convertedDropTime.split(' ').first
        : convertedDropTime;

    return Container(
      height: 146,
      decoration: BoxDecoration(
        color: const Color(0xFF111215), // Deep obsidian steel
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF282C36), // Steel precision border
          width: 1.1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.public_rounded,
                      size: 13, color: Color(0xFF88A0C4)),
                  const SizedBox(width: 5),
                  Text(
                    'WORLD CLOCK',
                    style: VaultTypography.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF88A0C4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4A84D6),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeOnly,
                style: VaultTypography.mono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Text(
                    _selectedZone,
                    style: VaultTypography.sans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A84D6),
                    ),
                  ),
                  Text(
                    ' · ${_getZoneCity(_selectedZone)}',
                    style: VaultTypography.sans(
                      fontSize: 11.5,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Active target base',
            style: VaultTypography.mono(
              fontSize: 9.5,
              color: VaultColors.ink3,
            ),
          ),
        ],
      ),
    );
  }

  // CELL 3: THE APPRAISER (Warm Amber Game Card with Interactive Chips)
  Widget _buildAppraiserGameTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 146,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF261D15), // Warm Amber arcade glow
              Color(0xFF181512),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF70522B), // Warm brass border
            width: 1.1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded,
                        size: 13, color: VaultColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      'MINIGAME',
                      style: VaultTypography.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: VaultColors.accent,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: VaultColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PLAY',
                    style: VaultTypography.mono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Appraiser',
                  style: VaultTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                // Playful Higher/Lower chip preview
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: VaultColors.pos.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '▲ HIGHER',
                        style: VaultTypography.mono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.pos,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: VaultColors.neg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '▼ LOWER',
                        style: VaultTypography.mono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.neg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Start Game',
                  style: VaultTypography.sans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 11, color: VaultColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // CELLS 4 & 5: CALENDAR RELEASE TILES (Date Stamp Headers)
  Widget _buildCalendarDropTile(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);
    final dateTag = drop['date_tag'] as String? ?? 'UPCOMING';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171716), // Slate matte
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaultColors.hairline),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distinct Date Stamp Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: VaultColors.ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: VaultColors.hairline,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 9.5, color: VaultColors.ink2),
                    const SizedBox(width: 4),
                    Text(
                      dateTag,
                      style: VaultTypography.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                drop['countdown'] as String,
                style: VaultTypography.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Artwork & Title
          Row(
            children: [
              _buildArtwork(
                drop['image'] as String,
                size: 38,
                fallbackIcon:
                    drop['icon'] as IconData? ?? Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop['title'] as String,
                      style: VaultTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      drop['category'] as String,
                      style: VaultTypography.sans(
                        fontSize: 10.5,
                        color: VaultColors.ink3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: VaultColors.hairline, height: 1),
          const SizedBox(height: 8),

          // Time & Floor Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dropTime.contains(' ') ? dropTime.split(' ').first : dropTime,
                style: VaultTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: VaultColors.ink2,
                ),
              ),
              Text(
                drop['floor_price'] as String,
                style: VaultTypography.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: VaultColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CELL 6: VAULT CATALOG & FINANCIAL LEDGER BENTO CARD
  Widget _buildCatalogBentoCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141413),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VaultColors.hairline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined,
                      size: 13, color: VaultColors.ink3),
                  const SizedBox(width: 6),
                  Text(
                    'INVENTORY LEDGER',
                    style: VaultTypography.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                ],
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
          const SizedBox(height: 12),

          // Search Box with distinct input container
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: VaultColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 16, color: VaultColors.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: VaultTypography.sans(
                        fontSize: 13, color: VaultColors.ink),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Search items, serials...',
                      hintStyle:
                          TextStyle(fontSize: 12.5, color: VaultColors.ink3),
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
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: VaultColors.ink2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Collectibles', 'Tech'].map((cat) {
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? VaultColors.ink : VaultColors.cardHover,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSel ? VaultColors.ink : VaultColors.hairline,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: VaultTypography.sans(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSel ? VaultColors.background : VaultColors.ink2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: VaultColors.hairline, height: 1),

          // Order Book List Items
          _buildLedgerItems(items),
        ],
      ),
    );
  }

  Widget _buildLedgerItems(List<Map<String, dynamic>> items) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        child: Text(
          'No matching items found.',
          style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink3),
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              _buildArtwork(
                item['image_url'] ??
                    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=100',
                size: 38,
                fallbackIcon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: VaultTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1.5),
                    Row(
                      children: [
                        Text(
                          item['category'] as String,
                          style: VaultTypography.sans(
                            fontSize: 11,
                            color: VaultColors.ink2,
                          ),
                        ),
                        if (item['serial_number'] != null &&
                            item['serial_number'].toString().isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: VaultTypography.mono(
                              fontSize: 9.5,
                              color: VaultColors.ink3,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item['serial_number'].toString(),
                              style: VaultTypography.mono(
                                fontSize: 9.5,
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
              const SizedBox(width: 8),
              Text(
                currencyFormatter.format(val),
                style: VaultTypography.mono(
                  fontSize: 13.5,
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

  // --- ERGONOMIC BOTTOM TIMEZONE DOCK ---

  Widget _buildBottomZoneDock() {
    return Container(
      height: 50,
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
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? VaultColors.accent : VaultColors.ink2,
                ),
              ),
              Text(
                offset,
                style: VaultTypography.mono(
                  fontSize: 9,
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
