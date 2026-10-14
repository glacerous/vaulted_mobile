import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/services/valto_ai_service.dart';
import '../core/services/gemini_service.dart';
import '../core/widgets/valto_mascot.dart';
import '../core/widgets/ascii_cloud_sea_header.dart';
import 'pillars/inventory_screen.dart';
import 'pillars/collectibles_hub_screen.dart';
import 'warranty_lbs_screen.dart';
import 'game_screen.dart';

class HomeVaultScreen extends StatefulWidget {
  const HomeVaultScreen({super.key});

  @override
  State<HomeVaultScreen> createState() => _HomeVaultScreenState();
}

class _HomeVaultScreenState extends State<HomeVaultScreen> {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocus = FocusNode();

  bool _isBalanceVisible = true;
  double _inventoryTotal = 0.0;
  double _collectiblesTotal = 0.0;
  int _steamItemsCount = 0;
  String _selectedCurrency = 'IDR';
  bool _isDayClosed = false;
  int _streakDays = 3;
  double _todaySpent = 0.0;
  int _todayCount = 0;

  bool _isAiProcessing = false;
  ValtoMood _valtoMood = ValtoMood.vigilant;

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

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  Future<void> _loadVaultData() async {
    final items = await DatabaseHelper.instance.getItems();
    double inv = 0.0;
    double col = 0.0;
    int steamCount = 0;

    for (var item in items) {
      final val = (item['current_valuation'] as num).toDouble();
      if (item['category'].toString().startsWith('Steam')) {
        col += val;
        steamCount++;
      } else if (item['is_collectible'] == 1) {
        col += val;
      } else {
        inv += val;
      }
    }

    if (mounted) {
      setState(() {
        _inventoryTotal = inv;
        _collectiblesTotal = col;
        _steamItemsCount = steamCount;
      });
    }
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handlePromptSubmit() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _isAiProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isAiProcessing = true;
      _valtoMood = ValtoMood.detective;
    });

    try {
      final action = await ValtoAiService.instance.parseNaturalInput(text);

      if (!mounted) return;

      if (action.type == 'expense') {
        setState(() {
          _todaySpent += action.amount;
          _todayCount++;
          _valtoMood = ValtoMood.happy;
        });
        _showSuccessSheet(action);
      } else if (action.type == 'hardware') {
        final usdAmount = action.currency == 'IDR' ? action.amount / 15850.0 : action.amount;
        await DatabaseHelper.instance.insertItem({
          'name': action.title,
          'category': 'Hardware / ${action.category}',
          'purchase_price': usdAmount,
          'current_valuation': usdAmount * 0.9,
          'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'warranty_expiry_date': action.warrantyMonths != null
              ? DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: action.warrantyMonths! * 30)))
              : null,
          'serial_number': action.serialNumber ?? 'SN-${DateTime.now().millisecondsSinceEpoch}',
          'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
          'is_collectible': 0,
          'blockchain_hash': '0xvalto${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        });
        await _loadVaultData();
        setState(() => _valtoMood = ValtoMood.happy);
        _showSuccessSheet(action);
      } else {
        setState(() => _valtoMood = ValtoMood.vigilant);
        _showSuccessSheet(action);
      }

      _promptController.clear();
      _promptFocus.unfocus();
    } catch (_) {
      if (mounted) setState(() => _valtoMood = ValtoMood.vigilant);
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  void _showSuccessSheet(ValtoParsedAction action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: VaultColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const ValtoMascot(size: 40, mood: ValtoMood.happy),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VALTO NOTED YOUR ACTION',
                        style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.1, color: VaultColors.accent),
                      ),
                      Text(
                        action.title,
                        style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w700, color: VaultColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: VaultColors.cardHover,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Logged Amount', style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink2)),
                  Text(
                    action.currency == 'IDR'
                        ? 'Rp ${NumberFormat('#,###').format(action.amount)}'
                        : '\$${action.amount.toStringAsFixed(2)}',
                    style: VaultTypography.mono(fontSize: 16, fontWeight: FontWeight.w700, color: VaultColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VaultColors.primaryButton,
                  foregroundColor: VaultColors.primaryButtonInk,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text('Done', style: VaultTypography.sans(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiScannerModal() {
    final textController = TextEditingController(
      text: 'Apple Store Receipt #90214\nModel: Apple MacBook Pro 14" M3 Max\nSerial: C02G90PLQ6L4\nDate: 2024-03-12\nTotal: \$1,999.00 USD\nWarranty: 24 Months Coverage Included',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(color: VaultColors.hairline, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const ValtoMascot(size: 36, mood: ValtoMood.detective, showHat: true),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VALTO OCR (GEMINI AI)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.1, color: VaultColors.accent)),
                              Text('Scan Receipt or Warranty', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w700)),
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: VaultTypography.mono(fontSize: 12, color: VaultColors.ink),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: VaultColors.cardHover,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setModalState(() => isProcessing = true);
                              final result = await GeminiService.instance.parseInvoiceText(textController.text);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                await DatabaseHelper.instance.insertItem({
                                  'name': result.itemName,
                                  'category': 'Hardware / ${result.category}',
                                  'purchase_price': result.purchasePrice,
                                  'current_valuation': result.purchasePrice * 0.9,
                                  'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                  'warranty_expiry_date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: result.warrantyMonths * 30))),
                                  'serial_number': result.serialNumber,
                                  'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
                                  'is_collectible': 0,
                                  'blockchain_hash': '0xvalto${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                                });
                                _loadVaultData();
                              }
                            },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        isProcessing ? 'Analyzing with Gemini...' : 'Extract & Save to Vault',
                        style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.primaryButton,
                        foregroundColor: VaultColors.primaryButtonInk,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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

  void _showVoiceModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 38, height: 4, decoration: BoxDecoration(color: VaultColors.hairline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const ValtoMascot(size: 64, mood: ValtoMood.detective),
            const SizedBox(height: 14),
            Text('Valto is listening...', style: VaultTypography.sans(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Say "kopi 25k bca" or "beli steam deck 500 usd garansi 24 bln"',
              style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(shape: BoxShape.circle, color: VaultColors.badgeBg),
              child: const Icon(Icons.mic_rounded, color: VaultColors.accent, size: 36),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink2)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final datePill = DateFormat('MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MINIMAL APP HEADER (Iconic Valto + Brand + Actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ValtoMascot(size: 32, mood: ValtoMood.peeking),
                      const SizedBox(width: 10),
                      Text(
                        'VAULTED',
                        style: VaultTypography.sans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: VaultColors.ink,
                        ),
                      ),
                    ],
                  ),

                  // Header Action Buttons
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VaultColors.cardHover,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          datePill,
                          style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.ink2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAiScannerModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 16, color: VaultColors.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showVoiceModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mic_none_rounded, size: 16, color: VaultColors.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. ALPINE DAWN DITHERED SCENIC HEADER (Permanent signature artwork)
              AlpineDawnHeader(
                promptController: _promptController,
                promptFocus: _promptFocus,
                isAiProcessing: _isAiProcessing,
                valtoMood: _valtoMood,
                onSubmit: _handlePromptSubmit,
              ),
              const SizedBox(height: 20),

              // 3. FOCAL GLANCE HERO (Giant Net Worth & Status Pill)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF141413).withValues(alpha: 0.03),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle & Status indicator (Like Oyenza • You're on the waitlist)
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VaultColors.pos,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$_steamItemsCount Steam items & vault assets active',
                          style: VaultTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: VaultColors.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Huge Bold Primary Counter
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _isBalanceVisible ? _formatAmount(_netWorth) : '••••••••',
                            style: VaultTypography.mono(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: VaultColors.ink,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: VaultColors.cardHover,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 16,
                              color: VaultColors.ink2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Currency Segment Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getGreeting()}, azzaky',
                          style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink3),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: ['IDR', 'USD', 'EUR', 'JPY'].map((curr) {
                              final isSel = _selectedCurrency == curr;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCurrency = curr);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isSel ? VaultColors.card : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    curr,
                                    style: VaultTypography.mono(
                                      fontSize: 10,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      color: isSel ? VaultColors.ink : VaultColors.ink2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. VALTO GUARDIAN ASSISTANT & HABIT STREAK CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF141413).withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ValtoMascot(
                      size: 42,
                      mood: _isDayClosed ? ValtoMood.sleeping : ValtoMood.vigilant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'VALTO GUARDIAN',
                                style: VaultTypography.mono(fontSize: 9.5, letterSpacing: 1, color: VaultColors.accent),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: VaultColors.badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_streakDays-DAY STREAK 🔥',
                                  style: VaultTypography.mono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: VaultColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _todayCount > 0
                                ? 'Rp ${NumberFormat('#,###').format(_todaySpent)} logged today'
                                : 'Valto is keeping watch. Vault secure.',
                            style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: VaultColors.ink),
                          ),
                          Text(
                            _isDayClosed ? 'Day closed · Streak preserved' : 'Tap to close today\'s ledger',
                            style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink2),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isDayClosed = !_isDayClosed;
                          if (_isDayClosed) {
                            _streakDays++;
                            _valtoMood = ValtoMood.happy;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDayClosed ? VaultColors.posBg : VaultColors.cardHover,
                        foregroundColor: _isDayClosed ? VaultColors.pos : VaultColors.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(
                        _isDayClosed ? 'Closed ✓' : 'Close day',
                        style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. VAULT PILLARS SECTION (Clean, Airy Mobile Cards)
              Text(
                'YOUR VAULT SPACES',
                style: VaultTypography.mono(fontSize: 10.5, letterSpacing: 1.2, color: VaultColors.ink2),
              ),
              const SizedBox(height: 12),

              // Pillar 1: Steam & Collectibles Hub (Real 38 Synced Items)
              _buildCleanPillarCard(
                icon: Icons.sports_esports_rounded,
                iconColor: VaultColors.accent,
                title: 'Steam & Gaming Vault',
                subtitle: '$_steamItemsCount verified items · Live Valve market prices',
                value: _formatAmount(_collectiblesTotal),
                badge: 'SYNCED',
                badgeColor: VaultColors.pos,
                badgeBg: VaultColors.posBg,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollectiblesHubScreen()),
                  );
                  _loadVaultData();
                },
              ),
              const SizedBox(height: 12),

              // Pillar 2: Hardware & Asset Inventory (MacBook, Warranties, Blockchain)
              _buildCleanPillarCard(
                icon: Icons.laptop_mac_rounded,
                iconColor: VaultColors.ink,
                title: 'Hardware & Devices',
                subtitle: 'Laptops, phones & equipment with on-chain proof',
                value: _formatAmount(_inventoryTotal),
                badge: 'WARRANTY ACTIVE',
                badgeColor: VaultColors.accent,
                badgeBg: VaultColors.badgeBg,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                  _loadVaultData();
                },
              ),
              const SizedBox(height: 12),

              // Pillar 3: Valto's Appraisal Minigame
              _buildCleanPillarCard(
                icon: Icons.monetization_on_outlined,
                iconColor: VaultColors.accent,
                title: "Valto's Appraisal Challenge",
                subtitle: 'Test your knowledge on real market valuation',
                value: 'Play',
                badge: 'MINIGAME',
                badgeColor: VaultColors.pos,
                badgeBg: VaultColors.posBg,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Pillar 4: LBS Service Center Radar
              _buildCleanPillarCard(
                icon: Icons.near_me_rounded,
                iconColor: VaultColors.ink2,
                title: 'LBS Repair Centers',
                subtitle: 'Find authorized Apple & Samsung repair in Sleman',
                value: 'Radar',
                badge: 'GPS SENSOR',
                badgeColor: VaultColors.ink2,
                badgeBg: VaultColors.cardHover,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WarrantyLbsScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanPillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF141413).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VaultColors.cardHover,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w700, color: VaultColors.ink),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge,
                          style: VaultTypography.mono(fontSize: 8.5, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: VaultTypography.mono(fontSize: 12.5, fontWeight: FontWeight.w700, color: VaultColors.ink),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: VaultColors.ink3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
