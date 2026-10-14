import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';
import '../core/services/valto_ai_service.dart';
import '../core/services/gemini_service.dart';
import '../core/widgets/valto_mascot.dart';
import 'pillars/inventory_screen.dart';
import 'pillars/collectibles_hub_screen.dart';
import 'pillars/add_subscription_screen.dart';
import 'warranty_lbs_screen.dart';

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
  int _collectiblesCount = 0;
  String _selectedCurrency = 'IDR';
  String _activeSpace = 'Personal Vault';
  bool _isDayClosed = false;
  int _streakDays = 3;
  double _todaySpent = 0.0;
  int _todayCount = 0;

  bool _isAiProcessing = false;
  ValtoMood _valtoMood = ValtoMood.peeking;

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
    int colCount = 0;

    for (var item in items) {
      final val = (item['current_valuation'] as num).toDouble();
      if (item['is_collectible'] == 1) {
        col += val;
        colCount++;
      } else {
        inv += val;
      }
    }

    if (mounted) {
      setState(() {
        _inventoryTotal = inv;
        _collectiblesTotal = col;
        _collectiblesCount = colCount;
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
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
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
        _showSuccessSheet(action);
      } else if (action.type == 'subscription') {
        _showSuccessSheet(action);
      } else {
        _showSuccessSheet(action);
      }

      _promptController.clear();
      _promptFocus.unfocus();
    } catch (e) {
      debugPrint('Valto prompt submit notice: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAiProcessing = false;
          _valtoMood = ValtoMood.peeking;
        });
      }
    }
  }

  void _showSuccessSheet(ValtoParsedAction action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: VaultColors.hairline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Row(
              children: [
                const ValtoMascot(size: 42, mood: ValtoMood.happy),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VALTO PARSED IT IN 1 SECOND', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.accent)),
                      Text(action.title, style: VaultTypography.sans(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: VaultColors.posBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(action.type.toUpperCase(), style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.pos)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: VaultColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.hairline)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount Logged', style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink2)),
                  Text(
                    action.currency == 'IDR' ? 'Rp ${NumberFormat('#,###').format(action.amount)}' : '\$${action.amount.toStringAsFixed(2)}',
                    style: VaultTypography.mono(fontSize: 16, fontWeight: FontWeight.w600, color: VaultColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VaultColors.accent,
                  foregroundColor: VaultColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Done · Return to Vault', style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
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
                          const ValtoMascot(size: 34, mood: ValtoMood.detective),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VALTO OCR ENGINE (GEMINI)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.accent)),
                              Text('Snap Receipt or Invoice', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w600)),
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
                  Text('INVOICE / RECEIPT TEXT', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: VaultTypography.mono(fontSize: 12, color: VaultColors.ink),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: VaultColors.background,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VaultColors.hairline)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                      label: Text(isProcessing ? 'Analyzing with Gemini...' : 'Extract & Save to Vault',
                          style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.accent,
                        foregroundColor: VaultColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: VaultColors.hairline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const ValtoMascot(size: 64, mood: ValtoMood.happy),
            const SizedBox(height: 14),
            Text('Listening to your voice...', style: VaultTypography.sans(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Say "kopi 25k bca" or "beli keyboard 500k garansi setahun"',
                style: VaultTypography.sans(fontSize: 13, color: VaultColors.body), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(shape: BoxShape.circle, color: VaultColors.accent.withValues(alpha: 0.15)),
              child: const Icon(Icons.mic_rounded, color: VaultColors.accent, size: 36),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: VaultTypography.sans(color: VaultColors.ink2)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now);
    final monthDayStr = DateFormat('MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. OYENZA-STYLE TOP BAR (Logo + Space Dropdown + Date + Receipt + Voice)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ValtoMascot(size: 28, mood: ValtoMood.idle),
                      const SizedBox(width: 8),
                      Text(
                        'VAULTED',
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: VaultColors.ink,
                        ),
                      ),
                    ],
                  ),

                  // Space Dropdown Capsule
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _activeSpace,
                        isDense: true,
                        dropdownColor: VaultColors.card,
                        icon: const Icon(Icons.unfold_more_rounded, size: 14, color: VaultColors.ink2),
                        style: VaultTypography.sans(fontSize: 11.5, fontWeight: FontWeight.w500, color: VaultColors.ink),
                        onChanged: (val) {
                          if (val != null) setState(() => _activeSpace = val);
                        },
                        items: ['Personal Vault', 'Gaming & Steam', 'Hardware Gear'].map((space) {
                          return DropdownMenuItem(value: space, child: Text(space));
                        }).toList(),
                      ),
                    ),
                  ),

                  // Quick Action Capsules (Date + Receipt + Voice)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        child: Text(
                          monthDayStr,
                          style: VaultTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w600, color: VaultColors.accent),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showAiScannerModal,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: VaultColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 16, color: VaultColors.ink),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showVoiceModal,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: VaultColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: const Icon(Icons.mic_none_rounded, size: 16, color: VaultColors.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. ICONIC OYENZA WARM SUNSET HERO BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B3E69), // Twilight lilac
                      Color(0xFF9E5748), // Warm sunset apricot
                      Color(0xFFBA7738), // Golden haze
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA7738).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: VaultTypography.mono(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getGreeting(),
                      style: VaultTypography.sans(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Say "coffee 25k" or snap a receipt. It takes two seconds.',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // VALTO THE CAT PEEKING + OMNIBAR
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Valto peeking over top of the omnibar
                        Positioned(
                          top: -30,
                          left: 20,
                          child: ValtoMascot(
                            size: 40,
                            mood: _valtoMood,
                          ),
                        ),

                        // Frosted Glass Omnibar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          padding: const EdgeInsets.only(left: 14, right: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.pets_rounded, size: 16, color: Color(0xFFFFD199)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _promptController,
                                  focusNode: _promptFocus,
                                  onSubmitted: (_) => _handlePromptSubmit(),
                                  style: VaultTypography.sans(fontSize: 13, color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ask Valto anything...',
                                    hintStyle: VaultTypography.sans(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _handlePromptSubmit,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black87,
                                  ),
                                  child: _isAiProcessing
                                      ? const Padding(
                                          padding: EdgeInsets.all(9),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. TODAY'S SUMMARY & STREAK CARD (Oyenza Habit Engine)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TODAY · ${DateFormat('EEE d MMM').format(now).toUpperCase()}',
                                style: VaultTypography.mono(fontSize: 9.5, letterSpacing: 1.1, color: VaultColors.ink2),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(color: const Color(0xFF2A2215), borderRadius: BorderRadius.circular(4)),
                                child: Text('$_streakDays DAY STREAK 🔥',
                                    style: VaultTypography.mono(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFE5A93C))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _todayCount > 0 ? 'Rp ${NumberFormat('#,###').format(_todaySpent)} logged today' : 'No payments yet today',
                            style: VaultTypography.sans(fontSize: 14.5, fontWeight: FontWeight.w600, color: VaultColors.ink),
                          ),
                          Text('Your streak and Valto Coins live in your account.',
                              style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.body)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isDayClosed = !_isDayClosed;
                          if (_isDayClosed) _streakDays++;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: VaultColors.card,
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: VaultColors.pos, size: 18),
                                const SizedBox(width: 8),
                                Text(_isDayClosed ? 'Day closed! Valto streak maintained 🔥' : 'Day reopened.',
                                    style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink)),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDayClosed ? VaultColors.posBg : VaultColors.cardHover,
                        foregroundColor: _isDayClosed ? VaultColors.pos : VaultColors.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(_isDayClosed ? 'Closed ✓' : 'Close day',
                          style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. NET WORTH & CURRENCY ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL VAULT NET WORTH', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.ink2)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _isBalanceVisible ? _formatAmount(_netWorth) : '••••••••',
                            style: VaultTypography.mono(fontSize: 24, fontWeight: FontWeight.w600, color: VaultColors.ink),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                            child: Icon(_isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 16, color: VaultColors.ink2),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Universal Currency Switcher
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: VaultColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: VaultColors.hairline)),
                    child: Row(
                      children: ['IDR', 'USD', 'EUR', 'JPY'].map((curr) {
                        final isSel = _selectedCurrency == curr;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCurrency = curr),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isSel ? VaultColors.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(curr,
                                style: VaultTypography.mono(
                                  fontSize: 9.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? VaultColors.background : VaultColors.ink2,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5. "YOUR FEATURES" GRID (Oyenza Style)
              Text('YOUR FEATURES', style: VaultTypography.mono(fontSize: 10.5, letterSpacing: 1.2, color: VaultColors.ink2)),
              const SizedBox(height: 10),

              // Feature Card 1: Steam & Gaming Vault (Real 38 Items)
              _buildFeatureCard(
                icon: Icons.sports_esports_rounded,
                iconColor: VaultColors.accent,
                title: 'Steam & Gaming Vault',
                subtitle: '$_collectiblesCount live assets synced with @xel',
                value: _formatAmount(_collectiblesTotal),
                badge: 'VALVE VERIFIED',
                badgeColor: VaultColors.pos,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectiblesHubScreen())).then((_) => _loadVaultData()),
              ),
              const SizedBox(height: 10),

              // Feature Card 2: Personal Hardware & Warranty Vault
              _buildFeatureCard(
                icon: Icons.laptop_mac_rounded,
                iconColor: const Color(0xFF66C0F4),
                title: 'Hardware & Warranty',
                subtitle: 'Physical gear catalog with active warranty tracking',
                value: _formatAmount(_inventoryTotal),
                badge: 'LBS REPAIR READY',
                badgeColor: const Color(0xFF66C0F4),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())).then((_) => _loadVaultData()),
              ),
              const SizedBox(height: 10),

              // Feature Card 3: Subscriptions & Recurring Burn
              _buildFeatureCard(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFFFFB5A7),
                title: 'Subscriptions & Burn Rate',
                subtitle: 'Track renewals on synchronized international billing calendar',
                value: '${_formatAmount(38.00)} / mo',
                badge: 'AUTO RENEW',
                badgeColor: const Color(0xFFFFB5A7),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubscriptionScreen())),
              ),
              const SizedBox(height: 10),

              // Feature Card 4: Repair Center Radar (LBS GPS)
              _buildFeatureCard(
                icon: Icons.location_on_rounded,
                iconColor: VaultColors.pos,
                title: 'Authorized Repair Radar (LBS)',
                subtitle: 'Find certified Apple, Samsung & Asus repair shops near you',
                value: '4 Centers Nearby',
                badge: 'GPS ACTIVE',
                badgeColor: VaultColors.pos,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarrantyLbsScreen())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: VaultColors.ink)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge, style: VaultTypography.mono(fontSize: 8.5, fontWeight: FontWeight.w600, color: badgeColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: VaultTypography.sans(fontSize: 11, color: VaultColors.body), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(value, style: VaultTypography.mono(fontSize: 15, fontWeight: FontWeight.w600, color: VaultColors.ink)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: VaultColors.ink3),
          ],
        ),
      ),
    );
  }
}
