import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 1; // 0: Banks, 1: Investments, 2: Crypto

  final List<Map<String, dynamic>> _investments = [
    {
      'name': 'Stockbit',
      'asset': 'assets/logos/stockbit.png',
      'icon': Icons.insights_rounded,
      'color': const Color(0xFF2E7D4F),
    },
    {
      'name': 'Bibit',
      'asset': 'assets/logos/bibit.png',
      'icon': Icons.spa_rounded,
      'color': const Color(0xFF2E7D4F),
    },
    {
      'name': 'Ajaib',
      'asset': 'assets/logos/ajaib.png',
      'icon': Icons.auto_fix_high_rounded,
      'color': const Color(0xFF1E88E5),
    },
    {
      'name': 'IPOT',
      'asset': 'assets/logos/ipot.png',
      'icon': Icons.analytics_outlined,
      'color': const Color(0xFFD32F2F),
    },
    {
      'name': 'Pluang',
      'asset': 'assets/logos/pluang.png',
      'icon': Icons.all_inclusive_rounded,
      'color': const Color(0xFF7B1FA2),
    },
    {
      'name': 'Bareksa',
      'asset': 'assets/logos/bareksa.png',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF388E3C),
    },
    {
      'name': 'Other stock broker',
      'icon': Icons.show_chart_rounded,
      'color': VaultColors.ink2,
    },
    {
      'name': 'Other mutual fund',
      'icon': Icons.pie_chart_outline_rounded,
      'color': VaultColors.ink2,
    },
    {
      'name': 'Bonds / SBN',
      'icon': Icons.receipt_long_rounded,
      'color': VaultColors.accent,
    },
    {
      'name': 'Deposito',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF00897B),
    },
    {
      'name': 'Gold',
      'icon': Icons.view_in_ar_rounded,
      'color': VaultColors.accent,
    },
    {
      'name': 'Pension fund',
      'icon': Icons.verified_user_outlined,
      'color': const Color(0xFF43A047),
    },
    {
      'name': 'Property',
      'icon': Icons.home_work_outlined,
      'color': const Color(0xFFE53935),
    },
  ];

  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'Bank Central Asia (BCA)',
      'asset': 'assets/logos/bca.png',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF0D47A1),
    },
    {
      'name': 'Bank Mandiri',
      'asset': 'assets/logos/mandiri.png',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFFF57F17),
    },
    {
      'name': 'Bank BNI',
      'asset': 'assets/logos/bni.png',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF00695C),
    },
    {
      'name': 'Bank BRI',
      'asset': 'assets/logos/bri.png',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF0277BD),
    },
    {
      'name': 'Bank Jago',
      'asset': 'assets/logos/jago.png',
      'icon': Icons.savings_outlined,
      'color': const Color(0xFFFF8F00),
    },
    {
      'name': 'Jenius (BTPN)',
      'asset': 'assets/logos/jenius.png',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF00ACC1),
    },
    {
      'name': 'SeaBank',
      'asset': 'assets/logos/seabank.png',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xFFFF6F00),
    },
  ];

  final List<Map<String, dynamic>> _crypto = [
    {
      'name': 'Polygon Amoy Web3 Vault',
      'asset': 'assets/logos/polygon.png',
      'icon': Icons.token_rounded,
      'color': const Color(0xFF8247E5),
      'is_onchain': true,
    },
    {
      'name': 'MetaMask Wallet',
      'asset': 'assets/logos/metamask.png',
      'icon': Icons.security_rounded,
      'color': const Color(0xFFE65100),
      'is_onchain': true,
    },
    {
      'name': 'Trust Wallet',
      'asset': 'assets/logos/trustwallet.png',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF1565C0),
      'is_onchain': true,
    },
    {
      'name': 'Phantom Solana',
      'asset': 'assets/logos/phantom.png',
      'icon': Icons.electric_bolt_rounded,
      'color': const Color(0xFFAB47BC),
      'is_onchain': true,
    },
    {
      'name': 'Hardware Ledger Safe',
      'icon': Icons.memory_rounded,
      'color': VaultColors.ink,
      'is_onchain': false,
    },
  ];

  Widget _buildAccountLogo(Map<String, dynamic> item) {
    final String? assetPath = item['asset'] as String?;
    final IconData icon = item['icon'] as IconData;
    final Color color = item['color'] as Color;

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: VaultColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VaultColors.hairline),
      ),
      child: assetPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(icon, size: 22, color: color),
              ),
            )
          : Icon(icon, size: 22, color: color),
    );
  }

  void _showWeb3ConnectDialog(String walletName) {
    final addressCtrl = TextEditingController(text: '0x8A12F4b78912Cd7b3E51e89Ad51d02c914b1E190');
    bool isSyncing = false;
    double? fetchedTokens;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8247E5).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.token_rounded, color: Color(0xFF8247E5), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LIVE WEB3 ON-CHAIN SYNC', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: const Color(0xFF8247E5))),
                              Text('Connect $walletName', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: VaultColors.ink2),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('PUBLIC WALLET ADDRESS (0x...)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressCtrl,
                    style: VaultTypography.mono(fontSize: 12, color: VaultColors.ink),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: VaultColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NETWORK STATUS', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: VaultColors.pos)),
                            const SizedBox(width: 6),
                            Text('Polygon Amoy Testnet (80002)', style: VaultTypography.mono(fontSize: 10.5, fontWeight: FontWeight.w500, color: VaultColors.pos)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSyncing
                          ? null
                          : () async {
                              setModalState(() => isSyncing = true);
                              await Future.delayed(const Duration(milliseconds: 900));
                              setModalState(() {
                                isSyncing = false;
                                fetchedTokens = 245.50; // On-chain live tokens
                              });
                            },
                      icon: isSyncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.background))
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        isSyncing
                            ? 'Reading On-Chain State...'
                            : (fetchedTokens == null
                                ? 'Query Real-Time On-Chain Balance'
                                : 'Fetched: 245.50 POL (~US \$103.11)'),
                        style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: VaultColors.background),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.accent,
                        foregroundColor: VaultColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (fetchedTokens != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: VaultColors.card,
                              content: Text('Linked $walletName with \$103.11 USD balance!', style: VaultTypography.sans(color: VaultColors.pos)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VaultColors.ink,
                          foregroundColor: VaultColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save On-Chain Balance to Vault', style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: VaultColors.background)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBalanceDialog(String institution) {
    final balanceCtrl = TextEditingController(text: '10000000');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: VaultColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: VaultColors.hairline)),
          title: Text(institution, style: VaultTypography.sectionTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ENTER CURRENT BALANCE (IDR)', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
              const SizedBox(height: 8),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                style: VaultTypography.mono(fontSize: 16, color: VaultColors.ink),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VaultColors.background,
                  hintText: '10000000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VaultColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: VaultColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zero-knowledge manual sync preserves your banking credentials & privacy.',
                        style: VaultTypography.sans(fontSize: 10.5, color: VaultColors.ink2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: VaultTypography.sans(color: VaultColors.ink2)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: VaultColors.card,
                    content: Text('Linked $institution with balance Rp ${balanceCtrl.text}!', style: VaultTypography.sans(color: VaultColors.pos)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: VaultColors.ink, foregroundColor: VaultColors.background, elevation: 0),
              child: Text('Save Account', style: VaultTypography.sans(fontWeight: FontWeight.w600, color: VaultColors.background)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList;
    String sectionHeader;

    if (_selectedTabIndex == 0) {
      currentList = _banks;
      sectionHeader = 'CHECKING & DIGITAL BANKS';
    } else if (_selectedTabIndex == 1) {
      currentList = _investments;
      sectionHeader = 'INVESTMENTS & BROKERS';
    } else {
      currentList = _crypto;
      sectionHeader = 'WEB3 WALLETS & LEDGERS';
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = currentList.where((item) {
      return item['name'].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: VaultColors.ink),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 36),
                        child: Text(
                          'Add an account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: VaultColors.ink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (Screenshot 4)
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
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search banks, brokers, crypto...',
                          hintStyle: TextStyle(fontSize: 13, color: VaultColors.ink3),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Tabs ([ Banks ] [ Investments ] [ Crypto ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Banks'),
                    _buildTab(1, 'Investments'),
                    _buildTab(2, 'Crypto'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Description Label (Screenshot 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _selectedTabIndex == 2
                    ? 'On-chain tracking — input a public address to fetch real-time token balances directly.'
                    : 'Manual tracking — nothing links to your accounts. Pick where the money lives, then type the balance.',
                style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2, height: 1.3),
              ),
            ),
            const SizedBox(height: 14),

            // Section Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sectionHeader,
                  style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.ink2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid of Providers (Screenshot 4)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final item = filtered[idx];

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (_selectedTabIndex == 2 && item['is_onchain'] == true) {
                        _showWeb3ConnectDialog(item['name'] as String);
                      } else {
                        _showBalanceDialog(item['name'] as String);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAccountLogo(item),
                          const SizedBox(height: 8),
                          Text(
                            item['name'] as String,
                            style: VaultTypography.sans(fontSize: 10, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? VaultColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? VaultColors.hairline : Colors.transparent),
          ),
          child: Text(
            label,
            style: VaultTypography.sans(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? VaultColors.ink : VaultColors.ink2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
