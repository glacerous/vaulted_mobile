import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';

/// Clean bottom sheet modal for manually adding high-value assets to the vault.
class ManualAssetModal {
  static void show(BuildContext context, {required Future<void> Function() onAssetSaved}) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final warrantyCtrl = TextEditingController(text: '12');
    String selectedCategory = 'Hardware';

    InputDecoration inputDeco(String hint, {String? prefix}) => InputDecoration(
      prefixText: prefix,
      prefixStyle: prefix != null
          ? VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: VaultColors.ink)
          : null,
      hintText: hint,
      hintStyle: VaultTypography.sans(fontSize: 13, color: VaultColors.ink3),
      filled: true,
      fillColor: VaultColors.cardHover,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );

    Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 22, right: 22, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38, height: 4,
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
                        decoration: BoxDecoration(color: VaultColors.badgeBg, borderRadius: BorderRadius.circular(8)),
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
              fieldLabel('ITEM NAME'),
              TextField(
                controller: nameCtrl,
                style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                decoration: inputDeco('e.g. MacBook Pro 16 M3 Max'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('VALUATION (USD)'),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: VaultTypography.sans(fontSize: 14, color: VaultColors.ink),
                          decoration: inputDeco('3499.00', prefix: '\$ '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('CATEGORY'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: VaultColors.cardHover, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              dropdownColor: VaultColors.card,
                              style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink),
                              items: ['Hardware', 'Gaming Rig', 'Display', 'Audio', 'Mobile']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('SERIAL NUMBER'),
                        TextField(
                          controller: serialCtrl,
                          style: VaultTypography.mono(fontSize: 12.5, color: VaultColors.ink),
                          decoration: inputDeco('Optional'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('WARRANTY (MOS)'),
                        TextField(
                          controller: warrantyCtrl,
                          keyboardType: TextInputType.number,
                          style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink),
                          decoration: inputDeco('12'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final serial = serialCtrl.text.trim();
                    final warrantyMonths = int.tryParse(warrantyCtrl.text.trim()) ?? 12;

                    if (name.isEmpty || price <= 0) {
                      VaultToast.show(
                        context,
                        icon: Icons.info_outline_rounded,
                        iconColor: VaultColors.warn,
                        message: 'Please provide valid Item Name and Valuation.',
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    await DatabaseHelper.instance.insertItem({
                      'name': name,
                      'category': selectedCategory,
                      'purchase_price': price,
                      'current_valuation': price,
                      'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'warranty_expiry_date': DateFormat('yyyy-MM-dd')
                          .format(DateTime.now().add(Duration(days: warrantyMonths * 30))),
                      'serial_number': serial.isNotEmpty ? serial : null,
                      'image_url': null,
                      'is_collectible': 0,
                      'blockchain_hash': '0xvalto${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                    });
                    await onAssetSaved();

                    if (!context.mounted) return;
                    VaultToast.show(
                      context,
                      icon: Icons.check_circle_rounded,
                      iconColor: VaultColors.pos,
                      message: 'Saved $name to your Vault!',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.primaryButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text('Save Asset to Vault', style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
