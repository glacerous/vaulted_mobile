import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import 'pillars/inventory_screen.dart';
import 'pillars/collectibles_hub_screen.dart';
import 'pillars/add_subscription_screen.dart';
import 'pillars/add_account_screen.dart';

class HomeVaultScreen extends StatefulWidget {
  const HomeVaultScreen({super.key});

  @override
  State<HomeVaultScreen> createState() => _HomeVaultScreenState();
}

class _HomeVaultScreenState extends State<HomeVaultScreen> {
  bool _isBalanceVisible = true;
  double _inventoryTotal = 0.0;
  double _collectiblesTotal = 27500.00;
  String _selectedCurrency = 'USD';

  // Live exchange rates (Base USD)
  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'IDR': 15850.0,
    'EUR': 0.92,
    'JPY': 152.4,
  };

  @override
  void initState() {
    super.initState();
    _loadVaultData();
  }

  Future<void> _loadVaultData() async {
    final items = await DatabaseHelper.instance.getItems();
    double inv = 0.0;
    double col = 0.0;

    for (var item in items) {
      final val = (item['current_valuation'] as num).toDouble();
      if (item['is_collectible'] == 1) {
        col += val;
      } else {
        inv += val;
      }
    }

    setState(() {
      _inventoryTotal = inv;
      _collectiblesTotal = col > 0 ? col : 27500.00;
    });
  }

  double get _netWorth => _inventoryTotal + _collectiblesTotal;

  String _formatAmount(double usdAmount) {
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final converted = usdAmount * rate;

    switch (_selectedCurrency) {
      case 'IDR':
        return 'Rp ${NumberFormat('#,###').format(converted)}';
      case 'EUR':
        return '€${NumberFormat('#,##0.00').format(converted)}';
      case 'JPY':
        return '¥${NumberFormat('#,###').format(converted)}';
      case 'USD':
      default:
        return '\$${NumberFormat('#,##0.00').format(converted)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.brightness_low_rounded,
                        color: VaultColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VAULT',
                        style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: VaultColors.ink,
                        ),
                      ),
                    ],
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
              const SizedBox(height: 24),

              // Greeting
              RichText(
                text: TextSpan(
                  style: VaultTypography.sans(
                    fontSize: 15,
                    color: VaultColors.ink2,
                  ),
                  children: [
                    const TextSpan(text: 'Good evening, '),
                    TextSpan(
                      text: 'azzaky',
                      style: VaultTypography.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Header Row: Total Net Worth Label + Universal Currency Switcher (Slide 1 Integrated Currency)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL NET WORTH',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: VaultColors.ink2,
                    ),
                  ),
                  // Universal Currency Switcher Chips
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      children: ['USD', 'IDR', 'EUR', 'JPY'].map((curr) {
                        final isSelected = _selectedCurrency == curr;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCurrency = curr),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? VaultColors.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              curr,
                              style: VaultTypography.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? VaultColors.background : VaultColors.ink2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Big Money Counter + Eye Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isBalanceVisible
                        ? _formatAmount(_netWorth)
                        : '\$••••••••',
                    style: VaultTypography.mono(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: VaultColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Allocation Progress Bar & Legend
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: 3,
                  color: VaultColors.hairline,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (_inventoryTotal > 0 ? _inventoryTotal.toInt() : 1),
                        child: Container(color: VaultColors.ink2),
                      ),
                      const SizedBox(width: 1),
                      Expanded(
                        flex: (_collectiblesTotal > 0 ? _collectiblesTotal.toInt() : 99),
                        child: Container(color: VaultColors.accent.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendDot(VaultColors.ink2, 'Inventory', _formatAmount(_inventoryTotal)),
                  const SizedBox(width: 16),
                  _buildLegendDot(VaultColors.accent.withValues(alpha: 0.85), 'Collectibles', _formatAmount(_collectiblesTotal)),
                ],
              ),
              const SizedBox(height: 24),

              // 4 Pillar Cards (Clickable Navigation to respective screens!)
              SizedBox(
                height: 236,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. INVENTORY PILLAR
                    _buildPillarCard(
                      icon: Icons.work_outline_rounded,
                      title: 'Inventory',
                      sub: 'Catalog & Gear',
                      value: _formatAmount(_inventoryTotal),
                      description: 'Add your first item — a watch, a camera — and start valuing what you own.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InventoryScreen()),
                        ).then((_) => _loadVaultData());
                      },
                    ),
                    const SizedBox(width: 12),

                    // 2. COLLECTIBLES PILLAR
                    _buildPillarCard(
                      icon: Icons.layers_outlined,
                      title: 'Collectibles',
                      sub: '1 card tracked',
                      value: _formatAmount(_collectiblesTotal),
                      gainBadge: r'+$27,479.00 · +130852.4%',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CollectiblesHubScreen()),
                        ).then((_) => _loadVaultData());
                      },
                      customContent: Center(
                        child: Container(
                          height: 72,
                          width: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.pokemontcg.io/ex15/100_hires.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 3. SUBSCRIPTIONS PILLAR
                    _buildPillarCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Subscriptions',
                      sub: '3 active',
                      value: '${_formatAmount(38.00)} / mo',
                      description: 'Track renewals on a synchronized international billing calendar.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // 4. WEALTH MANAGEMENT PILLAR
                    _buildPillarCard(
                      icon: Icons.account_balance_outlined,
                      title: 'Wealth Management',
                      sub: '2 accounts',
                      value: _formatAmount(2395.74),
                      description: 'Add a bank, broker or Web3 wallet — record balances, watch the total move.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddAccountScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // TOP MOVER Card (Clickable to Collectibles)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollectiblesHubScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.pokemontcg.io/ex15/100_hires.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.north_east_rounded, size: 12, color: VaultColors.ink2),
                                const SizedBox(width: 4),
                                Text(
                                  'TOP MOVER',
                                  style: VaultTypography.mono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: VaultColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Charizard ★ δ',
                              style: VaultTypography.sans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dragon Frontiers - since you paid \$21.00',
                              style: VaultTypography.sans(
                                fontSize: 11,
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
                            _formatAmount(27479.00),
                            style: VaultTypography.mono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.pos,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+130852.4%',
                            style: VaultTypography.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: VaultColors.pos,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, String amount) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.5)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
        ),
        const SizedBox(width: 4),
        Text(
          amount,
          style: VaultTypography.mono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: VaultColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String sub,
    required String value,
    String? description,
    String? gainBadge,
    Widget? customContent,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: VaultColors.ink2),
                const Icon(Icons.north_east_rounded, size: 14, color: VaultColors.ink3),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: VaultTypography.cardLabel),
            Text(sub, style: VaultTypography.cardSub),
            const SizedBox(height: 10),
            Text(
              value,
              style: VaultTypography.mono(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: VaultColors.ink,
              ),
            ),
            if (gainBadge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VaultColors.posBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gainBadge,
                  style: VaultTypography.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: VaultColors.pos,
                  ),
                ),
              ),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: customContent != null
                    ? Center(child: customContent)
                    : (description != null
                        ? Text(
                            description,
                            style: VaultTypography.cardDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
