import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/services/notification_service.dart';
import 'game_screen.dart';

/// SearchRadarScreen — Built with Apple Design Principles (WWDC & Emil Kowalski)
/// - Unified iOS Dark Secondary Surface (Color(0xFF1C1C1E))
/// - Optical sizing & negative tracking on display type
/// - Translucent floating bottom glass dock
/// - Apple Inset Grouped Table layout for catalog
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
      'title': 'Steam Autumn Market Sale',
      'subtitle': 'Counter-Strike 2 Liquidity Spike',
      'target_london': '18:00 GMT',
      'target_wib': '01:00 WIB (Tomorrow)',
      'target_wita': '02:00 WITA (Tomorrow)',
      'target_wit': '03:00 WIT (Tomorrow)',
      'category': 'Steam Market',
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
      'category': 'Pokémon TCG',
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

    final heroDrop = _globalDrops.first;

    return Scaffold(
      backgroundColor: Colors.black, // Apple True OLED Dark
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. APPLE LARGE DISPLAY TITLE (Tight tracking, negative leading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MARKET RADAR',
                          style: VaultTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: const Color(0xFF8E8E93), // iOS secondary label
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Drop Radar',
                              style: VaultTypography.sans(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                '$_selectedZone · ${_getZoneOffset(_selectedZone)}',
                                style: VaultTypography.sans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. HERO FEATURED DROP (Apple Today Story Card)
                  _buildAppleFeaturedCard(heroDrop),
                  const SizedBox(height: 12),

                  // 3. MIDDLE BENTO ROW: UPCOMING SUMMARY & THE APPRAISER
                  Row(
                    children: [
                      Expanded(child: _buildAppleUpcomingTile()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAppleAppraiserTile()),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. APPLE INSET GROUPED TABLE (Catalog & Search)
                  _buildAppleCatalogCard(filteredItems),
                ],
              ),
            ),

            // 5. APPLE FLOATING TRANSLUCENT TIMEZONE CAPSULE (Thumb Zone)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: _buildAppleFloatingDock(),
            ),
          ],
        ),
      ),
    );
  }

  // --- APPLE BENTO COMPONENTS ---

  // Component 1: Featured Drop Card (Apple Today Story Card)
  Widget _buildAppleFeaturedCard(Map<String, dynamic> drop) {
    final dropTime = _getZoneTime(drop, _selectedZone);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // iOS Secondary System Background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Overline + Countdown Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FEATURED RELEASE',
                style: VaultTypography.sans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF30D158).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live in ${drop['countdown']}',
                  style: VaultTypography.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF30D158), // Apple System Green
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            drop['title'] as String,
            style: VaultTypography.sans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            drop['subtitle'] as String,
            style: VaultTypography.sans(
              fontSize: 13.5,
              color: const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),

          // Media + Price + Apple Pill Button
          Row(
            children: [
              _buildAppleArtwork(drop['image'] as String, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop['floor_price'] as String,
                      style: VaultTypography.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dropTime,
                      style: VaultTypography.sans(
                        fontSize: 12,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              // Apple Filled Button
              GestureDetector(
                onTap: () async {
                  await NotificationService.instance.showWarrantyAlert(
                    itemName: drop['title'] as String,
                    daysLeft: 1,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF2C2C2E),
                        content: Text(
                          'Notification set for ${drop['title']}',
                          style: VaultTypography.sans(color: Colors.white),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Notify',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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

  // Component 2: Upcoming Releases Tile (Apple Stocks/Calendar Style)
  Widget _buildAppleUpcomingTile() {
    final d2 = _globalDrops[1];
    final d3 = _globalDrops[2];

    return Container(
      height: 154,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: Color(0xFF8E8E93)),
              const SizedBox(width: 5),
              Text(
                'UPCOMING',
                style: VaultTypography.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          Column(
            children: [
              _buildCompactDropRow(d2),
              const Divider(color: Color(0xFF2C2C2E), height: 12),
              _buildCompactDropRow(d3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropRow(Map<String, dynamic> drop) {
    final time = _getZoneTime(drop, _selectedZone);
    final shortTime = time.contains(' ') ? time.split(' ').first : time;

    return Row(
      children: [
        _buildAppleArtwork(drop['image'] as String, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drop['title'] as String,
                style: VaultTypography.sans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$shortTime · ${drop['countdown']}',
                style: VaultTypography.sans(
                  fontSize: 10.5,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        Text(
          drop['floor_price'] as String,
          style: VaultTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Component 3: The Appraiser Minigame Tile (Apple Arcade Style)
  Widget _buildAppleAppraiserTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      },
      child: Container(
        height: 154,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports_rounded,
                    size: 13, color: Color(0xFF8E8E93)),
                const SizedBox(width: 5),
                Text(
                  'MINIGAME',
                  style: VaultTypography.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: const Color(0xFF8E8E93),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Test your valuation intuition.',
                  style: VaultTypography.sans(
                    fontSize: 12,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Play',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: VaultColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Component 4: Apple Inset Grouped Table (Catalog & Search)
  Widget _buildAppleCatalogCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVENTORY CATALOG',
                style: VaultTypography.sans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              Text(
                '${items.length} items',
                style: VaultTypography.sans(
                  fontSize: 12,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Apple Native Search Field
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E), // Apple search bar fill
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF8E8E93)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: VaultTypography.sans(
                        fontSize: 14, color: Colors.white),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Search catalog',
                      hintStyle:
                          TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
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
                    child: const Icon(Icons.cancel_rounded,
                        size: 16, color: Color(0xFF8E8E93)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Segmented Categories (Apple Segmented Style)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: ['All', 'Collectibles', 'Tech'].map((cat) {
                final isSel = _selectedCategory == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF636366)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: VaultTypography.sans(
                          fontSize: 12,
                          fontWeight:
                              isSel ? FontWeight.w600 : FontWeight.w400,
                          color: isSel ? Colors.white : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // List Rows (Apple Inset Grouped Table with indented divider)
          _buildAppleTableRows(items),
        ],
      ),
    );
  }

  Widget _buildAppleTableRows(List<Map<String, dynamic>> items) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF8E8E93)),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        child: Text(
          'No items found',
          style: VaultTypography.sans(fontSize: 13, color: const Color(0xFF8E8E93)),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;
        final val = (item['current_valuation'] as num).toDouble();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _buildAppleArtwork(
                    item['image_url'] ??
                        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=100',
                    size: 42,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: VaultTypography.sans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${item['category']} · ${item['serial_number'] ?? 'Vault Item'}',
                          style: VaultTypography.sans(
                            fontSize: 12.5,
                            color: const Color(0xFF8E8E93),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormatter.format(val),
                    style: VaultTypography.mono(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                color: Color(0xFF2C2C2E),
                height: 1,
                indent: 56, // Classic Apple indented separator
              ),
          ],
        );
      }).toList(),
    );
  }

  // Component 5: Apple Floating Translucent Glass Dock (Thumb Zone)
  Widget _buildAppleFloatingDock() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xE61C1C1E), // Translucent Dark Glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAppleDockSegment('WIB'),
          _buildAppleDockSegment('WITA'),
          _buildAppleDockSegment('WIT'),
          _buildAppleDockSegment('London'),
        ],
      ),
    );
  }

  Widget _buildAppleDockSegment(String zone) {
    final isSelected = _selectedZone == zone;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = zone),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            zone,
            style: VaultTypography.sans(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Apple Artwork
  Widget _buildAppleArtwork(String url, {double size = 42}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        color: const Color(0xFF2C2C2E),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.inventory_2_outlined,
                size: size * 0.45, color: const Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }
}
