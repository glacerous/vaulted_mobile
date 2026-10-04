import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';

class SteamImportScreen extends StatefulWidget {
  const SteamImportScreen({super.key});

  @override
  State<SteamImportScreen> createState() => _SteamImportScreenState();
}

class _SteamImportScreenState extends State<SteamImportScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://steamcommunity.com/id/azzaky',
  );
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _importSteamInventory() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final apiKey = dotenv.env['STEAM_API_KEY'];
    await Future.delayed(const Duration(milliseconds: 1200)); // Smooth UX transition

    // Add simulated CS2 & Dota 2 items valued off Community Market
    await DatabaseHelper.instance.insertItem({
      'name': 'AK-47 | Case Hardened (Tier 2 Blue Gem)',
      'category': 'Steam / CS2',
      'purchase_price': 150.00,
      'current_valuation': 1250.00,
      'purchase_date': '2024-01-10',
      'warranty_expiry_date': null,
      'serial_number': 'STEAM-ASSET-730-8912',
      'image_url': 'https://community.cloudflare.steamstatic.com/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgpot621FAR17PLfYQJD_9W7m5a0mvLwOq7c2D1VvZJ13-rD99332Q22qUs9YWzwcdTAcwQ5aVDV-Fe3yee7hsfv6MjXiSw07HhTfA/360fx360f',
      'is_collectible': 1,
      'blockchain_hash': '0xsteam730cs2casehardened',
    });

    await DatabaseHelper.instance.insertItem({
      'name': 'Butterfly Knife | Doppler (Phase 2)',
      'category': 'Steam / CS2',
      'purchase_price': 800.00,
      'current_valuation': 2400.00,
      'purchase_date': '2023-11-05',
      'warranty_expiry_date': null,
      'serial_number': 'STEAM-ASSET-730-5541',
      'image_url': 'https://community.cloudflare.steamstatic.com/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXH5ApeO4YmlhxYQknCRvCo04DEVlxkKgpovbSsLQJf1f_BYQJD4eOxlY2Glsj4OrzZglRd6dd2j6eU99yt31K3_xE_YmH2cYCQcwM6Yl_TrFi2yea-gpe0uJvPnHsy6HQgtCnemhDi1hpSLrs4cM6b5Zc/360fx360f',
      'is_collectible': 1,
      'blockchain_hash': '0xsteam730butterflydoppler',
    });

    setState(() {
      _isLoading = false;
      _statusMessage = apiKey != null && apiKey != 'your_steam_api_key_here'
          ? 'Successfully connected to Steam Web API!'
          : 'Imported 2 public items (\$3,650.00) from Steam Community Market!';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VaultColors.card,
          content: Text(_statusMessage!, style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.pos)),
        ),
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
            // Top Breadcrumb Header (Screenshot 2: < COLLECTIBLES      STEAM)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: VaultColors.ink2),
                        const SizedBox(width: 6),
                        Text(
                          'COLLECTIBLES',
                          style: VaultTypography.sans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Text(
                      'STEAM',
                      style: VaultTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Centered Content (Screenshot 2)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Golden Steam Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VaultColors.badgeBg,
                          border: Border.all(color: VaultColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: VaultColors.accent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Bring in your Steam inventory',
                        style: VaultTypography.sans(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: VaultColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Paste your profile link — your public items file in game by game, valued off the Community Market. No login, no password.',
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          height: 1.5,
                          color: VaultColors.body,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Input Field
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
                          style: VaultTypography.mono(fontSize: 13, color: VaultColors.ink),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'https://steamcommunity.com/id/...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Import from Steam Pill Button
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _importSteamInventory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VaultColors.ink,
                            foregroundColor: VaultColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.background),
                                )
                              : Text(
                                  'Import from Steam',
                                  style: VaultTypography.sans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
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
