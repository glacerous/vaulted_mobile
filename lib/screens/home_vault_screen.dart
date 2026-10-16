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
import 'warranty_lbs_screen.dart';
import 'game_screen.dart';

class HomeVaultScreen extends StatefulWidget {
  const HomeVaultScreen({super.key});

  @override
  State<HomeVaultScreen> createState() => _HomeVaultScreenState();
}

class _HomeVaultScreenState extends State<HomeVaultScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocus = FocusNode();

  late AnimationController _animController;
  static const int _frameCount = 36;

  bool _isBalanceVisible = true;
  double _inventoryTotal = 0.0;
  double _collectiblesTotal = 0.0;
  int _steamItemsCount = 0;
  String _selectedCurrency = 'IDR';

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _loadVaultData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (int i = 0; i < _frameCount; i++) {
      precacheImage(
        AssetImage('assets/images/alpine_dawn_frames/f_$i.png'),
        context,
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
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

  String _formatRawNumber(double usdAmount) {
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final converted = usdAmount * rate;
    if (_selectedCurrency == 'IDR' || _selectedCurrency == 'JPY') {
      return NumberFormat('#,###').format(converted);
    }
    return NumberFormat('#,##0.00').format(converted);
  }

  String get _currencyPrefix {
    switch (_selectedCurrency) {
      case 'IDR':
        return 'Rp ';
      case 'EUR':
        return '€ ';
      case 'JPY':
        return '¥ ';
      case 'USD':
      default:
        return '\$ ';
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
        setState(() => _valtoMood = ValtoMood.happy);
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

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. EXPANSIVE FULL-BLEED SCENIC SKY HEADER (Edge-to-Edge)
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  // Animated Scenic Dithered Background
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, _) {
                        final frameIndex = (_animController.value * _frameCount).floor() % _frameCount;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/alpine_dawn_frames/f_$frameIndex.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              gaplessPlayback: true,
                            ),
                            // Dreamy twilight overlay gradient matching the reference photo
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF5A4D7A).withValues(alpha: 0.35),
                                    const Color(0xFFC78B96).withValues(alpha: 0.20),
                                    const Color(0xFFFAF9F6).withValues(alpha: 0.65),
                                    VaultColors.background,
                                  ],
                                  stops: const [0.0, 0.45, 0.82, 1.0],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Header Content
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // UPGRADED APP BAR (Tactile Frosted Glass Controls)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Frosted circular button
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 15,
                                  color: Color(0xFF1D1D1B),
                                ),
                              ),

                              // Right: Frosted Capsule Cluster
                              Row(
                                children: [
                                  // Mini Calendar Badge
                                  Container(
                                    width: 36,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEA580C),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              DateFormat('MMM').format(now).toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              DateFormat('d').format(now),
                                              style: VaultTypography.mono(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF1D1D1B),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // AI Chat Quick Bubble
                                  GestureDetector(
                                    onTap: () => _promptFocus.requestFocus(),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.50),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 17,
                                        color: Color(0xFF1D1D1B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Refresh Sync Button
                                  GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await _loadVaultData();
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.50),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                        color: Color(0xFF1D1D1B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // GREETING LINE
                          Text(
                            '${_getGreeting()}, azzaky.',
                            style: VaultTypography.sans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1B),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // DATE SUBTITLE + PRIVACY EYE TOGGLE
                          Row(
                            children: [
                              Text(
                                'Today · ${DateFormat('EEEE, d MMMM').format(now)}',
                                style: VaultTypography.sans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1D1D1B).withValues(alpha: 0.60),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                child: Icon(
                                  _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 14,
                                  color: const Color(0xFF1D1D1B).withValues(alpha: 0.60),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // HERO BALANCE & MASCOT ROW
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _currencyPrefix,
                                          style: VaultTypography.mono(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1D1D1B).withValues(alpha: 0.65),
                                          ),
                                        ),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _isBalanceVisible ? _formatRawNumber(_netWorth) : '••••••••',
                                              style: VaultTypography.mono(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.8,
                                                color: const Color(0xFF1D1D1B),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_steamItemsCount vault items active',
                                      style: VaultTypography.sans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1D1D1B).withValues(alpha: 0.60),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _valtoMood = _valtoMood == ValtoMood.happy ? ValtoMood.vigilant : ValtoMood.happy;
                                      });
                                    },
                                    child: ValtoMascot(
                                      size: 58,
                                      mood: _valtoMood,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF141413),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ASK VALTO OMNIBAR
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Text('🐾', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _promptController,
                                    focusNode: _promptFocus,
                                    onSubmitted: (_) => _handlePromptSubmit(),
                                    style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink),
                                    decoration: InputDecoration(
                                      hintText: 'Ask Valto anything',
                                      hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_isAiProcessing)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 14),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.accent),
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: VaultColors.ink),
                                    onPressed: _handlePromptSubmit,
                                    splashRadius: 18,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // HORIZONTAL QUICK ACTION PILLS
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildQuickPill('1 bill this week', '📅', () {
                                  _promptController.text = 'Show pending bills this week';
                                  _handlePromptSubmit();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickPill('Where did it go?', '🔍', () {
                                  _promptController.text = 'Where did my expenses go this month?';
                                  _handlePromptSubmit();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickPill('Review my week', '📊', () {
                                  _promptController.text = 'Review vault changes for this week';
                                  _handlePromptSubmit();
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. MAIN CARD SURFACE (Activities & Vault Spaces)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: VaultColors.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141413).withValues(alpha: 0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Currency Switcher Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT ACTIVITY',
                              style: VaultTypography.mono(
                                fontSize: 10.5,
                                letterSpacing: 1.2,
                                color: VaultColors.ink2,
                              ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSel ? VaultColors.card : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        curr,
                                        style: VaultTypography.mono(
                                          fontSize: 9.5,
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
                        const SizedBox(height: 14),

                        // Transaction Items like in reference
                        _buildActivityItem(
                          icon: Icons.laptop_mac_rounded,
                          title: 'Apple MacBook Pro 14"',
                          subtitle: 'Hardware · Bank Mandiri',
                          amount: '- Rp 1,999,000',
                          isExpense: true,
                        ),
                        const Divider(height: 18, thickness: 1, color: VaultColors.hairline),
                        _buildActivityItem(
                          icon: Icons.sports_esports_rounded,
                          title: 'CS:GO AWP Dragon Lore',
                          subtitle: 'Steam Market · Valve OVO',
                          amount: '+ Rp 4,250,000',
                          isExpense: false,
                        ),
                        const Divider(height: 18, thickness: 1, color: VaultColors.hairline),
                        _buildActivityItem(
                          icon: Icons.watch_outlined,
                          title: 'Rolex Submariner 126610',
                          subtitle: 'Horology · Vaulted Local',
                          amount: '+ Rp 14,200,000',
                          isExpense: false,
                        ),
                        const SizedBox(height: 18),

                        // Black Primary Pill Button ("Check & close today" from reference)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Vault audited & confirmed for today.', style: VaultTypography.sans(fontSize: 12)),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF141413),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Check & close today',
                              style: VaultTypography.sans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons (Receipt & Voice)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Receipt OCR',
                          onTap: _showAiScannerModal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.mic_none_rounded,
                          label: 'Voice Logger',
                          onTap: _showVoiceModal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vault Pillars Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'YOUR VAULT SPACES',
                      style: VaultTypography.mono(fontSize: 10.5, letterSpacing: 1.2, color: VaultColors.ink2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VaultColors.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF141413).withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildPillarRow(
                          icon: Icons.sports_esports_rounded,
                          iconColor: VaultColors.accent,
                          title: 'Steam & Gaming Vault',
                          subtitle: '$_steamItemsCount verified items · Live Valve sync',
                          value: _formatAmount(_collectiblesTotal),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CollectiblesHubScreen()),
                            );
                            _loadVaultData();
                          },
                        ),
                        const Divider(height: 1, thickness: 1, color: VaultColors.hairline, indent: 68, endIndent: 16),
                        _buildPillarRow(
                          icon: Icons.laptop_mac_rounded,
                          iconColor: VaultColors.ink,
                          title: 'Hardware & Devices',
                          subtitle: 'Equipment, serials & on-chain proof',
                          value: _formatAmount(_inventoryTotal),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InventoryScreen()),
                            );
                            _loadVaultData();
                          },
                        ),
                        const Divider(height: 1, thickness: 1, color: VaultColors.hairline, indent: 68, endIndent: 16),
                        _buildPillarRow(
                          icon: Icons.monetization_on_outlined,
                          iconColor: VaultColors.accent,
                          title: "Valto's Appraisal Challenge",
                          subtitle: 'Market valuation mini-trial',
                          value: 'Play',
                          isAction: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GameScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1, color: VaultColors.hairline, indent: 68, endIndent: 16),
                        _buildPillarRow(
                          icon: Icons.near_me_rounded,
                          iconColor: VaultColors.ink2,
                          title: 'LBS Repair Centers',
                          subtitle: 'Authorized Apple & Samsung in Sleman',
                          value: 'Radar',
                          isAction: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WarrantyLbsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPill(String title, String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              title,
              style: VaultTypography.sans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isExpense,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: VaultColors.cardHover,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: VaultColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink3),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: VaultTypography.mono(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isExpense ? VaultColors.ink : const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VaultColors.hairline),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF141413).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: VaultColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    bool isAction = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VaultColors.cardHover,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VaultTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    subtitle,
                    style: VaultTypography.sans(
                      fontSize: 11.5,
                      color: VaultColors.ink2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: VaultTypography.mono(
                    fontSize: 12.5,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w700,
                    color: isAction ? VaultColors.accent : VaultColors.ink,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: VaultColors.ink3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
