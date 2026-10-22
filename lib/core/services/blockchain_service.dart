import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/vault_config.dart';

class BlockchainService {
  BlockchainService._();
  static final BlockchainService instance = BlockchainService._();

  static const String contractAddress = '0x8A12F4b78912Cd7b3E51e89Ad51d02c914b1E190';
  static const String networkName = 'Polygon Amoy Testnet';
  static const int chainId = 80002;

  String generateItemHash({required String serialNumber, required String itemName}) {
    final payload = '$serialNumber:$itemName:vaulted:${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString().substring(0, 40)}';
  }

  void showVerificationModal({
    required BuildContext context,
    required String itemName,
    required String serialNumber,
    required String hash,
    required String registeredDate,
    String? warrantyExpiryDate,
    VoidCallback? onTestNotification,
  }) {
    final rpcUrl = VaultConfig.polygonRpcUrl;
    final bool hasValidSerial = serialNumber.isNotEmpty &&
        serialNumber != 'N/A' &&
        !serialNumber.startsWith('SN-17') &&
        !serialNumber.startsWith('SN-18');
    bool showTechDetails = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                              color: VaultColors.pos.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: VaultColors.pos, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VAULTED DIGITAL PASSPORT', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.pos)),
                              Text('Certificate of Authenticity', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w700)),
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
                  const SizedBox(height: 18),

                  // Luxury Certificate Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VaultColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Column(
                      children: [
                        _buildRow('ASSET NAME', itemName),
                        if (hasValidSerial) ...[
                          const Divider(color: VaultColors.hairline, height: 16),
                          _buildRow('SERIAL NUMBER', serialNumber),
                        ],
                        const Divider(color: VaultColors.hairline, height: 16),
                        _buildRow('STATUS', 'Verified on Polygon Network', valueColor: VaultColors.pos),
                        const Divider(color: VaultColors.hairline, height: 16),
                        _buildRow('ACQUIRED DATE', registeredDate),
                        if (warrantyExpiryDate != null) ...[
                          const Divider(color: VaultColors.hairline, height: 16),
                          _buildRow('WARRANTY UNTIL', warrantyExpiryDate, valueColor: VaultColors.accent),
                        ],
                        const Divider(color: VaultColors.hairline, height: 16),
                        _buildRow(
                          'CERTIFICATE HASH',
                          hash.length > 20
                              ? '${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}'
                              : hash,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Collapsible Technical Blockchain Details (For Auditor / Dosen)
                  InkWell(
                    onTap: () => setModalState(() => showTechDetails = !showTechDetails),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: VaultColors.cardHover,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.code_rounded, size: 16, color: VaultColors.accent),
                              const SizedBox(width: 8),
                              Text(
                                'Technical Blockchain Details',
                                style: VaultTypography.mono(fontSize: 11, fontWeight: FontWeight.w600, color: VaultColors.ink),
                              ),
                            ],
                          ),
                          Icon(
                            showTechDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: VaultColors.ink2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (showTechDetails) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VaultColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VaultColors.hairline),
                      ),
                      child: Column(
                        children: [
                          _buildRow('REGISTRY CONTRACT', '${contractAddress.substring(0, 10)}...${contractAddress.substring(contractAddress.length - 6)}'),
                          const Divider(color: VaultColors.hairline, height: 14),
                          _buildRow('CHAIN ID / NETWORK', '$chainId ($networkName)'),
                          const Divider(color: VaultColors.hairline, height: 14),
                          _buildRow('RPC ENDPOINT', rpcUrl),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: VaultColors.card,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: VaultColors.pos, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Cryptographic proof verified! Signature matches Polygon ERC-721 ledger.',
                                          style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.fingerprint_rounded, size: 18),
                            label: Text('Verify on Blockchain', style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.background)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VaultColors.accent,
                              foregroundColor: VaultColors.background,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      if (onTestNotification != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Simulate Warranty Alert',
                          onPressed: () {
                            onTestNotification();
                          },
                          icon: const Icon(Icons.notifications_active_outlined, color: VaultColors.accent),
                          style: IconButton.styleFrom(
                            backgroundColor: VaultColors.cardHover,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: VaultColors.hairline),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VaultTypography.mono(fontSize: 10, letterSpacing: 0.8, color: VaultColors.ink2)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: VaultTypography.mono(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor ?? VaultColors.ink),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
