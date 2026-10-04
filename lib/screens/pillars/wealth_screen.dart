import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  final List<Map<String, dynamic>> _accounts = [
    {
      'institution': 'BCA Prioritas Savings',
      'type': 'Cash & Checking',
      'balance': 24500000.0,
      'currency': 'IDR',
      'converted_usd': 1545.74,
      'icon': Icons.account_balance_rounded,
    },
    {
      'institution': 'Polygon Amoy Web3 Vault',
      'type': 'On-chain Wallet',
      'address': '0x71C...894Fa',
      'balance': 1.45,
      'currency': 'MATIC / ETH',
      'converted_usd': 850.00,
      'icon': Icons.token_rounded,
    },
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  double get _totalLiquidUsd {
    double total = 0;
    for (var a in _accounts) {
      total += (a['converted_usd'] as num).toDouble();
    }
    return total;
  }

  void _showAddAccountModal() {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '1000');

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
                  Text('Connect Account or Wallet', style: VaultTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: VaultColors.ink2),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput('INSTITUTION / WALLET NAME', nameCtrl, 'e.g. Bank Mandiri, MetaMask Polygon'),
              const SizedBox(height: 12),
              _buildInput('BALANCE (ESTIMATED USD)', balanceCtrl, '1000.00', isNumber: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final bal = double.tryParse(balanceCtrl.text) ?? 0.0;
                    if (name.isNotEmpty && bal > 0) {
                      setState(() {
                        _accounts.add({
                          'institution': name,
                          'type': 'Linked Account',
                          'balance': bal,
                          'currency': 'USD',
                          'converted_usd': bal,
                          'icon': Icons.account_balance_wallet_rounded,
                        });
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.ink,
                    foregroundColor: VaultColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Connect Account', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
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
    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: VaultColors.ink),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('Wealth Management', style: VaultTypography.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: VaultColors.accent, size: 24),
            onPressed: _showAddAccountModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL LIQUID BALANCES', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.ink2)),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(_totalLiquidUsd),
                style: VaultTypography.mono(fontSize: 32, fontWeight: FontWeight.w500, color: VaultColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Add bank accounts, brokerages, and on-chain Web3 wallets to see your full financial picture.',
                style: VaultTypography.cardDescription,
              ),
              const SizedBox(height: 20),

              Text('Connected Balances & Wallets', style: VaultTypography.sectionTitle),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: _accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final acc = _accounts[idx];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: VaultColors.cardHover,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(acc['icon'] as IconData? ?? Icons.account_balance, size: 20, color: VaultColors.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(acc['institution'] as String, style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  acc['address'] != null
                                      ? 'Web3 Address: ${acc['address']}'
                                      : acc['type'] as String,
                                  style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormatter.format(acc['converted_usd']),
                                style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w600, color: VaultColors.ink),
                              ),
                              Text(
                                '${acc['balance']} ${acc['currency']}',
                                style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink3),
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
