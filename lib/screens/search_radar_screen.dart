import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/services/notification_service.dart';
import '../core/widgets/valto_mascot.dart';
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
      'title': 'Steam Halloween Sale',
      'subtitle': 'Spooky bundles, cosmetics & market spike',
      'target_london': '17:00 GMT',
      'target_wib': '00:00 WIB (Oct 29)',
      'target_wita': '01:00 WITA (Oct 29)',
      'target_wit': '02:00 WIT (Oct 29)',
      'category': 'Gaming',
      'countdown': '9d 05h',
      'floor_price': 'Up to 90% off',
      'image':
          'https://images.unsplash.com/photo-1612287232213-9111c1070e17?w=300',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'drop_3',
      'title': 'Steam Winter Holiday Grand Sale',
      'subtitle': 'Valve Annual Trading Card & Badge Event',
      'target_london': '18:00 GMT',
      'target_wib': '01:00 WIB (Dec 19)',
      'target_wita': '02:00 WITA (Dec 19)',
      'target_wit': '03:00 WIT (Dec 19)',
      'category': 'Gaming',
      'countdown': '58d 14h',
      'floor_price': 'Up to 90% off',
      'image':
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300',
      'icon': Icons.sports_esports_rounded,
    },
    {
      'id': 'drop_4',
      'title': 'CS2 Major Championship Drops',
      'subtitle': 'Valve Souvenir Packages & Gold Stickers',
      'target_london': '15:00 GMT',
      'target_wib': '22:00 WIB',
      'target_wita': '23:00 WITA',
      'target_wit': '00:00 WIT',
      'category': 'Collectibles',
      'countdown': '12d 08h',
      'floor_price': '\$4,250.00',
      'image':
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=300',
      'icon': Icons.verified_outlined,
    },
    {
      'id': 'drop_5',
      'title': 'Steam Spring Skin Showcase',
      'subtitle': 'Doppler Gems & Contraband Finishes',
      'target_london': '17:00 GMT',
      'target_wib': '00:00 WIB (Mar 13)',
      'target_wita': '01:00 WITA (Mar 13)',
      'target_wit': '02:00 WIT (Mar 13)',
      'category': 'Collectibles',
      'countdown': '142d 10h',
      'floor_price': '\$12,400.00',
      'image':
          'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300',
      'icon': Icons.sports_esports_rounded,
    },
  ];

  // --- FEATURED UPCOMING EVENTS (carousel) ---
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _featuredIndex = 0;
  final Set<String> _alertedEvents = {};
  Timer? _ticker;
  final Map<String, Timer> _alertTimers = {};

  static const List<String> _zones = ['WIB', 'WITA', 'WIT', 'LON'];
  // 💡 DOSEN LIVE CHALLENGE: TIMEZONE OFFSETS (WIB, WITA, WIT, London GMT)
  static const Map<String, int> _zoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'LON': 0,
  };

  late List<Map<String, dynamic>> _featuredEvents = _buildFeaturedEvents();

  @override
  void initState() {
    super.initState();
    // Perbarui hitung mundur setiap 10 detik
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
    _fetchLiveSteamEvents();
  }

  Future<void> _fetchLiveSteamEvents() async {
    try {
      final uri = Uri.parse(
        'https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=730&count=4',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = data['appnews']?['newsitems'] as List?;
        if (items != null && items.isNotEmpty) {
          final List<Map<String, dynamic>> liveList = [];
          final testEvt = _featuredEvents.firstWhere(
            (e) => e['is_test'] == true,
            orElse: () => _buildFeaturedEvents().first,
          );
          liveList.add(testEvt);

          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final title = item['title']?.toString() ?? 'Valve Steam Event';
            final contents = item['contents']?.toString() ?? '';
            final cleanDesc = contents
                .replaceAll(RegExp(r'<[^>]*>|\[\/?\w+[^\]]*\]'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            final shortDesc = cleanDesc.length > 180
                ? '${cleanDesc.substring(0, 180)}...'
                : cleanDesc;
            final imgMatch = RegExp(r'https?://[^\s"<>]+?\.(?:jpg|jpeg|png|webp)')
                .firstMatch(contents);
            final imageUrl = imgMatch?.group(0) ??
                'https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=300';
            final nowUtc = DateTime.now().toUtc();
            final scheduledStart = nowUtc.add(Duration(hours: (i + 1) * 8, minutes: i * 15));

            liveList.add({
              'id': 'live_steam_${item['gid'] ?? i}',
              'title': title,
              'subtitle': 'Valve Official · Steam Community Market',
              'category': 'Gaming',
              'mode': 'Online',
              'start': scheduledStart,
              'venue': 'Steam Community Market (Global)',
              'floor_price': 'Live Steam Feed',
              'description': shortDesc.isNotEmpty ? shortDesc : 'Official Steam Counter-Strike 2 community announcement and market event.',
              'image': imageUrl,
              'is_live': true,
              'is_steam_sale': true,
              'url': item['url']?.toString(),
            });
          }
          for (var evt in _buildFeaturedEvents()) {
            if (evt['is_test'] != true && liveList.length < 8) {
              liveList.add(evt);
            }
          }
          if (mounted) {
            setState(() {
              _featuredEvents = liveList;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[SearchRadarScreen] Live Steam API fallback: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final t in _alertTimers.values) {
      t.cancel();
    }
    _pageController.dispose();
    super.dispose();
  }

  // 5 event mendatang. Waktu mulai disimpan dalam UTC lalu dikonversi ke WIB/WITA/WIT/London.
  // Tanggal dihitung relatif dari hari ini supaya data demo tidak kedaluwarsa.
  // Ganti `at(...)` dengan DateTime.utc(tahun, bulan, tanggal, jam, menit) untuk tanggal tetap.
  List<Map<String, dynamic>> _buildFeaturedEvents() {
    final now = DateTime.now().toUtc();
    DateTime at(int daysFromNow, int hour, [int minute = 0]) =>
        DateTime.utc(now.year, now.month, now.day + daysFromNow, hour, minute);

    return [
      {
        'id': 'evt_1',
        'title': 'Steam Autumn Market Sale',
        'subtitle': 'Counter-Strike 2 Liquidity Spike',
        'category': 'Gaming',
        'mode': 'Online',
        'is_test': true,
        'is_steam_sale': true,
        'start': now.add(const Duration(minutes: 2)),
        'venue': 'Online · Steam Community Market',
        'floor_price': 'Market Surge',
        'description': 'Official Steam seasonal sale with a massive surge in Community Market trading volume for CS2 skins, weapon cases, and trading cards. Asset prices fluctuate actively during the opening hours.',
        'image': 'https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=300',
      },
      {
        'id': 'evt_2',
        'title': 'Steam Winter Holiday Grand Sale',
        'subtitle': 'Valve Annual Trading Card & Badge Event',
        'category': 'Gaming',
        'mode': 'Online',
        'is_steam_sale': true,
        'start': at(4, 18),
        'venue': 'Online · Steam Store & Community Market',
        'floor_price': 'Up to 90% Off',
        'description': 'The biggest annual Valve Steam event. Millions of collectors trade holiday trading cards, craft badges, and liquidate CS2 skins, creating unprecedented Community Market transaction volume.',
        'image': 'https://images.unsplash.com/photo-1612287232213-9111c1070e17?w=300',
      },
      {
        'id': 'evt_3',
        'title': 'Steam Spring Skin Showcase',
        'subtitle': 'CS2 Knives, Gloves & Rare Dota 2 Arcana',
        'category': 'Gaming',
        'mode': 'Online',
        'is_steam_sale': true,
        'start': at(8, 14),
        'venue': 'Steam Community Market · Auction Room',
        'floor_price': '\$12,400.00',
        'description': 'Curated high-tier Steam Community Market auction featuring Case Hardened Blue Gems, Doppler Gems, and rare contraband skins. Prices benchmarked directly against Steam Community Market history.',
        'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=300',
      },
      {
        'id': 'evt_4',
        'title': 'Steam Summer Market Liquidity Gala',
        'subtitle': 'Mid-Year Valve Steam Market Surge',
        'category': 'Gaming',
        'mode': 'Online',
        'is_steam_sale': true,
        'start': at(16, 17),
        'venue': 'Online · Steam Global Servers',
        'floor_price': 'Community Boost',
        'description': 'The grand mid-year Steam sale. High inventory turnover as gamers liquidate weapon finishes to purchase new releases, leading to prime buying opportunities on the Steam Community Market.',
        'image': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300',
      },
      {
        'id': 'evt_halloween',
        'title': 'Steam Scream Fest (Halloween Sale)',
        'subtitle': 'Valve Official Spooky Event & Themed Market Drops',
        'category': 'Gaming',
        'mode': 'Online',
        'is_steam_sale': true,
        'start': at(8, 17),
        'venue': 'Online · Steam Community Market & Store',
        'floor_price': 'Up to 90% Off',
        'description': 'Official Valve seasonal Halloween event with deep discounts on survival and horror games, driving massive trading surges for spooky CS2 stickers and weapon finishes.',
        'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=300',
      },
    ];
  }

  // --- Konversi waktu nyata (UTC -> zona yang dipilih) ---
  DateTime _inZone(DateTime utc, String zone) =>
      utc.add(Duration(hours: _zoneOffsets[zone] ?? 7));

  String _zoneLabel(String zone) => zone == 'LON' ? 'GMT' : zone;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatClock(DateTime utc, String zone) {
    final t = _inZone(utc, zone);
    return '${_two(t.hour)}:${_two(t.minute)}';
  }

  String _formatTime(DateTime utc, String zone) =>
      '${_formatClock(utc, zone)} ${_zoneLabel(zone)}';

  String _formatDate(DateTime utc, String zone) =>
      DateFormat('EEEE, d MMMM yyyy').format(_inZone(utc, zone));

  String _dayTag(DateTime utc, String zone) {
    final t = _inZone(utc, zone);
    final n = _inZone(DateTime.now().toUtc(), zone);
    final diff = DateTime.utc(
      t.year,
      t.month,
      t.day,
    ).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('d MMM').format(t);
  }

  String _countdown(DateTime startUtc) {
    final d = startUtc.difference(DateTime.now().toUtc());
    if (d.isNegative) return 'now';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes < 10) return '${d.inMinutes}m ${_two(d.inSeconds % 60)}s';
    return '${d.inMinutes}m';
  }

  Future<void> _setEventAlert(Map<String, dynamic> event) async {
    final id = event['id'] as String;
    if (_alertedEvents.contains(id)) {
      _alertTimers.remove(id)?.cancel();
      setState(() => _alertedEvents.remove(id));
      return;
    }

    // Event test: mulai 1 menit dari sekarang supaya notifikasi bisa langsung dites
    if (event['is_test'] == true) {
      event['start'] = DateTime.now().toUtc().add(const Duration(minutes: 1));
    }
    setState(() => _alertedEvents.add(id));

    // Notifikasi dikirim tepat saat event dimulai (selama app masih berjalan)
    final start = event['start'] as DateTime;
    final wait = start.difference(DateTime.now().toUtc());
    _alertTimers[id]?.cancel();
    _alertTimers[id] = Timer(
      wait.isNegative ? Duration.zero : wait,
      () => _fireEventAlert(event),
    );

    if (mounted) {
      VaultToast.show(
        context,
        icon: Icons.notifications_active_rounded,
        iconColor: VaultColors.accent,
        message: 'Alert set · you will be notified at ${_formatTime(start, _selectedZone)}',
      );
    }
  }

  Future<void> _fireEventAlert(Map<String, dynamic> event) async {
    final id = event['id'] as String;
    _alertTimers.remove(id);
    final title = event['title'] as String;

    await NotificationService.instance.showEventReminder(
      title: title,
      body: '${event['subtitle']} · ${event['venue']}. Starting now!',
    );

    if (!mounted) return;
    setState(() => _alertedEvents.remove(id));
    VaultToast.show(
      context,
      icon: Icons.notifications_active_rounded,
      iconColor: VaultColors.accent,
      message: 'Starting now: $title',
    );
  }

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
      VaultToast.show(
        context,
        icon: Icons.notifications_active_rounded,
        iconColor: VaultColors.accent,
        message: 'Alert scheduled for $title',
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
    final otherDrops = filteredDrops
        .where((d) => d['id'] != heroDrop['id'])
        .toList();

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
                  Text(
                    'VAULTED',
                    style: VaultTypography.mono(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: VaultColors.ink,
                    ),
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
                'Live Steam sales & synchronized drops across global markets.',
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
              _buildFeaturedCarousel(),
              const SizedBox(height: 24),

              // 5. CATEGORY FILTER CHIPS FOR DROPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children:
                      [
                        'All',
                        'Gaming',
                        'Collectibles',
                      ].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? VaultColors.ink
                                    : VaultColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? VaultColors.ink
                                      : VaultColors.hairline,
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
                    style: VaultTypography.sans(
                      fontSize: 12.5,
                      color: VaultColors.ink3,
                    ),
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
                  color: isSelected ? VaultColors.background : VaultColors.ink2,
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

  // 1. Featured Drop: carousel 5 event mendatang
  Widget _buildFeaturedCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 214,
          child: ScrollConfiguration(
            // Izinkan geser dengan mouse (Chrome) selain sentuhan
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: _featuredEvents.length,
              onPageChanged: (i) => setState(() => _featuredIndex = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildFeaturedCard(_featuredEvents[i], i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featuredEvents.length, (i) {
            final active = i == _featuredIndex;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? VaultColors.ink
                        : VaultColors.ink3.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> event, int index) {
    final start = event['start'] as DateTime;
    final timeLine =
        '${_formatTime(start, _selectedZone)} · ${_dayTag(start, _selectedZone)}';
    final alertOn = _alertedEvents.contains(event['id']);
    final countdown = _countdown(start);

    return GestureDetector(
      onTap: () => _showEventDetail(event),
      child: Container(
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
                  'FEATURED DROP · ${index + 1}/${_featuredEvents.length}',
                  style: VaultTypography.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: VaultColors.ink2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
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
                        countdown == 'now'
                            ? 'Live now'
                            : 'Starts in $countdown',
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
                _buildVaultArtwork(event['image'] as String, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VaultTypography.sans(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['subtitle'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['floor_price'] as String,
                        style: VaultTypography.mono(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        timeLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VaultTypography.mono(
                          fontSize: 11,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _setEventAlert(event),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: alertOn
                          ? VaultColors.posBg
                          : VaultColors.cardHover,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: alertOn ? VaultColors.pos : VaultColors.hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alertOn
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: 14,
                          color: alertOn ? VaultColors.pos : VaultColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alertOn ? 'Alert On' : 'Set Alert',
                          style: VaultTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alertOn ? VaultColors.pos : VaultColors.ink,
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

  // Detail event: deskripsi, tanggal, jam, tempat, dan tombol notifikasi
  void _showEventDetail(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final start = event['start'] as DateTime;
            final alertOn = _alertedEvents.contains(event['id']);
            final countdown = _countdown(start);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.of(ctx).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VaultColors.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVaultArtwork(event['image'] as String, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildTag(
                                  event['category'] as String,
                                  VaultColors.badgeBg,
                                  VaultColors.accent,
                                ),
                                const SizedBox(width: 6),
                                _buildTag(
                                  (event['mode'] as String).toUpperCase(),
                                  event['mode'] == 'Offline'
                                      ? VaultColors.posBg
                                      : VaultColors.cardHover,
                                  event['mode'] == 'Offline'
                                      ? VaultColors.pos
                                      : VaultColors.ink2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['title'] as String,
                              style: VaultTypography.sans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: VaultColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event['subtitle'] as String,
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
                  Text(
                    event['description'] as String,
                    style: VaultTypography.cardDescription,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'DATE',
                          _formatDate(start, _selectedZone),
                        ),
                        _buildInfoRow(
                          Icons.schedule_rounded,
                          'TIME',
                          _formatTime(start, _selectedZone),
                        ),
                        _buildInfoRow(
                          Icons.place_outlined,
                          'PLACE',
                          event['venue'] as String,
                        ),
                        _buildInfoRow(
                          Icons.hourglass_bottom_rounded,
                          'STARTS IN',
                          countdown == 'now' ? 'Live now' : countdown,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ALL TIMEZONES',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _zones.map((z) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: z == _zones.last ? 0 : 6,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _zoneLabel(z),
                                style: VaultTypography.mono(
                                  fontSize: 9.5,
                                  color: VaultColors.ink3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatClock(start, z),
                                style: VaultTypography.mono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: VaultColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('d MMM').format(_inZone(start, z)),
                                style: VaultTypography.mono(
                                  fontSize: 9,
                                  color: VaultColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _setEventAlert(event);
                        if (ctx.mounted) setSheetState(() {});
                      },
                      icon: Icon(
                        alertOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 18,
                        color: alertOn
                            ? VaultColors.pos
                            : VaultColors.background,
                      ),
                      label: Text(
                        alertOn ? 'Alert On · Tap to Cancel' : 'Notify Me',
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: alertOn
                              ? VaultColors.pos
                              : VaultColors.background,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertOn
                            ? VaultColors.posBg
                            : VaultColors.ink,
                        foregroundColor: alertOn
                            ? VaultColors.pos
                            : VaultColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: alertOn ? VaultColors.pos : VaultColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: VaultTypography.mono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: VaultColors.accent),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: VaultTypography.mono(
                fontSize: 10,
                letterSpacing: 1,
                color: VaultColors.ink2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: VaultTypography.sans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: VaultColors.ink,
              ),
            ),
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
                    Text(
                      ' · ',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        color: VaultColors.ink3,
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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

  // 3. Full-Width Appraiser Banner featuring Valto
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: VaultColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VaultColors.hairline),
              ),
              alignment: Alignment.center,
              child: const ValtoMascot(
                size: 38,
                mood: ValtoMood.detective,
                showHat: true,
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
                        "VALTO'S APPRAISAL",
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
                          horizontal: 5,
                          vertical: 1.5,
                        ),
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
                    'Higher or Lower Challenge',
                    style: VaultTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Can you guess real market values with Valto?',
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
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 11,
                    color: VaultColors.accent,
                  ),
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
            child: Icon(
              Icons.inventory_2_outlined,
              size: size * 0.45,
              color: VaultColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}