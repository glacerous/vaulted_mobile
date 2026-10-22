import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modals/ai_scanner_modal.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/supabase_service.dart';

import '../../core/services/blockchain_service.dart';
import '../../core/widgets/vault_thumbnail.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _allItems = [];
  String _selectedFilter = 'All Hardware';
  String _selectedSort = 'Highest';
  bool _isLoading = true;

  // Search bar inventory
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadItems();
    _syncCloudInBackground();
  }

  Future<void> _syncCloudInBackground() async {
    try {
      final res = await SupabaseService.instance.syncTwoWay();
      if ((res['pulled'] as int? ?? 0) > 0 && mounted) {
        _loadItems();
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    try {
      final res = await SupabaseService.instance.syncTwoWay();
      await _loadItems();
      if (mounted) {
        final pulled = res['pulled'] as int? ?? 0;
        if (pulled > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: VaultColors.card,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Cloud Sync: $pulled new asset(s) retrieved.',
                style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
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

  Future<bool> _showDeleteConfirmationDialog(String itemName) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VaultColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VaultColors.hairline),
        ),
        title: Text(
          'Remove Asset?',
          style: VaultTypography.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: VaultColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$itemName" from your vault? This will update your total net worth and cloud sync across your devices.',
          style: VaultTypography.sans(fontSize: 13, color: VaultColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: VaultTypography.mono(
                fontSize: 12,
                color: VaultColors.ink2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VaultColors.neg.withValues(alpha: 0.15),
              foregroundColor: VaultColors.neg,
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: VaultTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VaultColors.neg,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _executeDeleteItem(Map<String, dynamic> item) async {
    final itemName = item['name'] as String? ?? 'this asset';
    final id = item['id'];
    final hash = item['blockchain_hash'] as String?;
    final serial = item['serial_number'] as String?;
    final name = item['name'] as String?;

    setState(() {
      _items.removeWhere((it) {
        if (id != null && it['id'] == id) return true;
        if (hash != null && it['blockchain_hash'] == hash) return true;
        if (serial != null && serial.isNotEmpty && it['serial_number'] == serial) return true;
        if (name != null && it['name'] == name) return true;
        return false;
      });
    });

    await DatabaseHelper.instance.deleteItem(
      id,
      blockchainHash: hash,
      serialNumber: serial,
      name: name,
    );

    await SupabaseService.instance.deleteItemOnline(
      id: id,
      blockchainHash: hash,
      serialNumber: serial,
      name: name,
    );

    await _loadItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VaultColors.card,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: VaultColors.pos, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Removed "$itemName" from your vault.',
                  style: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDeleteItem(Map<String, dynamic> item) async {
    final itemName = item['name'] as String? ?? 'this asset';
    final confirmed = await _showDeleteConfirmationDialog(itemName);
    if (confirmed) {
      await _executeDeleteItem(item);
      return true;
    }
    return false;
  }

  void _showSortSheet() {
    HapticFeedback.selectionClick();
    const options = [
      {'key': 'Highest', 'label': 'Highest Value', 'icon': Icons.arrow_downward_rounded},
      {'key': 'Lowest', 'label': 'Lowest Value', 'icon': Icons.arrow_upward_rounded},
      {'key': 'Name A-Z', 'label': 'Alphabetical (A - Z)', 'icon': Icons.sort_by_alpha_rounded},
      {'key': 'Category', 'label': 'Category', 'icon': Icons.category_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VaultColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SORT HARDWARE',
                  style: VaultTypography.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: VaultColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final key = opt['key'] as String;
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSel = _selectedSort == key;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSel ? VaultColors.cardHover : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? VaultColors.accent : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        icon,
                        size: 18,
                        color: isSel ? VaultColors.accent : VaultColors.ink2,
                      ),
                      title: Text(
                        label,
                        style: VaultTypography.sans(
                          fontSize: 13.5,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? VaultColors.ink : VaultColors.ink2,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_rounded, size: 18, color: VaultColors.accent)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSort = key);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _items {
    // InventoryScreen is dedicated purely to physical Hardware, Tech & Devices.
    // Steam collectibles are managed in the Steam & Gaming Vault.
    final hardwareOnly = _allItems
        .where(
          (i) =>
              !i['category'].toString().startsWith('Steam') &&
              i['is_collectible'] == 0,
        )
        .toList();

    List<Map<String, dynamic>> list;
    if (_selectedFilter == 'Protected' || _selectedFilter == 'With Warranty') {
      list = hardwareOnly
          .where(
            (i) =>
                i['warranty_expiry_date'] != null &&
                i['warranty_expiry_date'].toString().isNotEmpty,
          )
          .toList();
    } else if (_selectedFilter == 'Apple' ||
        _selectedFilter == 'Sony' ||
        _selectedFilter == 'Samsung') {
      list = hardwareOnly
          .where(
            (i) => (i['name'] ?? '').toString().toLowerCase().contains(
              _selectedFilter.toLowerCase(),
            ),
          )
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
      case 'Highest':
        list.sort(
          (a, b) => ((b['current_valuation'] as num?)?.toDouble() ?? 0.0)
              .compareTo((a['current_valuation'] as num?)?.toDouble() ?? 0.0),
        );
        break;
      case 'Lowest':
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
    AiScannerModal.show(context, onAssetScanned: _loadItems);
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
                        'current_valuation': price,
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
                        'serial_number': serial.isNotEmpty ? serial : null,
                        'image_url': null,
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hardware & Devices',
              style: VaultTypography.sans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: VaultColors.ink,
              ),
            ),
            Text(
              'Physical Assets & Equipment',
              style: VaultTypography.mono(
                fontSize: 10.5,
                color: VaultColors.ink2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Invoice OCR Scanner',
            icon: const Icon(
              Icons.receipt_long_rounded,
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
                      _allItems
                          .where(
                            (i) =>
                                !i['category'].toString().startsWith('Steam') &&
                                i['is_collectible'] == 0,
                          )
                          .length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'With Warranty',
                      _allItems
                          .where(
                            (i) =>
                                !i['category'].toString().startsWith('Steam') &&
                                i['is_collectible'] == 0 &&
                                i['warranty_expiry_date'] != null &&
                                i['warranty_expiry_date'].toString().isNotEmpty,
                          )
                          .length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sort button — tap to open bottom sheet (consistent with Steam Vault)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'HARDWARE & DEVICES',
                    style: VaultTypography.mono(
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                      color: VaultColors.ink2,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: VaultColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 14, color: VaultColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            _selectedSort,
                            style: VaultTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: VaultColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  child: RefreshIndicator(
                    color: VaultColors.accent,
                    backgroundColor: VaultColors.card,
                    onRefresh: _handleRefresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = _items[idx];
                      final val = (item['current_valuation'] as num).toDouble();
                      final purchase = (item['purchase_price'] as num)
                          .toDouble();
                      final warranty = item['warranty_expiry_date'] as String?;
                      final rawSerial = item['serial_number'] as String?;
                      final hasRealSerial = rawSerial != null &&
                          rawSerial.isNotEmpty &&
                          rawSerial != 'N/A' &&
                          !rawSerial.startsWith('SN-17') &&
                          !rawSerial.startsWith('SN-18');
                      final serial = hasRealSerial ? rawSerial : '';
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
                            warrantyExpiryDate: warranty,
                            onDelete: () => _confirmDeleteItem(item),
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
                                  VaultThumbnail(
                                    imageUrl: item['image_url'] as String?,
                                    category: item['category'] as String?,
                                    name: item['name'] as String?,
                                    width: 44,
                                    height: 44,
                                    borderRadius: 8,
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
                                          hasRealSerial
                                              ? 'Paid: ${currencyFormatter.format(purchase)} · S/N: $serial'
                                              : 'Paid: ${currencyFormatter.format(purchase)}',
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
                            ],
                          ),
                        ),
                      );

                      final dismissibleKey = ValueKey(
                        item['id']?.toString() ??
                            item['blockchain_hash']?.toString() ??
                            item['serial_number']?.toString() ??
                            'item_$idx',
                      );

                      return Dismissible(
                        key: dismissibleKey,
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final itemName = item['name'] as String? ?? 'this asset';
                          return await _showDeleteConfirmationDialog(itemName);
                        },
                        onDismissed: (_) {
                          _executeDeleteItem(item);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: VaultColors.neg.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: VaultColors.neg.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'REMOVE',
                                style: VaultTypography.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: VaultColors.neg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: VaultColors.neg,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        child: card,
                      );
                    },
                  ),
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
