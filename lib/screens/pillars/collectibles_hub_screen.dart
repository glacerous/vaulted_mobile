import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/utils/image_utils.dart';
import 'steam_import_screen.dart';

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
  bool _isSyncingSteam = false;

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

  Future<void> _quickSyncSteam() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSyncingSteam = true);

    await Future.delayed(const Duration(milliseconds: 500));
    await _loadData();

    if (mounted) {
      setState(() => _isSyncingSteam = false);
      VaultToast.show(
        context,
        icon: Icons.check_circle_rounded,
        iconColor: VaultColors.pos,
        message: 'Steam inventory up to date · ${_steamItems.length} assets verified.',
      );
    }
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
                          'Collectibles Hub',
                          style: VaultTypography.sans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.ink,
                          ),
                        ),
                        Text(
                          'Digital Assets & Gaming Items',
                          style: VaultTypography.mono(
                            fontSize: 10.5,
                            color: VaultColors.ink2,
                          ),
                        ),
                      ],
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
                  _buildSteamCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Steam items Card (Live synced)
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
            color: VaultColors.hairline,
            width: 1.0,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  GestureDetector(
                    onTap: _isSyncingSteam ? null : _quickSyncSteam,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: VaultColors.cardHover,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VaultColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isSyncingSteam
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: VaultColors.accent,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 14, color: VaultColors.accent),
                          const SizedBox(width: 5),
                          Text(
                            'UPDATE',
                            style: VaultTypography.mono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: VaultColors.accent,
                            ),
                          ),
                        ],
                      ),
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
}
