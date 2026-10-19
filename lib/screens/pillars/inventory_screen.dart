import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/blockchain_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/image_utils.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _allItems = [];
  String _selectedFilter = 'All Hardware';
  String _selectedSort = 'Value ↓';
  bool _isLoading = true;

  // Search bar inventory
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Sensor 2: Gyroscope (kartu item miring mengikuti rotasi HP)
  static const double _maxTilt = 0.35; // radian
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  DateTime? _lastGyroTime;
  bool _gyroActive = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadItems();
    _initGyroscope();
  }

  void _initGyroscope() {
    if (kIsWeb) return; // sensor hanya tersedia di perangkat asli
    try {
      _gyroSub =
          gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            (GyroscopeEvent e) {
              final now = DateTime.now();
              final dt = _lastGyroTime == null
                  ? 0.02
                  : (now.difference(_lastGyroTime!).inMicroseconds / 1000000.0)
                        .clamp(0.001, 0.1)
                        .toDouble();
              _lastGyroTime = now;

              // Integrasi kecepatan sudut (rad/s) jadi sudut miring, lalu perlahan kembali ke 0
              final decay = exp(-3.0 * dt);
              final tx = ((_tilt.value.dx + e.y * dt) * decay)
                  .clamp(-_maxTilt, _maxTilt)
                  .toDouble();
              final ty = ((_tilt.value.dy + e.x * dt) * decay)
                  .clamp(-_maxTilt, _maxTilt)
                  .toDouble();
              _tilt.value = Offset(tx, ty);

              if (!_gyroActive && mounted) setState(() => _gyroActive = true);
            },
            onError: (_) {},
            cancelOnError: false,
          );
    } catch (_) {
      // Perangkat tanpa gyroscope: efek tilt dilewati
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _tilt.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final all = await DatabaseHelper.instance.getItems();
    setState(() {
      _allItems = all;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _items {
    // InventoryScreen is dedicated purely to physical Hardware, Tech & Devices.
    // Steam collectibles are managed in the Steam & Gaming Vault.
    final hardwareOnly = _allItems
        .where((i) => !i['category'].toString().startsWith('Steam') && i['is_collectible'] == 0)
        .toList();

    List<Map<String, dynamic>> list;
    if (_selectedFilter == 'Protected' || _selectedFilter == 'With Warranty') {
      list = hardwareOnly
          .where((i) => i['warranty_expiry_date'] != null && i['warranty_expiry_date'].toString().isNotEmpty)
          .toList();
    } else if (_selectedFilter == 'Apple' || _selectedFilter == 'Sony' || _selectedFilter == 'Samsung') {
      list = hardwareOnly
          .where((i) => (i['name'] ?? '').toString().toLowerCase().contains(_selectedFilter.toLowerCase()))
          .toList();
    } else {
      list = List.from(hardwareOnly);
    }

    // Pencarian: cocokkan nama, kategori, atau serial number
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((i) {
        final name = (i['name'] ?? '').toString().toLowerCase();
        final cat = (i['category'] ?? '').toString().toLowerCase();
        final serial = (i['serial_number'] ?? '').toString().toLowerCase();
        return name.contains(q) || cat.contains(q) || serial.contains(q);
      }).toList();
    }

    switch (_selectedSort) {
      case 'Value ↓':
        list.sort(
          (a, b) => ((b['current_valuation'] as num?)?.toDouble() ?? 0.0)
              .compareTo((a['current_valuation'] as num?)?.toDouble() ?? 0.0),
        );
        break;
      case 'Value ↑':
        list.sort(
          (a, b) => ((a['current_valuation'] as num?)?.toDouble() ?? 0.0)
              .compareTo((b['current_valuation'] as num?)?.toDouble() ?? 0.0),
        );
        break;
      case 'Name A-Z':
        list.sort(
          (a, b) => (a['name'] as String? ?? '').toLowerCase().compareTo(
            (b['name'] as String? ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Category':
        list.sort(
          (a, b) => (a['category'] as String? ?? '').toLowerCase().compareTo(
            (b['category'] as String? ?? '').toLowerCase(),
          ),
        );
        break;
    }
    return list;
  }

  void _showAiScannerModal() {
    final textController = TextEditingController(
      text: 'Apple Store Receipt #90214\nModel: Apple MacBook Pro 14" M3 Max\nSerial: C02G90PLQ6L4\nDate: 2024-03-12\nTotal: \$1,999.00 USD\nAppleCare+ Warranty: 24 Months Coverage Included',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                              color: VaultColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: VaultColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GOOGLE GEMINI 1.5 FLASH',
                                style: VaultTypography.mono(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: VaultColors.accent,
                                ),
                              ),
                              Text(
                                'AI Receipt & Warranty OCR',
                                style: VaultTypography.sans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: VaultColors.ink2,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PRESET RECEIPT SAMPLE',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip(
                          'MacBook Pro M3',
                          'Apple Store Receipt #90214\nModel: Apple MacBook Pro 14" M3 Max\nSerial: C02G90PLQ6L4\nTotal: \$1,999.00\nAppleCare: 24 Months',
                          textController,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          'Rolex Submariner',
                          'Bucherer Geneva Warranty Certificate\nRolex Submariner Date 126610LN\nSerial: RX-9918231\nPrice: \$10,250.00\nWarranty: 60 Months International',
                          textController,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          'Leica M11',
                          'Leica Store Wetzlar\nLeica M11 Rangefinder Black Paint\nSerial: LC-5829104\nTotal: \$8,995.00\nWarranty: 36 Months',
                          textController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'INVOICE / RECEIPT TEXT',
                    style: VaultTypography.mono(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: VaultTypography.mono(
                      fontSize: 12,
                      color: VaultColors.ink,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: VaultColors.background,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: VaultColors.hairline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: VaultColors.hairline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setModalState(() => isProcessing = true);
                              final result = await GeminiService.instance
                                  .parseInvoiceText(textController.text);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                _showAddItemModal(
                                  initialName: result.itemName,
                                  initialCategory: result.category,
                                  initialPrice: result.purchasePrice,
                                  initialSerial: result.serialNumber,
                                  initialWarranty: result.warrantyMonths,
                                );
                              }
                            },
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VaultColors.background,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        isProcessing
                            ? 'Analyzing with Gemini...'
                            : 'Extract & Auto-Fill',
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VaultColors.background,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.accent,
                        foregroundColor: VaultColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildPresetChip(
    String label,
    String sampleText,
    TextEditingController ctrl,
  ) {
    return InkWell(
      onTap: () => ctrl.text = sampleText,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: VaultColors.cardHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Text(
          label,
          style: VaultTypography.mono(fontSize: 11, color: VaultColors.ink),
        ),
      ),
    );
  }

  void _showAddItemModal({
    String? initialName,
    String? initialCategory,
    double? initialPrice,
    String? initialSerial,
    int? initialWarranty,
  }) {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final categoryCtrl = TextEditingController(
      text: initialCategory ?? 'Tech & Gadgets',
    );
    final priceCtrl = TextEditingController(
      text: initialPrice != null ? initialPrice.toStringAsFixed(2) : '',
    );
    final serialCtrl = TextEditingController(text: initialSerial ?? '');
    final warrantyCtrl = TextEditingController(
      text: (initialWarranty ?? 12).toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  Text(
                    'Add Inventory Item',
                    style: VaultTypography.sectionTitle,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: VaultColors.ink2,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput('ITEM NAME', nameCtrl, 'e.g. MacBook Pro 14" M3 Max'),
              const SizedBox(height: 12),
              _buildInput(
                'PURCHASE PRICE (USD)',
                priceCtrl,
                '1999.00',
                isNumber: true,
              ),
              const SizedBox(height: 12),
              _buildInput('SERIAL NUMBER', serialCtrl, 'C02G...'),
              const SizedBox(height: 12),
              _buildInput(
                'WARRANTY COVERAGE (MONTHS)',
                warrantyCtrl,
                '12',
                isNumber: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    final serial = serialCtrl.text.trim();
                    if (name.isNotEmpty && price > 0) {
                      final hash = BlockchainService.instance.generateItemHash(
                        serialNumber: serial,
                        itemName: name,
                      );

                      await DatabaseHelper.instance.insertItem({
                        'name': name,
                        'category': categoryCtrl.text,
                        'purchase_price': price,
                        'current_valuation': price * 0.9,
                        'purchase_date': DateFormat('yyyy-MM-dd')
                            .format(DateTime.now()),
                        'warranty_expiry_date': DateFormat('yyyy-MM-dd').format(
                          DateTime.now().add(
                            Duration(
                              days:
                                  (int.tryParse(warrantyCtrl.text) ?? 12) * 30,
                            ),
                          ),
                        ),
                        'serial_number': serial.isNotEmpty
                            ? serial
                            : 'SN-${DateTime.now().millisecondsSinceEpoch}',
                        'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
                        'is_collectible': 0,
                        'blockchain_hash': hash,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadItems();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.ink,
                    foregroundColor: VaultColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save & Mint On-Chain Proof',
                    style: VaultTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VaultColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VaultTypography.mono(
            fontSize: 10,
            letterSpacing: 1,
            color: VaultColors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: VaultTypography.sans(
              fontSize: 13,
              color: VaultColors.ink3,
            ),
            filled: true,
            fillColor: VaultColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: VaultColors.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: VaultColors.hairline),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = 0.0;
    for (var i in _items) {
      totalValue += (i['current_valuation'] as num).toDouble();
    }

    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('Hardware & Devices', style: VaultTypography.sectionTitle),
        actions: [
          IconButton(
            tooltip: 'AI Invoice Scanner (Gemini)',
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: VaultColors.accent,
              size: 22,
            ),
            onPressed: _showAiScannerModal,
          ),
          IconButton(
            tooltip: 'Add Hardware Item',
            icon: const Icon(
              Icons.add_rounded,
              color: VaultColors.ink,
              size: 24,
            ),
            onPressed: () => _showAddItemModal(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL HARDWARE VALUE',
                style: VaultTypography.mono(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: VaultColors.ink2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(totalValue),
                style: VaultTypography.mono(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Catalog physical gear, gadgets, watches, and cameras with warranty tracking.',
                style: VaultTypography.cardDescription,
              ),
              const SizedBox(height: 14),
              _buildGyroStatus(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 12),
              // Category filter pills for hardware only
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      'All Hardware',
                      _allItems.where((i) => !i['category'].toString().startsWith('Steam') && i['is_collectible'] == 0).length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'With Warranty',
                      _allItems
                          .where((i) =>
                              !i['category'].toString().startsWith('Steam') &&
                              i['is_collectible'] == 0 &&
                              i['warranty_expiry_date'] != null &&
                              i['warranty_expiry_date'].toString().isNotEmpty)
                          .length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Sort Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SORT BY',
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  Row(
                    children: ['Value ↓', 'Value ↑', 'Name A-Z', 'Category']
                        .map((sortKey) {
                          final isSelected = _selectedSort == sortKey;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedSort = sortKey);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? VaultColors.accent
                                    : VaultColors.card,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? VaultColors.accent
                                      : VaultColors.hairline,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                sortKey,
                                style: VaultTypography.mono(
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? VaultColors.background
                                      : VaultColors.ink2,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_items.isEmpty && _query.trim().isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No items match "$_query".',
                      style: VaultTypography.cardDescription,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_items.isEmpty)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 36,
                            color: VaultColors.ink3,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No hardware logged yet',
                            style: VaultTypography.sans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your tech gear, laptops, cameras, or timepieces — or scan an invoice using Gemini OCR.',
                            style: VaultTypography.cardDescription,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showAddItemModal(),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: VaultColors.background,
                                ),
                                label: Text(
                                  'Add Item',
                                  style: VaultTypography.sans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: VaultColors.background,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VaultColors.ink,
                                  foregroundColor: VaultColors.background,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _showAiScannerModal,
                                icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: VaultColors.accent,
                                ),
                                label: Text(
                                  'Scan Receipt',
                                  style: VaultTypography.sans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: VaultColors.ink,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VaultColors.cardHover,
                                  foregroundColor: VaultColors.ink,
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: VaultColors.hairline,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = _items[idx];
                      final val = (item['current_valuation'] as num).toDouble();
                      final purchase = (item['purchase_price'] as num)
                          .toDouble();
                      final warranty = item['warranty_expiry_date'] as String?;
                      final serial = item['serial_number'] as String? ?? 'N/A';
                      final hash =
                          item['blockchain_hash'] as String? ?? '0x7bfa8...';
                      final registeredDate =
                          item['purchase_date'] as String? ?? '2024-03-01';

                      final card = InkWell(
                        onTap: () {
                          BlockchainService.instance.showVerificationModal(
                            context: context,
                            itemName: item['name'] as String,
                            serialNumber: serial,
                            hash: hash,
                            registeredDate: registeredDate,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VaultColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: VaultColors.hairline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: VaultColors.cardHover,
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          vaultImageUrl(
                                            item['image_url'] as String?,
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: VaultTypography.sans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Paid: ${currencyFormatter.format(purchase)} · S/N: $serial',
                                          style: VaultTypography.sans(
                                            fontSize: 11,
                                            color: VaultColors.ink2,
                                          ),
                                        ),
                                        if (warranty != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Warranty until $warranty',
                                            style: VaultTypography.mono(
                                              fontSize: 10,
                                              color: VaultColors.accent,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormatter.format(val),
                                        style: VaultTypography.mono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: VaultColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-10.0%',
                                        style: VaultTypography.mono(
                                          fontSize: 10,
                                          color: VaultColors.neg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(
                                color: VaultColors.hairline,
                                height: 1,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 13,
                                        color: VaultColors.pos,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Polygon Amoy: ${hash.length > 14 ? "${hash.substring(0, 14)}..." : hash}',
                                        style: VaultTypography.mono(
                                          fontSize: 10,
                                          color: VaultColors.ink2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final sent = await NotificationService
                                          .instance
                                          .showWarrantyAlert(
                                            itemName: item['name'] as String,
                                            daysLeft: 42,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor: VaultColors.card,
                                            content: Text(
                                              sent
                                                  ? '🔔 Warranty notification dispatched for ${item['name']}!'
                                                  : 'Notification simulated for ${item['name']}.',
                                              style: VaultTypography.sans(
                                                fontSize: 12,
                                                color: VaultColors.ink,
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VaultColors.cardHover,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: VaultColors.hairline,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.notifications_active_outlined,
                                            size: 12,
                                            color: VaultColors.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Test Alert',
                                            style: VaultTypography.mono(
                                              fontSize: 9.5,
                                              color: VaultColors.accent,
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
                        ),
                      );

                      // Kartu miring 3D mengikuti gyroscope
                      return ValueListenableBuilder<Offset>(
                        valueListenable: _tilt,
                        builder: (context, t, child) => Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateX(-t.dy * 0.6)
                            ..rotateY(t.dx * 0.6),
                          child: child,
                        ),
                        child: card,
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

  Widget _buildSearchBar() {
    return Container(
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
              controller: _searchCtrl,
              style: VaultTypography.sans(
                fontSize: 13.5,
                color: VaultColors.ink,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search name, category, serial...',
                hintStyle: VaultTypography.sans(
                  fontSize: 13.5,
                  color: VaultColors.ink3,
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: VaultColors.ink3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGyroStatus() {
    final String label;
    if (_gyroActive) {
      label = 'GYROSCOPE ACTIVE · tilt your phone to inspect cards';
    } else if (kIsWeb) {
      label = 'GYROSCOPE N/A ON WEB · run on a real device';
    } else {
      label = 'GYROSCOPE WAITING FOR SENSOR...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VaultColors.badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_rotation_rounded,
            size: 14,
            color: _gyroActive ? VaultColors.pos : VaultColors.ink3,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<Offset>(
              valueListenable: _tilt,
              builder: (context, t, _) => Text(
                _gyroActive
                    ? '$label\nx: ${t.dy.toStringAsFixed(2)}  y: ${t.dx.toStringAsFixed(2)} rad'
                    : label,
                style: VaultTypography.mono(
                  fontSize: 9.5,
                  color: VaultColors.ink2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? VaultColors.accent : VaultColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? VaultColors.accent : VaultColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: VaultTypography.sans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? VaultColors.background : VaultColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? VaultColors.background.withValues(alpha: 0.25)
                    : VaultColors.cardHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: VaultTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? VaultColors.background : VaultColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
