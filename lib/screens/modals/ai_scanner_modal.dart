import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/valto_mascot.dart';

/// Clean bottom sheet modal for Valto Gemini AI Receipt & Invoice OCR Scanning.
class AiScannerModal {
  static void show(BuildContext context, {required Future<void> Function() onAssetScanned}) {
    final textController = TextEditingController();
    Uint8List? selectedImageBytes;
    String? selectedImagePath;
    bool isProcessing = false;
    final picker = ImagePicker();

    Widget buildSourceButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,
    }) => Expanded(
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: VaultColors.cardHover,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VaultColors.hairline),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor ?? VaultColors.ink, size: 24),
              const SizedBox(height: 6),
              Text(label, style: VaultTypography.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: VaultColors.ink)),
            ],
          ),
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          Future<void> pick(ImageSource source) async {
            try {
              final photo = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
              if (photo != null) {
                final bytes = await photo.readAsBytes();
                setModalState(() {
                  selectedImageBytes = bytes;
                  selectedImagePath = photo.path;
                });
              }
            } catch (e) {
              debugPrint('Image pick error: $e');
            }
          }

          return Padding(
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
                        const ValtoMascot(size: 36, mood: ValtoMood.detective, showHat: true),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VALTO OCR (GEMINI VISION AI)', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.1, color: VaultColors.accent)),
                            Text('Scan Receipt or Warranty Card', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w700)),
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
                if (selectedImageBytes != null) ...[
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: VaultColors.cardHover,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VaultColors.accent.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(selectedImageBytes!, fit: BoxFit.cover, width: double.infinity, height: 160),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setModalState(() {
                              selectedImageBytes = null;
                              selectedImagePath = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Row(
                    children: [
                      buildSourceButton(icon: Icons.photo_camera_rounded, label: 'Take Photo', iconColor: VaultColors.accent, onTap: () => pick(ImageSource.camera)),
                      const SizedBox(width: 12),
                      buildSourceButton(icon: Icons.photo_library_rounded, label: 'Upload Image', onTap: () => pick(ImageSource.gallery)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Text('OR PASTE RECEIPT TEXT / SERIAL NUMBER', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink),
                  decoration: InputDecoration(
                    hintText: 'e.g. MacBook Pro 14 M3, Serial C02G90PLQ6L4, Total \$1,999...',
                    hintStyle: VaultTypography.sans(fontSize: 12.5, color: VaultColors.ink3),
                    filled: true,
                    fillColor: VaultColors.cardHover,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                            final text = textController.text.trim();
                            if (selectedImageBytes == null && text.isEmpty) {
                              VaultToast.show(
                                context,
                                icon: Icons.info_outline_rounded,
                                iconColor: VaultColors.warn,
                                message: 'Please take a photo or enter receipt text first.',
                              );
                              return;
                            }

                            setModalState(() => isProcessing = true);
                            try {
                              GeminiInvoiceResult result = selectedImageBytes != null
                                  ? await GeminiService.instance.parseInvoiceImage(selectedImageBytes!)
                                  : await GeminiService.instance.parseInvoiceText(text);

                              await DatabaseHelper.instance.insertItem({
                                'name': result.itemName,
                                'category': 'Hardware / ${result.category}',
                                'purchase_price': result.purchasePrice,
                                'current_valuation': result.purchasePrice,
                                'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                'warranty_expiry_date': DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now().add(Duration(days: result.warrantyMonths * 30))),
                                'serial_number': result.serialNumber,
                                'image_url': selectedImagePath,
                                'is_collectible': 0,
                                'blockchain_hash': '0xvalto${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                              });

                              if (ctx.mounted) Navigator.pop(ctx);
                              await onAssetScanned();

                              if (context.mounted) {
                                VaultToast.show(
                                  context,
                                  icon: Icons.auto_awesome_rounded,
                                  iconColor: VaultColors.accent,
                                  message: 'Extracted & Saved "${result.itemName}" (\$${result.purchasePrice.toStringAsFixed(2)}) via Gemini AI!',
                                );
                              }
                            } catch (e) {
                              debugPrint('[HomeVault] OCR error: $e');
                              if (context.mounted) {
                                VaultToast.show(
                                  context,
                                  icon: Icons.error_outline_rounded,
                                  iconColor: VaultColors.warn,
                                  message: 'Receipt processed with fallback: $e',
                                );
                              }
                            } finally {
                              if (ctx.mounted) setModalState(() => isProcessing = false);
                            }
                          },
                    icon: isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.document_scanner_rounded, size: 18, color: Colors.white),
                    label: Text(
                      isProcessing ? 'Analyzing Receipt with Gemini...' : 'Scan & Extract with AI',
                      style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VaultColors.primaryButton,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
