import 'dart:ui';
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
  List<Map<String, dynamic>> _recentItems = [];

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
        _recentItems = items.take(4).toList();
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
                child: Text(
                  'Done',
                  style: VaultTypography.sans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualAddAssetModal() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final warrantyCtrl = TextEditingController(text: '12');
    String selectedCategory = 'Hardware';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: VaultColors.badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_box_rounded, color: VaultColors.accent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NEW ASSET ENTRY', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.1, color: VaultColors.accent)),
                              Text('Add High-Value Item', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w700)),
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
                  Text('ITEM NAME', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: VaultTypography.sans(fontSize: 13.5, color: VaultColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Sony WH-1000XM5, iPhone 15 Pro',
                      hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
                      filled: true,
                      fillColor: VaultColors.cardHover,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRICE (USD)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: VaultTypography.mono(fontSize: 13.5, color: VaultColors.ink),
                              decoration: InputDecoration(
                                hintText: '399.00',
                                hintStyle: VaultTypography.mono(fontSize: 13, color: VaultColors.ink3),
                                filled: true,
                                fillColor: VaultColors.cardHover,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WARRANTY (MO)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: warrantyCtrl,
                              keyboardType: TextInputType.number,
                              style: VaultTypography.mono(fontSize: 13.5, color: VaultColors.ink),
                              decoration: InputDecoration(
                                hintText: '12',
                                hintStyle: VaultTypography.mono(fontSize: 13, color: VaultColors.ink3),
                                filled: true,
                                fillColor: VaultColors.cardHover,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('SERIAL NUMBER (FOR LBS & WARRANTY)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: serialCtrl,
                    style: VaultTypography.mono(fontSize: 13, color: VaultColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. SN-SNY90841284',
                      hintStyle: VaultTypography.mono(fontSize: 12.5, color: VaultColors.ink3),
                      filled: true,
                      fillColor: VaultColors.cardHover,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                        final serial = serialCtrl.text.trim();
                        final warrantyMonths = int.tryParse(warrantyCtrl.text.trim()) ?? 12;

                        if (name.isEmpty || price <= 0) {
                          VaultToast.show(
                            context,
                            icon: Icons.error_outline_rounded,
                            iconColor: VaultColors.neg,
                            message: 'Please provide a valid item name and purchase price.',
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final itemMap = {
                          'name': name,
                          'category': 'Hardware / $selectedCategory',
                          'purchase_price': price,
                          'current_valuation': price * 0.95,
                          'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'warranty_expiry_date': DateFormat('yyyy-MM-dd').format(
                            DateTime.now().add(Duration(days: warrantyMonths * 30)),
                          ),
                          'serial_number': serial.isNotEmpty ? serial : 'SN-${DateTime.now().millisecondsSinceEpoch}',
                          'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
                          'is_collectible': 0,
                          'blockchain_hash': '0xvalto${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                        };

                        await DatabaseHelper.instance.insertItem(itemMap);
                        await _loadVaultData();

                        if (!mounted) return;
                        VaultToast.show(
                          context,
                          icon: Icons.check_circle_rounded,
                          iconColor: VaultColors.pos,
                          message: 'Saved $name to your Vault!',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141413),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        'Save Asset to Vault',
                        style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141413),
                        foregroundColor: Colors.white,
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


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white, // Pure white matching the sheet so no contrast sliver can ever appear
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. EXPANSIVE FULL-BLEED SCENIC SKY HEADER (Edge-to-Edge with Clear Separator)
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  // Animated Scenic Dithered Background (Full vivid scenery, NO fading gradient)
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
                            // Contrast Scrim ensuring crystal-clear text readability over mountains
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.40),
                                    Colors.black.withValues(alpha: 0.16),
                                    Colors.black.withValues(alpha: 0.48),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Glowing celestial moon in upper right as in reference photo
                            Positioned(
                              top: 48,
                              right: 28,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Header Content (Generous vertical spacing to make the scenic header wide & expansive)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 54),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AUTHENTIC VAULTED TOP APP BAR
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VAULTED',
                                style: VaultTypography.mono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.90),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      DateFormat('MMM d').format(now).toUpperCase(),
                                      style: VaultTypography.mono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D1D1B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _showAiScannerModal,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.90),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF1D1D1B)),
                                          const SizedBox(width: 5),
                                          Text(
                                            'SCAN OCR',
                                            style: VaultTypography.mono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                              color: const Color(0xFF1D1D1B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // GREETING LINE
                          Text(
                            '${_getGreeting()}, azzaky.',
                            style: VaultTypography.sans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // DATE SUBTITLE + PRIVACY EYE TOGGLE
                          Row(
                            children: [
                              Text(
                                'Today · ${DateFormat('EEEE, d MMMM').format(now)}',
                                style: VaultTypography.sans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                child: Icon(
                                  _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // HERO BALANCE (Full Width Clean Typography)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _currencyPrefix,
                                style: VaultTypography.mono(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _isBalanceVisible ? _formatRawNumber(_netWorth) : '••••••••',
                                    style: VaultTypography.mono(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.85),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_steamItemsCount vault items active',
                            style: VaultTypography.sans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 42),

                          // ASK VALTO FROSTED GLASS OMNIBAR WITH VALTO MASCOT PERCHED ON TOP
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.42),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.22),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _promptController,
                                            focusNode: _promptFocus,
                                            onSubmitted: (_) => _handlePromptSubmit(),
                                            style: VaultTypography.sans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Ask Valto anything',
                                              hintStyle: VaultTypography.sans(
                                                fontSize: 13,
                                                color: Colors.white.withValues(alpha: 0.80),
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        if (_isAiProcessing)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: _handlePromptSubmit,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.50),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Valto Mascot Sitting Directly on Top of the Frosted Glass Search Bar
                              Positioned(
                                top: -38,
                                right: 24,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _valtoMood = _valtoMood == ValtoMood.happy ? ValtoMood.vigilant : ValtoMood.happy;
                                    });
                                  },
                                  child: ValtoMascot(
                                    size: 46,
                                    mood: _valtoMood,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. MAIN COMPONENT SHEET (Smooth Circled Edge Seamlessly Overlapping Scenic Header)
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
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
                                    color: isSel ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
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

                    // Dynamic Activity Items from Real SQLite Data
                    if (_recentItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No assets tracked yet. Scan a receipt to start.',
                            style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink3),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (int i = 0; i < _recentItems.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 18, thickness: 1, color: VaultColors.hairline),
                            _buildDynamicActivityItem(_recentItems[i]),
                          ],
                        ],
                      ),
                    const SizedBox(height: 18),


                    // Quick Action Buttons (Receipt OCR & Add Manual Asset)
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
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add Asset',
                            onTap: _showManualAddAssetModal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Vault Pillars Section
                    Text(
                      'YOUR VAULT SPACES',
                      style: VaultTypography.mono(fontSize: 10.5, letterSpacing: 1.2, color: VaultColors.ink2),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: VaultColors.cardHover,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicActivityItem(Map<String, dynamic> item) {
    final cat = item['category']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Asset';
    final serial = item['serial_number']?.toString();
    final valuation = (item['current_valuation'] as num?)?.toDouble() ?? 0.0;

    IconData icon = Icons.inventory_2_outlined;
    if (cat.contains('Steam') || cat.contains('Gaming')) {
      icon = Icons.sports_esports_rounded;
    } else if (cat.contains('Hardware') || cat.contains('Device') || cat.contains('Laptop') || cat.contains('MacBook')) {
      icon = Icons.laptop_mac_rounded;
    } else if (cat.contains('Watch') || cat.contains('Horology') || cat.contains('Collectible')) {
      icon = Icons.watch_outlined;
    }

    final subtitle = serial != null && serial.isNotEmpty
        ? '$cat · SN: $serial'
        : (item['purchase_date'] != null ? '$cat · ${item['purchase_date']}' : cat);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        ).then((_) => _loadVaultData());
      },
      child: _buildActivityItem(
        icon: icon,
        title: name,
        subtitle: subtitle,
        amount: '+ ${_formatAmount(valuation)}',
        isExpense: false,
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
