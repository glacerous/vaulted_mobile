import 'package:flutter/material.dart';
import 'vault_door_3d.dart';

export 'vault_door_3d.dart';

/// HairlineVault — Renders the architectural 3D Vault Door with authentic mechanical swing.
class HairlineVault extends StatelessWidget {
  final double size;
  final bool isUnlocking;
  final VoidCallback? onUnlocked;

  const HairlineVault({
    super.key,
    this.size = 180,
    this.isUnlocking = false,
    this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VaultDoor3D(
        size: size,
        isUnlocking: isUnlocking,
        onOpened: onUnlocked,
      ),
    );
  }
}
