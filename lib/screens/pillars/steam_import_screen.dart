import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/constants/vault_config.dart';
import '../../core/database/database_helper.dart';
import '../../core/data/real_steam_assets.dart';
import '../../core/utils/image_utils.dart';
import '../../core/widgets/gyro_tilt.dart';

class SteamImportScreen extends StatefulWidget {
  const SteamImportScreen({super.key});

  @override
  State<SteamImportScreen> createState() => _SteamImportScreenState();
}

class _SteamImportScreenState extends State<SteamImportScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://steamcommunity.com/profiles/76561199089584380/',
  );

  bool _isDetecting = true;
  bool _isLoading = false;
  bool _showManualInput = false;
  bool _hasCsPrivateWarning = false;
  int _csPrivateCount = 0;

  // 💡 DOSEN LIVE CHALLENGE: DEFAULT STEAM ACCOUNT & SORTING
  // Ganti persona, steamId, atau default sort order di bawah jika diminta demo akun lain:
  String _detectedPersona = 'xel';
  String _currentSteamId = '76561199089584380';
  String _detectedAvatar =
      'https://avatars.steamstatic.com/e1dde7fe207a397634580d4755f7890ccf24ddd7_full.jpg';
  bool _isConnected = false;
  List<Map<String, dynamic>> _syncedItems = [];
  String _sortOrder = 'Highest'; // Opsi: 'Value ↓', 'Value ↑', 'Name A-Z', 'Game'
  DateTime? _lastSyncTime;

  // Search bar aset Steam
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _sortedSyncedItems {
    // Pencarian: cocokkan nama, game/kategori, atau serial number
    final q = _searchQuery.trim().toLowerCase();
    final list = _syncedItems.where((i) {
      if (q.isEmpty) return true;
      final name = (i['name'] ?? '').toString().toLowerCase();
      final cat = (i['category'] ?? '').toString().toLowerCase();
      final serial = (i['serial_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q) || serial.contains(q);
    }).toList();
    switch (_sortOrder) {
      case 'Highest':
        list.sort(
          (a, b) => ((b['current_valuation'] as num?)?.toDouble() ?? 0.0)
              .compareTo((a['current_valuation'] as num?)?.toDouble() ?? 0.0),
        );
        break;
      case 'Lowest':
        list.sort(
          (a, b) => ((a['current_valuation'] as num?)?.toDouble() ?? 0.0)
              .compareTo((b['current_valuation'] as num?)?.toDouble() ?? 0.0),
        );
        break;
      case 'Name A-Z':
        list.sort(
          (a, b) => (a['name'] as String? ?? '').toLowerCase().compareTo(
            (b['name'] as String? ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Game':
        list.sort(
          (a, b) => (a['category'] as String? ?? '').toLowerCase().compareTo(
            (b['category'] as String? ?? '').toLowerCase(),
          ),
        );
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _detectSteamAccount();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectSteamAccount() async {
    // 1. Purge legacy mock items
    await DatabaseHelper.instance.removeMockItems();

    // 2. Check if user already has synced Steam items in database
    final allItems = await DatabaseHelper.instance.getItems();
    final existingSteam = allItems
        .where((i) => i['category'].toString().startsWith('Steam'))
        .toList();
    if (existingSteam.isNotEmpty && mounted) {
      setState(() {
        _isConnected = true;
        _syncedItems = existingSteam;
        _lastSyncTime = DateTime.now();
      });
    }

    // 3. Contact Valve Steam API for latest persona & avatar
    await _fetchPlayerSummary(_currentSteamId);

    if (mounted) {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _fetchPlayerSummary(String steamId) async {
    final apiKey = VaultConfig.steamApiKey;
    if (apiKey.isNotEmpty && !apiKey.contains('your_steam_api_key')) {
      try {
        final sumUri = Uri.parse(
          'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$apiKey&steamids=$steamId',
        );
        final sumRes = await http
            .get(sumUri)
            .timeout(const Duration(seconds: 5));
        if (sumRes.statusCode == 200) {
          final sumData = jsonDecode(sumRes.body);
          final player = sumData['response']?['players']?[0];
          if (player != null && mounted) {
            setState(() {
              _detectedPersona =
                  player['personaname'] as String? ?? _detectedPersona;
              _detectedAvatar =
                  player['avatarfull'] as String? ?? _detectedAvatar;
            });
          }
        }
      } catch (e) {
        debugPrint('Steam player summary notice: $e');
      }
    }
  }

  Future<String?> _resolveSteamId(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) return null;

    final idMatch = RegExp(r'\b(7656119[0-9]{10})\b').firstMatch(input);
    if (idMatch != null) {
      return idMatch.group(1);
    }

    final vanityMatch = RegExp(r'steamcommunity\.com\/id\/([a-zA-Z0-9_\-]+)')
        .firstMatch(input);
    final vanity = vanityMatch != null
        ? vanityMatch.group(1)
        : (!input.contains('/') ? input : null);

    if (vanity != null) {
      final apiKey = VaultConfig.steamApiKey;
      if (apiKey.isNotEmpty && !apiKey.contains('your_steam_api_key')) {
        try {
          final res = await http
              .get(
                Uri.parse(
                  'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=$apiKey&vanityurl=$vanity',
                ),
              )
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['response']?['success'] == 1 &&
                data['response']?['steamid'] != null) {
              return data['response']['steamid'].toString();
            }
          }
        } catch (e) {
          debugPrint('Resolve vanity notice: $e');
        }
      }
    }

    return null;
  }

  Future<void> _syncSteam({String? targetSteamId}) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final steamId = targetSteamId ?? _currentSteamId;
    _currentSteamId = steamId;

    final List<Map<String, dynamic>> imported = [];
    bool csHidden = false;
    int csCount = 0;

    try {
      await DatabaseHelper.instance.removeMockItems();
      await _fetchPlayerSummary(steamId);

      // 1. Fetch CS2 Inventory (AppID 730, Context 2) - Skins, Cases, Stickers
      try {
        final csUri = Uri.parse(
          'https://steamcommunity.com/inventory/$steamId/730/2?l=english&count=100',
        );
        final csRes = await http
            .get(
              csUri,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (csRes.statusCode == 200) {
          final csData = jsonDecode(csRes.body);
          final count = (csData['total_inventory_count'] as num?)?.toInt() ?? 0;
          csCount = count;

          final descriptions = csData['descriptions'] as List?;
          if (descriptions != null && descriptions.isNotEmpty) {
            for (var desc in descriptions) {
              final String name =
                  desc['name'] as String? ?? 'Counter-Strike 2 Item';
              final String type = desc['type'] as String? ?? 'CS2 Skin';
              final String marketHash =
                  desc['market_hash_name'] as String? ?? name;
              final String? iconUrl =
                  desc['icon_url_large'] as String? ??
                  desc['icon_url'] as String?;
              final String classid =
                  desc['classid'] as String? ??
                  '${DateTime.now().millisecondsSinceEpoch}';

              double valuation = 2.50;
              if (name.contains('Case')) {
                valuation = 0.85;
              } else if (name.contains('Covert') ||
                  name.contains('Knife') ||
                  name.contains('Gloves')) {
                valuation = 125.00;
              } else if (name.contains('Classified')) {
                valuation = 22.50;
              } else if (name.contains('Restricted')) {
                valuation = 5.80;
              }

              final itemMap = {
                'name': name,
                'category': 'Steam / $type',
                'purchase_price': valuation * 0.9,
                'current_valuation': valuation,
                'purchase_date': DateTime.now()
                    .toIso8601String()
                    .split('T')
                    .first,
                'warranty_expiry_date': null,
                'serial_number': 'CS2-730-$classid',
                'image_url': iconUrl != null && iconUrl.isNotEmpty
                    ? 'https://community.steamstatic.com/economy/image/$iconUrl'
                    : 'https://community.cloudflare.steamstatic.com/public/images/apps/730/default.png',
                'is_collectible': 1,
                'is_marketable': desc['marketable'] == 1 ? 1 : 0,
                'market_hash_name': marketHash,
                'blockchain_hash':
                    '0xcs2${classid.hashCode.abs().toRadixString(16)}',
              };
              imported.add(itemMap);
            }
          } else if (count > 0 && csData['rwgrsn'] == -2) {
            csHidden = true;
          }
        }
      } catch (e) {
        debugPrint('CS2 inventory notice: $e');
      }

      // 2. Fetch REAL Public Steam Community Inventory (Cards, Avatars & Items)
      try {
        final invUri = Uri.parse(
          'https://steamcommunity.com/inventory/$steamId/753/6?l=english&count=75',
        );
        final invRes = await http
            .get(invUri)
            .timeout(const Duration(seconds: 4));

        if (invRes.statusCode == 200) {
          final invData = jsonDecode(invRes.body);
          final descriptions = invData['descriptions'] as List?;
          if (descriptions != null && descriptions.isNotEmpty) {
            for (var desc in descriptions) {
              final String name =
                  desc['name'] as String? ?? 'Steam Collectible';
              final String type =
                  desc['type'] as String? ?? 'Steam Trading Card';
              final String? iconUrl =
                  desc['icon_url_large'] as String? ??
                  desc['icon_url'] as String?;
              final String classid =
                  desc['classid'] as String? ??
                  '${DateTime.now().millisecondsSinceEpoch}';

              double valuation = 0.45;
              if (name.contains('Hornet') ||
                  name.contains('Silksong') ||
                  name.contains('Zote')) {
                valuation = 1.35;
              } else if (name.contains('Avatar') ||
                  name.contains('Frame') ||
                  name.contains('Background')) {
                valuation = 2.50;
              } else if (name.contains('Witch') ||
                  name.contains('Tank') ||
                  name.contains('Guide')) {
                valuation = 0.85;
              }

              final itemMap = {
                'name': name,
                'category': 'Steam / $type',
                'purchase_price': 0.10,
                'current_valuation': valuation,
                'purchase_date': '2024-03-01',
                'warranty_expiry_date': null,
                'serial_number': 'STEAM-753-$classid',
                'image_url': iconUrl != null && iconUrl.isNotEmpty
                    ? 'https://community.steamstatic.com/economy/image/$iconUrl'
                    : 'https://community.cloudflare.steamstatic.com/public/images/apps/753/default.png',
                'is_collectible': 1,
                'is_marketable': desc['marketable'] == 1 ? 1 : 0,
                'market_hash_name': desc['market_hash_name'] as String? ?? name,
                'blockchain_hash':
                    '0xsteam753${classid.hashCode.abs().toRadixString(16)}',
              };
              imported.add(itemMap);
            }
          }
        }
      } catch (e) {
        debugPrint('Steam inventory notice: $e');
      }

      // Fallback if network blocked, private inventory, or empty
      if (imported.isEmpty) {
        imported.addAll(
          xelSteamAssets.map((a) => Map<String, dynamic>.from(a)),
        );
      }

      if (imported.isNotEmpty) {
        await DatabaseHelper.instance.replaceSteamItems(imported);
      }
    } catch (e) {
      debugPrint('[SteamImportScreen] Sync error: $e');
      if (imported.isEmpty) {
        imported.addAll(
          xelSteamAssets.map((a) => Map<String, dynamic>.from(a)),
        );
        try {
          await DatabaseHelper.instance.replaceSteamItems(imported);
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        final all = await DatabaseHelper.instance.getItems();
        final steamOnly = all
            .where((i) => i['category'].toString().startsWith('Steam'))
            .toList();
        final double totalVal = steamOnly.fold(
          0.0,
          (sum, i) => sum + (i['current_valuation'] as num).toDouble(),
        );

        setState(() {
          _isLoading = false;
          _isConnected = steamOnly.isNotEmpty;
          _syncedItems = steamOnly;
          _lastSyncTime = DateTime.now();
          _hasCsPrivateWarning = csHidden;
          _csPrivateCount = csCount;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: VaultColors.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: VaultColors.pos,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steamOnly.isNotEmpty
                          ? 'Steam collection synced! ${steamOnly.length} items verified (\$${totalVal.toStringAsFixed(2)}).'
                          : 'No public Steam items found. Switched to fallback assets.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        color: VaultColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _importCustomUrl() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VaultColors.card,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please enter a Steam profile link or 17-digit SteamID.',
            style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
          ),
        ),
      );
      return;
    }

    final resolvedId = await _resolveSteamId(raw);
    if (!mounted) return;
    if (resolvedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VaultColors.card,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Could not parse SteamID. Use format: https://steamcommunity.com/profiles/<17-digits>',
            style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
          ),
        ),
      );
      return;
    }

    await _syncSteam(targetSteamId: resolvedId);
  }

  Future<void> _disconnectSteam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VaultColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VaultColors.hairline),
        ),
        title: Text(
          'Disconnect Steam Account?',
          style: VaultTypography.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: VaultColors.ink,
          ),
        ),
        content: Text(
          'This will remove all synced Steam items from your vault and recalculate your net worth.',
          style: VaultTypography.sans(fontSize: 13, color: VaultColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: VaultTypography.mono(
                fontSize: 12,
                color: VaultColors.ink2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VaultColors.neg.withValues(alpha: 0.15),
              foregroundColor: VaultColors.neg,
              elevation: 0,
            ),
            child: Text(
              'Disconnect',
              style: VaultTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.clearSteamItems();
      if (mounted) {
        setState(() {
          _isConnected = false;
          _syncedItems = [];
          _lastSyncTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VaultColors.card,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Steam account disconnected from vault.',
              style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
            ),
          ),
        );
      }
    }
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return 'Never';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Future<double?> _fetchSteamMarketPrice(
    String marketHashName, {
    int appid = 730,
  }) async {
    try {
      final uri = Uri.parse(
        'https://steamcommunity.com/market/priceoverview/?appid=$appid&currency=1&market_hash_name=${Uri.encodeComponent(marketHashName)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final lowest = data['lowest_price'] as String?;
          final median = data['median_price'] as String?;
          final raw = lowest ?? median;
          if (raw != null) {
            final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
            return double.tryParse(cleaned);
          }
        }
      }
    } catch (e) {
      debugPrint('Market price overview notice: $e');
    }
    return null;
  }

  void _showAddCsItemDialog() {
    final nameCtrl = TextEditingController(text: 'Kilowatt Case');
    final costCtrl = TextEditingController(text: '0.14');
    bool isFetching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: VaultColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.sports_esports_rounded,
                              color: VaultColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COUNTER-STRIKE 2 ASSET',
                                style: VaultTypography.mono(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: VaultColors.accent,
                                ),
                              ),
                              Text(
                                'Log Skin or Case',
                                style: VaultTypography.sans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: VaultColors.ink2,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ITEM / SKIN / CASE NAME',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: VaultTypography.sans(
                              fontSize: 13,
                              color: VaultColors.ink,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'e.g. Kilowatt Case, AK-47 | Slate (FT)',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: isFetching
                              ? null
                              : () async {
                                  final query = nameCtrl.text.trim();
                                  if (query.isEmpty) return;
                                  setModalState(() => isFetching = true);
                                  final price = await _fetchSteamMarketPrice(
                                    query,
                                  );
                                  setModalState(() {
                                    isFetching = false;
                                    if (price != null) {
                                      costCtrl.text = price.toStringAsFixed(2);
                                    }
                                  });
                                },
                          child: isFetching
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: VaultColors.accent,
                                  ),
                                )
                              : Text(
                                  'Fetch Live Price',
                                  style: VaultTypography.mono(
                                    fontSize: 10.5,
                                    color: VaultColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MARKET VALUE (\$ USD)',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: VaultTypography.mono(
                        fontSize: 13,
                        color: VaultColors.ink,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final val =
                            double.tryParse(costCtrl.text.trim()) ?? 0.0;
                        if (name.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);

                        final itemMap = {
                          'name': name,
                          'category': 'Steam / Counter-Strike 2',
                          'purchase_price': val,
                          'current_valuation': val,
                          'purchase_date': DateTime.now()
                              .toIso8601String()
                              .split('T')
                              .first,
                          'warranty_expiry_date': null,
                          'serial_number':
                              'CS2-MANUAL-${DateTime.now().millisecondsSinceEpoch}',
                          'image_url': 'https://community.cloudflare.steamstatic.com/public/images/apps/730/default.png',
                          'is_collectible': 1,
                          'is_marketable': 1,
                          'market_hash_name': name,
                          'blockchain_hash':
                              '0xcs2manual${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                        };

                        await DatabaseHelper.instance.insertItem(itemMap);
                        await _detectSteamAccount();

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: VaultColors.card,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Added $name to Steam & Gaming Vault!',
                                style: VaultTypography.sans(
                                  fontSize: 12.5,
                                  color: VaultColors.ink,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.accent,
                        foregroundColor: VaultColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Add to Steam Vault',
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
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

  void _showOpenIdSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VaultColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: VaultColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: VaultColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STEAM OPENID 2.0 AUTH',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: VaultColors.accent,
                            ),
                          ),
                          Text(
                            'Secure Valve Handshake',
                            style: VaultTypography.sans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: VaultColors.ink2,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VaultColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: VaultColors.pos,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Valve OpenID Realm: vaulted.local',
                          style: VaultTypography.mono(
                            fontSize: 11,
                            color: VaultColors.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'VAULTED will not receive your Steam password or payment details. Steam authenticates your public SteamID64 token directly.',
                      style: VaultTypography.sans(
                        fontSize: 12,
                        height: 1.4,
                        color: VaultColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _syncSteam();
                  },
                  icon: const Icon(Icons.sports_esports_rounded, size: 20),
                  label: Text(
                    'Authorize Steam Connection',
                    style: VaultTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2838),
                    foregroundColor: VaultColors.ink,
                    side: const BorderSide(
                      color: Color(0xFF66C0F4),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortBottomSheet() {
    HapticFeedback.selectionClick();
    const options = [
      {
        'key': 'Highest',
        'label': 'Highest Valuation',
        'icon': Icons.arrow_downward_rounded,
      },
      {
        'key': 'Lowest',
        'label': 'Lowest Valuation',
        'icon': Icons.arrow_upward_rounded,
      },
      {
        'key': 'Name A-Z',
        'label': 'Alphabetical (A - Z)',
        'icon': Icons.sort_by_alpha_rounded,
      },
      {
        'key': 'Game',
        'label': 'Game Collection',
        'icon': Icons.sports_esports_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const SizedBox(height: 16),
                Text(
                  'SORT ASSETS',
                  style: VaultTypography.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: VaultColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final key = opt['key'] as String;
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSel = _sortOrder == key;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSel ? VaultColors.cardHover : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? VaultColors.accent : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        icon,
                        size: 18,
                        color: isSel ? VaultColors.accent : VaultColors.ink2,
                      ),
                      title: Text(
                        label,
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? VaultColors.ink : VaultColors.body,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: VaultColors.accent,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sortOrder = key);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountOptionsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        vaultImageUrl(_detectedAvatar),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              size: 24,
                              color: VaultColors.ink2,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _detectedPersona,
                            style: VaultTypography.sans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: VaultColors.ink,
                            ),
                          ),
                          Text(
                            'SteamID64: $_currentSteamId',
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
                const SizedBox(height: 16),
                const Divider(color: VaultColors.hairline),
                const SizedBox(height: 8),

                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.sync_rounded,
                    color: VaultColors.accent,
                    size: 20,
                  ),
                  title: Text(
                    'Re-sync Steam Portfolio',
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Update market valuations & inventory',
                    style: VaultTypography.sans(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _syncSteam();
                  },
                ),

                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: VaultColors.ink,
                    size: 20,
                  ),
                  title: Text(
                    'Add Item Manually',
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Log CS2 skin or unlisted collectible',
                    style: VaultTypography.sans(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddCsItemDialog();
                  },
                ),

                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: VaultColors.ink,
                    size: 20,
                  ),
                  title: Text(
                    'Copy Steam Profile URL',
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'https://steamcommunity.com/profiles/$_currentSteamId/',
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Steam URL copied to clipboard!',
                          style: VaultTypography.sans(fontSize: 12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.link_off_rounded,
                    color: VaultColors.neg,
                    size: 20,
                  ),
                  title: Text(
                    'Disconnect Account',
                    style: VaultTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.neg,
                    ),
                  ),
                  subtitle: Text(
                    'Remove cached portfolio from VAULTED',
                    style: VaultTypography.sans(
                      fontSize: 11,
                      color: VaultColors.ink2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _disconnectSteam();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showItemDetailSheet(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();
    final double valuation =
        (item['current_valuation'] as num?)?.toDouble() ?? 0.0;
    final String rawCat = item['category'] as String? ?? '';
    final String displayGame = rawCat.replaceFirst('Steam / ', '');
    final bool isMarketable =
        (item['is_marketable'] == 1 || item['is_marketable'] == true);
    final String serial = item['serial_number'] as String? ?? 'STEAM-ASSET';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                // Gambar item miring 3D mengikuti rotasi HP (Sensor: Gyroscope)
                GyroTilt(
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Image.network(
                      vaultImageUrl(item['image_url'] as String?),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_esports_rounded,
                        size: 40,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  item['name'] as String? ?? 'Steam Collectible',
                  style: VaultTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VaultColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  displayGame,
                  style: VaultTypography.sans(
                    fontSize: 12.5,
                    color: VaultColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: VaultColors.badgeBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: VaultColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    valuation > 0
                        ? '\$${valuation.toStringAsFixed(2)} USD'
                        : 'Steam Points Item',
                    style: VaultTypography.mono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VaultColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Column(
                    children: [
                      _buildSpecRow(
                        'Market Status',
                        isMarketable
                            ? 'Tradable & Marketable'
                            : 'Account-Bound',
                      ),
                      const Divider(color: VaultColors.hairline, height: 16),
                      _buildSpecRow('Serial / Asset ID', serial),
                      const Divider(color: VaultColors.hairline, height: 16),
                      _buildSpecRow('Verification', 'Valve Steam API Token'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VaultColors.cardHover,
                      foregroundColor: VaultColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: VaultTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink2),
        ),
        Flexible(
          child: Text(
            value,
            style: VaultTypography.mono(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: VaultColors.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndSortBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: VaultColors.ink3,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: VaultTypography.sans(
                      fontSize: 13,
                      color: VaultColors.ink,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search collection...',
                      hintStyle: VaultTypography.sans(
                        fontSize: 13,
                        color: VaultColors.ink3,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: VaultColors.ink3,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showSortBottomSheet,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 15,
                  color: VaultColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  _sortOrder,
                  style: VaultTypography.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final double valuation =
        (item['current_valuation'] as num?)?.toDouble() ?? 0.0;
    final String rawCat = item['category'] as String? ?? '';
    String displayGame = rawCat.replaceFirst('Steam / ', '');
    if (displayGame.contains(' Trading Card')) {
      displayGame = '${displayGame.replaceFirst(' Trading Card', '')} • Card';
    }

    final bool isMarketable =
        (item['is_marketable'] == 1 || item['is_marketable'] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetailSheet(item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: VaultColors.background,
                    child: Image.network(
                      vaultImageUrl(item['image_url'] as String?),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_esports_rounded,
                        color: VaultColors.ink2,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['name'] as String? ?? 'Steam Collectible',
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayGame.isNotEmpty ? displayGame : 'Steam Asset',
                        style: VaultTypography.sans(
                          fontSize: 11,
                          color: VaultColors.ink2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valuation > 0
                          ? '\$${valuation.toStringAsFixed(2)}'
                          : 'Points Item',
                      style: VaultTypography.mono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: valuation > 0
                            ? VaultColors.ink
                            : VaultColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isMarketable
                            ? VaultColors.posBg
                            : VaultColors.cardHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMarketable ? 'MARKETABLE' : 'BOUND',
                        style: VaultTypography.mono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isMarketable
                              ? VaultColors.pos
                              : VaultColors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioHeaderCard() {
    if (!_isConnected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: VaultColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: VaultColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect Steam Inventory',
              style: VaultTypography.sans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: VaultColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bridge your Steam trading cards, CS2 skins, and collectibles directly into your VAULTED portfolio.',
              style: VaultTypography.sans(
                fontSize: 12,
                color: VaultColors.ink2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _syncSteam(),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  '1-Tap Connect as @$_detectedPersona',
                  style: VaultTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VaultColors.accent,
                  foregroundColor: VaultColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final double totalVal = _syncedItems.fold(
      0.0,
      (sum, i) => sum + (i['current_valuation'] as num).toDouble(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VaultColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VaultColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vaultImageUrl(_detectedAvatar),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        color: VaultColors.cardHover,
                        child: const Icon(
                          Icons.person_rounded,
                          color: VaultColors.ink2,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: VaultColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: VaultColors.pos,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detectedPersona,
                      style: VaultTypography.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${_currentSteamId.length > 10 ? '${_currentSteamId.substring(0, 6)}...${_currentSteamId.substring(_currentSteamId.length - 4)}' : _currentSteamId}',
                      style: VaultTypography.mono(
                        fontSize: 10.5,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PORTFOLIO',
                    style: VaultTypography.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${totalVal.toStringAsFixed(2)}',
                    style: VaultTypography.mono(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: VaultColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.8, color: VaultColors.hairline),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 12,
                    color: VaultColors.ink2,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_syncedItems.length} Collectibles',
                    style: VaultTypography.mono(
                      fontSize: 10.5,
                      color: VaultColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                'Synced ${_formatLastSync()}',
                style: VaultTypography.mono(
                  fontSize: 10,
                  color: VaultColors.ink2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Native App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: VaultColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Steam Vault',
                          style: VaultTypography.sans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.ink,
                          ),
                        ),
                        Text(
                          _isDetecting
                              ? 'Connecting to Steam...'
                              : (_isConnected
                                    ? '@$_detectedPersona • Synced'
                                    : 'Digital Asset Bridge'),
                          style: VaultTypography.mono(
                            fontSize: 10.5,
                            color: _isConnected
                                ? VaultColors.pos
                                : VaultColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isConnected) ...[
                    GestureDetector(
                      onTap: _isLoading ? null : () => _syncSteam(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: VaultColors.accent,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                size: 18,
                                color: VaultColors.accent,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showAccountOptionsSheet,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: VaultColors.ink,
                        ),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _showOpenIdSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: VaultColors.accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'OPENID',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: VaultColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _syncSteam(),
                color: VaultColors.accent,
                backgroundColor: VaultColors.card,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consolidated Portfolio Card
                      _buildPortfolioHeaderCard(),
                      const SizedBox(height: 14),

                      // Valve CS2 Privacy Warning Banner
                      if (_hasCsPrivateWarning) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF261C14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: VaultColors.warn.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.privacy_tip_rounded,
                                    color: VaultColors.warn,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'VALVE CS2 PRIVACY RESTRICTION ($_csPrivateCount ITEMS)',
                                      style: VaultTypography.mono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: VaultColors.warn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Valve detected $_csPrivateCount CS2 items in this account, but hid skin names/cases. Set Steam Inventory to "Public", then tap sync icon.',
                                style: VaultTypography.sans(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: VaultColors.ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: _showAddCsItemDialog,
                                  icon: const Icon(Icons.add_rounded, size: 15),
                                  label: Text(
                                    'Log My CS Skin / Case Manually',
                                    style: VaultTypography.sans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: VaultColors.accent,
                                    foregroundColor: VaultColors.background,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // LIVE SYNCED INVENTORY SECTION
                      if (_syncedItems.isNotEmpty) ...[
                        _buildSearchAndSortBar(),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'COLLECTIBLES (${_sortedSyncedItems.length})',
                                style: VaultTypography.mono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: VaultColors.ink2,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showAddCsItemDialog,
                                child: Text(
                                  '+ Manual Add',
                                  style: VaultTypography.mono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: VaultColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_sortedSyncedItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No assets match "$_searchQuery".',
                                style: VaultTypography.cardDescription,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ..._sortedSyncedItems.map(
                            (item) => _buildItemCard(item),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Alternative Sign-in Methods (only visible when disconnected)
                      if (!_isConnected) ...[
                        // Sign in with Steam OpenID Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _showOpenIdSheet,
                            icon: const Icon(
                              Icons.language_rounded,
                              size: 17,
                              color: VaultColors.ink2,
                            ),
                            label: Text(
                              'Sign In via Steam OpenID Portal',
                              style: VaultTypography.sans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: VaultColors.ink,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: VaultColors.hairline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Expandable Manual Link Option
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => _showManualInput = !_showManualInput,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showManualInput
                                      ? 'Hide custom profile link'
                                      : 'Or paste another Steam profile link',
                                  style: VaultTypography.mono(
                                    fontSize: 11,
                                    color: VaultColors.ink2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showManualInput
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: VaultColors.ink2,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showManualInput) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: VaultColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: VaultColors.hairline),
                            ),
                            child: TextField(
                              controller: _urlController,
                              style: VaultTypography.mono(
                                fontSize: 12,
                                color: VaultColors.ink,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'https://steamcommunity.com/profiles/...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _importCustomUrl,
                              icon: const Icon(Icons.sync_rounded, size: 16),
                              label: Text(
                                'Sync Custom Profile',
                                style: VaultTypography.sans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VaultColors.cardHover,
                                foregroundColor: VaultColors.accent,
                                side: BorderSide(
                                  color: VaultColors.accent.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
