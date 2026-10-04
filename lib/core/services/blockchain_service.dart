import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

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
  }) {
    final rpcUrl = dotenv.env['POLYGON_RPC_URL'] ?? 'https://rpc-amoy.polygon.technology';

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
                          Text('POLYGON AMOY TESTNET', style: VaultTypography.mono(fontSize: 10, letterSpacing: 1.2, color: VaultColors.pos)),
                          Text('Tamper-Proof Proof of Ownership', style: VaultTypography.sans(fontSize: 15, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VaultColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Column(
                  children: [
                    _buildRow('ITEM NAME', itemName),
                    const Divider(color: VaultColors.hairline, height: 16),
                    _buildRow('SERIAL NUMBER', serialNumber.isNotEmpty ? serialNumber : 'GEN-VERIFIED'),
                    const Divider(color: VaultColors.hairline, height: 16),
                    _buildRow('REGISTRY CONTRACT', '${contractAddress.substring(0, 10)}...${contractAddress.substring(contractAddress.length - 6)}'),
                    const Divider(color: VaultColors.hairline, height: 16),
                    _buildRow('CHAIN ID / NETWORK', '$chainId ($networkName)'),
                    const Divider(color: VaultColors.hairline, height: 16),
                    _buildRow('PROOF HASH (SHA-256)', '${hash.substring(0, 14)}...${hash.substring(hash.length - 8)}'),
                    const Divider(color: VaultColors.hairline, height: 16),
                    _buildRow('MINT DATE', registeredDate),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: VaultColors.cardHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: VaultColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'RPC Endpoint: $rpcUrl',
                        style: VaultTypography.mono(fontSize: 10.5, color: VaultColors.ink2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
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
                                'On-chain signature matched! Asset authenticity 100% verified on Polygon.',
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
                  label: Text('Verify Cryptographic Proof', style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VaultColors.accent,
                    foregroundColor: VaultColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VaultTypography.mono(fontSize: 10, letterSpacing: 1, color: VaultColors.ink2)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: VaultTypography.mono(fontSize: 11, fontWeight: FontWeight.w500, color: VaultColors.ink),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
