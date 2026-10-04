import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';

class CollectiblesScreen extends StatefulWidget {
  const CollectiblesScreen({super.key});

  @override
  State<CollectiblesScreen> createState() => _CollectiblesScreenState();
}

class _CollectiblesScreenState extends State<CollectiblesScreen> {
  List<Map<String, dynamic>> _collectibles = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadCollectibles();
  }

  Future<void> _loadCollectibles() async {
    final all = await DatabaseHelper.instance.getItems();
    setState(() {
      _collectibles = all.where((i) => i['is_collectible'] == 1).toList();
      _isLoading = false;
    });
  }

  void _showAddCardModal() {
    final nameCtrl = TextEditingController(text: 'Pikachu Illustrator Promo');
    final paidCtrl = TextEditingController(text: '5000');
    final valCtrl = TextEditingController(text: '45000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Card / Collectible', style: VaultTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: VaultColors.ink2),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput('CARD NAME / EDITION', nameCtrl, 'e.g. Gengar VMAX Alt Art'),
              const SizedBox(height: 12),
              _buildInput('AMOUNT PAID (USD)', paidCtrl, '150.00', isNumber: true),
              const SizedBox(height: 12),
              _buildInput('CURRENT MARKET PRICE (USD)', valCtrl, '280.00', isNumber: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final paid = double.tryParse(paidCtrl.text) ?? 0.0;
                    final current = double.tryParse(valCtrl.text) ?? paid;

                    if (name.isNotEmpty) {
                      await DatabaseHelper.instance.insertItem({
                        'name': name,
                        'category': 'Collectibles / TCG',
                        'purchase_price': paid,
                        'current_valuation': current,
                        'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'warranty_expiry_date': null,
                        'serial_number': 'PSA-10-MINT',
                        'image_url': 'https://images.pokemontcg.io/base1/4_hires.png',
                        'is_collectible': 1,
                        'blockchain_hash': '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}card',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadCollectibles();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.ink,
                    foregroundColor: VaultColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add to Portfolio', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
            filled: true,
            fillColor: VaultColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalVal = 0.0;
    double totalCost = 0.0;
    for (var c in _collectibles) {
      totalVal += (c['current_valuation'] as num).toDouble();
      totalCost += (c['purchase_price'] as num).toDouble();
    }
    final totalGain = totalVal - totalCost;
    final pctGain = totalCost > 0 ? (totalGain / totalCost) * 100 : 0.0;

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: VaultColors.ink),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('Collectibles', style: VaultTypography.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: VaultColors.accent, size: 24),
            onPressed: _showAddCardModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PORTFOLIO MARKET VALUE', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.ink2)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currencyFormatter.format(totalVal),
                    style: VaultTypography.mono(fontSize: 32, fontWeight: FontWeight.w500, color: VaultColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: VaultColors.posBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${currencyFormatter.format(totalGain)} · +${pctGain.toStringAsFixed(1)}%',
                      style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.pos),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Price your cards against live TCGPlayer and Cardmarket feeds with instant arbitrage signals.',
                style: VaultTypography.cardDescription,
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: _collectibles.length,
                    itemBuilder: (ctx, idx) {
                      final item = _collectibles[idx];
                      final val = (item['current_valuation'] as num).toDouble();
                      final cost = (item['purchase_price'] as num).toDouble();
                      final diff = val - cost;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['image_url'] ?? 'https://images.pokemontcg.io/ex15/100_hires.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['name'] as String,
                              style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bought: ${currencyFormatter.format(cost)}',
                              style: VaultTypography.sans(fontSize: 10, color: VaultColors.ink2),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currencyFormatter.format(val),
                                  style: VaultTypography.mono(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink),
                                ),
                                Text(
                                  '+${currencyFormatter.format(diff)}',
                                  style: VaultTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w500, color: VaultColors.pos),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
