import 'package:flutter/material.dart';

class HairlineVaultPlatform extends StatelessWidget {
  final double width;
  final double height;
  final bool isUnlocking;

  const HairlineVaultPlatform({
    super.key,
    required this.width,
    required this.height,
    this.isUnlocking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.shield_outlined,
          color: Color(0xFFC7A97A),
          size: 40,
        ),
      ),
    );
  }
}
