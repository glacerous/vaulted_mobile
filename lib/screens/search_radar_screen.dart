import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/services/notification_service.dart';

class SearchRadarScreen extends StatefulWidget {
  const SearchRadarScreen({super.key});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen> {
  String _selectedCategory = 'All';
  String _selectedZone = 'WIB'; // 4 Timezones: WIB, WITA, WIT, LON (London GMT)

  final Set<String> _alertedEvents = {};
  Timer? _ticker;
  final Map<String, Timer> _alertTimers = {};

  // DOSEN LIVE CHALLENGE: TIMEZONE OFFSETS (WIB UTC+7, WITA UTC+8, WIT UTC+9, LON GMT+0)
  static const Map<String, int> _zoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'LON': 0,
  };

  late List<Map<String, dynamic>> _allEvents = _buildSeedEvents();

  @override
  void initState() {
    super.initState();
    // Perbarui hitung mundur secara real-time setiap 10 detik
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
    _fetchLiveSteamEvents();
  }

  /// Tarik update resmi Counter-Strike 2 langsung dari Valve Steam Web API
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

          // Pertahankan event test 1-menit di posisi paling awal
          final testEvt = _allEvents.firstWhere(
            (e) => e['is_test'] == true,
            orElse: () => _buildSeedEvents().first,
          );
          liveList.add(testEvt);

          // Masukkan event live dari server Valve
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
            final scheduledStart = nowUtc.add(Duration(hours: (i + 1) * 6, minutes: i * 20));

            liveList.add({
              'id': 'live_steam_${item['gid'] ?? i}',
              'title': title,
              'subtitle': 'Valve Official · Counter-Strike 2',
              'category': 'Gaming',
              'mode': 'Online',
              'start': scheduledStart,
              'venue': 'Steam Community Market (Global)',
              'floor_price': 'Live Steam Feed',
              'description': shortDesc.isNotEmpty
                  ? shortDesc
                  : 'Official Steam Counter-Strike 2 community announcement and market event.',
              'image': imageUrl,
              'is_live': true,
              'url': item['url']?.toString(),
            });
          }

          // Gabungkan jadwal resmi seasonal sales
          for (var evt in _buildSeedEvents()) {
            if (evt['is_test'] != true && liveList.length < 8) {
              liveList.add(evt);
            }
          }

          if (mounted) {
            setState(() {
              _allEvents = liveList;
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
    super.dispose();
  }

  /// Jadwal resmi Steam Sales & Drops. Waktu mulai disimpan dalam format UTC.
  List<Map<String, dynamic>> _buildSeedEvents() {
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
        // EVENT TEST: jam mulai diset 1 menit dari sekarang saat tombol Alert ditekan
        'is_test': true,
        'start': now.add(const Duration(minutes: 2)),
        'venue': 'Online · Steam Community Market',
        'floor_price': 'Market Surge',
        'description': 'Official Steam seasonal sale with a massive surge in Community Market trading volume for CS2 skins, weapon cases, and trading cards. Asset prices fluctuate actively during the opening hours.',
        'image': 'https://images.unsplash.com/photo-1595590424283-b8f17842773f?w=300',
      },
      {
        'id': 'evt_halloween',
        'title': 'Steam Scream Fest (Halloween Sale)',
        'subtitle': 'Valve Official Spooky Event & Themed Market Drops',
        'category': 'Gaming',
        'mode': 'Online',
        'start': at(7, 17),
        'venue': 'Online · Steam Community Market & Store',
        'floor_price': 'Up to 90% Off',
        'description': 'Official Valve seasonal Halloween event with deep discounts on survival and horror games, driving massive trading surges for spooky CS2 stickers and weapon finishes.',
        'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=300',
      },
      {
        'id': 'evt_winter',
        'title': 'Steam Winter Holiday Grand Sale',
        'subtitle': 'Valve Annual Trading Card & Badge Event',
        'category': 'Gaming',
        'mode': 'Online',
        'start': at(58, 18),
        'venue': 'Online · Steam Store & Community Market',
        'floor_price': 'Up to 90% Off',
        'description': 'The biggest annual Valve Steam event. Millions of collectors trade holiday trading cards, craft badges, and liquidate CS2 skins, creating unprecedented Community Market transaction volume.',
        'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300',
      },
      {
        'id': 'evt_major',
        'title': 'CS2 Major Championship Drops',
        'subtitle': 'Valve Souvenir Packages & Gold Stickers',
        'category': 'Collectibles',
        'mode': 'Online',
        'start': at(12, 15),
        'venue': 'Online · Steam Community Market',
        'floor_price': '\$4,250.00',
        'description': 'Official Valve Major Championship tournament items, souvenir packages, and team autograph capsules trade live on the Community Market.',
        'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=300',
      },
      {
        'id': 'evt_spring',
        'title': 'Steam Spring Skin Showcase',
        'subtitle': 'Doppler Gems & Contraband Finishes',
        'category': 'Collectibles',
        'mode': 'Online',
        'start': at(142, 17),
        'venue': 'Steam Community Market · Auction Room',
        'floor_price': '\$12,400.00',
        'description': 'Curated high-tier Steam Community Market showcase featuring Case Hardened Blue Gems, Doppler Gems, and rare contraband skins. Prices benchmarked directly against Steam Community Market history.',
        'image': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300',
      },
    ];
  }

  // --- Konversi Waktu Nyata (UTC -> Zona Terpilih) ---
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
      if (mounted) {
        VaultToast.show(
          context,
          icon: Icons.notifications_off_rounded,
          iconColor: VaultColors.ink2,
          message: 'Alert removed for ${event['title']}',
        );
      }
      return;
    }

    // Pastikan izin notifikasi sudah disetujui di Android
    final granted = await NotificationService.instance.requestPermission();
    if (!granted && mounted) {
      VaultToast.show(
        context,
        icon: Icons.notifications_off_rounded,
        iconColor: VaultColors.neg,
        message: 'Notification permission is disabled in your phone settings',
      );
      return;
    }

    // Event test langsung dikirimkan ke bar notifikasi sistem HP tanpa delay
    if (event['is_test'] == true) {
      setState(() => _alertedEvents.add(id));
      await _fireEventAlert(event);
      return;
    }

    setState(() => _alertedEvents.add(id));

    // Notifikasi terjadwal dikirim tepat saat event dimulai (selama app berjalan)
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

    final sent = await NotificationService.instance.showEventReminder(
      title: title,
      body: '${event['subtitle']} · ${event['venue']}. Starting now!',
    );

    if (!mounted) return;
    setState(() => _alertedEvents.remove(id));
    VaultToast.show(
      context,
      icon: Icons.notifications_active_rounded,
      iconColor: VaultColors.accent,
      message: sent
          ? 'Notification sent to phone: $title'
          : 'Starting now: $title (check phone notification settings)',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Single Source of Truth Filter
    final filteredEvents = _allEvents.where((e) {
      if (_selectedCategory == 'All') return true;
      return e['category'] == _selectedCategory;
    }).toList();

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
              const SizedBox(height: 20),

              // 4. CATEGORY FILTER CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Gaming', 'Collectibles'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
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
                              color: isSel ? VaultColors.background : VaultColors.ink2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // 5. UNIFIED EVENT FEED HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SCHEDULED MARKET DROPS',
                    style: VaultTypography.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: VaultColors.ink2,
                    ),
                  ),
                  Text(
                    '${filteredEvents.length} drops active',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      color: VaultColors.ink3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. SINGLE UNIFIED EVENT LIST (Simple, Informative, No Redundancy)
              if (filteredEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Text(
                    'No scheduled drops in this category.',
                    style: VaultTypography.sans(
                      fontSize: 12.5,
                      color: VaultColors.ink3,
                    ),
                  ),
                )
              else
                ...filteredEvents.map((evt) => _buildUnifiedEventCard(evt)),
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

  /// Satu kartu event lengkap: informatif, bersih, dan mendukung test notifikasi
  Widget _buildUnifiedEventCard(Map<String, dynamic> event) {
    final start = event['start'] as DateTime;
    final timeLine =
        '${_formatTime(start, _selectedZone)} · ${_dayTag(start, _selectedZone)}';
    final alertOn = _alertedEvents.contains(event['id']);
    final countdown = _countdown(start);
    final floorPrice = event['floor_price'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showEventDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Pill + Countdown Capsule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Text(
                    event['category'] as String? ?? 'Gaming',
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: countdown == 'now' ? VaultColors.posBg : VaultColors.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: countdown == 'now' ? VaultColors.pos : VaultColors.accent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        countdown == 'now' ? 'Live now' : 'Starts in $countdown',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: countdown == 'now' ? VaultColors.pos : VaultColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Artwork + Title + Subtitle + Timezone
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVaultArtwork(event['image'] as String, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String,
                        style: VaultTypography.sans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: VaultColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['subtitle'] as String,
                        style: VaultTypography.sans(
                          fontSize: 11.5,
                          color: VaultColors.ink2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: VaultColors.ink3),
                          const SizedBox(width: 4),
                          Text(
                            timeLine,
                            style: VaultTypography.mono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: VaultColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Divider & Action Row
            Container(height: 1, color: VaultColors.hairline),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  floorPrice,
                  style: VaultTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.ink,
                  ),
                ),
                GestureDetector(
                  onTap: () => _setEventAlert(event),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: alertOn ? VaultColors.ink : VaultColors.cardHover,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: alertOn ? VaultColors.ink : VaultColors.hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alertOn
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: 13,
                          color: alertOn ? VaultColors.background : VaultColors.ink,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          alertOn ? 'Alert Set' : 'Set Alert',
                          style: VaultTypography.mono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: alertOn ? VaultColors.background : VaultColors.ink,
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

  // --- DETAIL MODAL BOTTOM SHEET ---
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
                                  (event['mode'] as String? ?? 'ONLINE').toUpperCase(),
                                  VaultColors.cardHover,
                                  VaultColors.ink2,
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
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'STARTS IN',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.ink3,
                              ),
                            ),
                            Text(
                              countdown == 'now'
                                  ? 'LIVE NOW'
                                  : countdown.toUpperCase(),
                              style: VaultTypography.mono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: countdown == 'now'
                                    ? VaultColors.pos
                                    : VaultColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: VaultColors.hairline),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SCHEDULED TIME',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.ink3,
                              ),
                            ),
                            Text(
                              '${_formatTime(start, _selectedZone)} (${_dayTag(start, _selectedZone)})',
                              style: VaultTypography.mono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: VaultColors.hairline),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VENUE / PLATFORM',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.ink3,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                event['venue'] as String,
                                textAlign: TextAlign.right,
                                style: VaultTypography.sans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: VaultColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ABOUT THIS EVENT',
                    style: VaultTypography.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event['description'] as String,
                    style: VaultTypography.sans(
                      fontSize: 13,
                      height: 1.45,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _setEventAlert(event);
                        setSheetState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertOn
                            ? VaultColors.cardHover
                            : VaultColors.primaryButton,
                        foregroundColor: alertOn
                            ? VaultColors.ink
                            : VaultColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: alertOn
                                ? VaultColors.hairline
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      icon: Icon(
                        alertOn
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined,
                        size: 16,
                      ),
                      label: Text(
                        alertOn
                            ? 'Remove Alert'
                            : (event['is_test'] == true
                                ? 'Send Test Alert to Phone'
                                : 'Set Alert for this Drop'),
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: alertOn ? VaultColors.ink : VaultColors.background,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: VaultTypography.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

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
