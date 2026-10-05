import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allServices = [
    {'name': 'Netflix', 'category': 'Streaming', 'price': 15.49, 'icon': Icons.movie_outlined},
    {'name': 'Spotify', 'category': 'Music', 'price': 11.99, 'icon': Icons.music_note_rounded},
    {'name': 'Apple Music', 'category': 'Music', 'price': 10.99, 'icon': Icons.music_video_rounded},
    {'name': 'Apple One', 'category': 'Bundle', 'price': 19.95, 'icon': Icons.apple_rounded},
    {'name': 'Apple TV+', 'category': 'Streaming', 'price': 9.99, 'icon': Icons.tv_rounded},
    {'name': 'YouTube Premium', 'category': 'Streaming', 'price': 13.99, 'icon': Icons.play_circle_outline_rounded},
    {'name': 'YouTube Music', 'category': 'Music', 'price': 10.99, 'icon': Icons.queue_music_rounded},
    {'name': 'Paramount+', 'category': 'Streaming', 'price': 7.99, 'icon': Icons.video_library_outlined},
    {'name': 'Crunchyroll', 'category': 'Streaming', 'price': 7.99, 'icon': Icons.animation_rounded},
    {'name': 'Twitch', 'category': 'Streaming', 'price': 8.99, 'icon': Icons.live_tv_rounded},
    {'name': 'Deezer', 'category': 'Music', 'price': 11.99, 'icon': Icons.graphic_eq_rounded},
    {'name': 'Tidal', 'category': 'Music', 'price': 10.99, 'icon': Icons.album_outlined},
    {'name': 'SoundCloud', 'category': 'Music', 'price': 9.99, 'icon': Icons.cloud_outlined},
    {'name': 'Audible', 'category': 'Audio', 'price': 14.95, 'icon': Icons.headphones_rounded},
    {'name': 'Notion', 'category': 'Productivity', 'price': 10.00, 'icon': Icons.edit_note_rounded},
    {'name': 'ChatGPT Plus', 'category': 'AI & Tech', 'price': 20.00, 'icon': Icons.auto_awesome_rounded},
    {'name': 'GitHub Copilot', 'category': 'Developer', 'price': 10.00, 'icon': Icons.code_rounded},
    {'name': 'iCloud+ 200GB', 'category': 'Cloud Storage', 'price': 2.99, 'icon': Icons.cloud_done_rounded},
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _allServices.where((s) {
      return s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar (Screenshot 3: <     Add subscription)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: VaultColors.ink),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 36),
                        child: Text(
                          'Add subscription',
                          style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w600, color: VaultColors.ink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (Screenshot 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                        style: VaultTypography.sans(fontSize: 13.5, color: VaultColors.ink),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search a subscription...',
                          hintStyle: VaultTypography.sans(fontSize: 13.5, color: VaultColors.ink3),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section Label (Popular — 202 services — or type any name)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Popular — ${_allServices.length} services — or type any name',
                style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
              ),
            ),
            const SizedBox(height: 8),

            // Services List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (ctx, idx) {
                  final service = filtered[idx];

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await DatabaseHelper.instance.insertSubscription({
                        'service_name': service['name'],
                        'cost': service['price'],
                        'currency': 'USD',
                        'billing_cycle': 'monthly',
                        'renewal_date': DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10),
                        'category': service['category'],
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: VaultColors.card,
                            content: Text(
                              'Added ${service['name']} to your active subscriptions!',
                              style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.pos),
                            ),
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: VaultColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: VaultColors.hairline),
                            ),
                            child: Icon(service['icon'] as IconData, size: 20, color: VaultColors.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service['name'] as String, style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(service['category'] as String, style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2)),
                              ],
                            ),
                          ),
                          Text(
                            '\$${(service['price'] as double).toStringAsFixed(2)}',
                            style: VaultTypography.mono(fontSize: 13, color: VaultColors.ink2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
