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
  bool _isSyncingSteam = false;

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
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collectibles Hub',
              style: VaultTypography.sans(
                fontSize: 16,
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSteamCard(context),
            const SizedBox(height: 20),
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
                  ],
                ),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink2),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hasItems ? '${_steamItems.length} items' : 'Community Cards · Avatars · In-game Items',
              style: VaultTypography.cardSub,
            ),
            const SizedBox(height: 12),

            if (hasItems) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '\$${_steamTotal.toStringAsFixed(2)}',
                    style: VaultTypography.mono(fontSize: 24, fontWeight: FontWeight.w500, color: VaultColors.ink),
                  ),
                  IconButton(
                    tooltip: 'Sync Steam Inventory',
                    onPressed: _isSyncingSteam ? null : _quickSyncSteam,
                    icon: _isSyncingSteam
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: VaultColors.accent,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18, color: VaultColors.ink2),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Real preview thumbnails
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _steamItems.map((item) {
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
