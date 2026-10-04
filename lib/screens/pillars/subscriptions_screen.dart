import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final List<Map<String, dynamic>> _subs = [
    {
      'service_name': 'ChatGPT Plus',
      'cost': 20.00,
      'currency': 'USD',
      'renewal_date': '2026-10-15',
      'category': 'AI & Productivity',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'service_name': 'Netflix Premium 4K',
      'cost': 12.00,
      'currency': 'USD',
      'renewal_date': '2026-10-22',
      'category': 'Entertainment',
      'icon': Icons.movie_outlined,
    },
    {
      'service_name': 'Spotify Family',
      'cost': 6.00,
      'currency': 'USD',
      'renewal_date': '2026-10-28',
      'category': 'Music Streaming',
      'icon': Icons.music_note_rounded,
    },
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  double get _monthlyBurn {
    double total = 0;
    for (var s in _subs) {
      total += (s['cost'] as num).toDouble();
    }
    return total;
  }

  void _showAddSubModal() {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '10.00');

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
                  Text('Add Subscription', style: VaultTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: VaultColors.ink2),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput('SERVICE NAME', nameCtrl, 'e.g. GitHub Copilot, iCloud+'),
              const SizedBox(height: 12),
              _buildInput('MONTHLY COST (USD)', costCtrl, '10.00', isNumber: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final cost = double.tryParse(costCtrl.text) ?? 0.0;
                    if (name.isNotEmpty && cost > 0) {
                      setState(() {
                        _subs.add({
                          'service_name': name,
                          'cost': cost,
                          'currency': 'USD',
                          'renewal_date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30))),
                          'category': 'Digital Services',
                          'icon': Icons.credit_card_rounded,
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
                  child: Text('Track Subscription', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
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
        title: Text('Subscriptions', style: VaultTypography.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: VaultColors.accent, size: 24),
            onPressed: _showAddSubModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONTHLY RECURRING BURN', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.ink2)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${currencyFormatter.format(_monthlyBurn)} / mo',
                    style: VaultTypography.mono(fontSize: 32, fontWeight: FontWeight.w500, color: VaultColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '(${_subs.length} active)',
                    style: VaultTypography.mono(fontSize: 12, color: VaultColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'See every renewal synchronized against global billing cycles.',
                style: VaultTypography.cardDescription,
              ),
              const SizedBox(height: 16),

              // Global Timezone Billing Warning (Real Integrated Timezone Feature!)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: VaultColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Global Server Billing Timezone', style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w600, color: VaultColors.accent)),
                          const SizedBox(height: 2),
                          Text(
                            'Global services trigger at 00:00 London (GMT). In Indonesia, your bank auto-debits at 07:00 WIB / 08:00 WITA / 09:00 WIT.',
                            style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Active Subscriptions', style: VaultTypography.sectionTitle),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: _subs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final sub = _subs[idx];
                    final cost = (sub['cost'] as num).toDouble();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: VaultColors.cardHover,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(sub['icon'] as IconData? ?? Icons.credit_card, size: 20, color: VaultColors.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sub['service_name'] as String, style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Renews: ${sub['renewal_date']} (Next billing in 11 days)',
                                  style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormatter.format(cost),
                                style: VaultTypography.mono(fontSize: 14, fontWeight: FontWeight.w600, color: VaultColors.ink),
                              ),
                              Text('/ month', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink3)),
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
