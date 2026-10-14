import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import 'vowl_mascot.dart';

/// Isometric Anatomy Desk Computer inspired by Ryan's Anatomy collection (skills.wheresryan.sh/anatomy/collection/computer).
/// Merges tactile 3D isometric vintage workstation geometry with the 2D pixel-art cat guardian Valto.
class AnatomyDeskComputer extends StatefulWidget {
  final VoidCallback? onTerminalTap;
  final VoidCallback? onKeyTap;
  final ValueChanged<String>? onPinEntered;

  const AnatomyDeskComputer({
    super.key,
    this.onTerminalTap,
    this.onKeyTap,
    this.onPinEntered,
  });

  @override
  State<AnatomyDeskComputer> createState() => _AnatomyDeskComputerState();
}

class _AnatomyDeskComputerState extends State<AnatomyDeskComputer>
    with TickerProviderStateMixin {
  // Cursor blink controller
  late AnimationController _cursorController;

  // Cat mood state
  ValtoMood _catMood = ValtoMood.vigilant;

  // Terminal screen state
  String _typedPin = '';
  String _statusLine = 'KEEPER: VALTO [ONLINE]';
  String _subStatusLine = 'STATUS: ENCLAVE LOCKED';
  bool _powerOn = true;

  // Pressed key index for interactive keyboard bounce
  int? _pressedKeyIndex;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _handleCatTap() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_catMood) {
        case ValtoMood.vigilant:
          _catMood = ValtoMood.happy;
          _statusLine = 'VALTO: ^_^ PURRR...';
          _subStatusLine = 'ENCLAVE DEFENSES: 100%';
          break;
        case ValtoMood.happy:
          _catMood = ValtoMood.playful;
          _statusLine = 'VALTO: *WAVES PAW*';
          _subStatusLine = 'OPERATOR DETECTED';
          break;
        case ValtoMood.playful:
          _catMood = ValtoMood.sleeping;
          _statusLine = 'VALTO: zzz... WARM CRT';
          _subStatusLine = 'MONITORING IN SLEEP';
          break;
        case ValtoMood.sleeping:
          _catMood = ValtoMood.detective;
          _statusLine = 'VALTO: MONOCLE EQUIPPED';
          _subStatusLine = 'INSPECTING ASSETS...';
          break;
        case ValtoMood.detective:
        default:
          _catMood = ValtoMood.vigilant;
          _statusLine = 'KEEPER: VALTO [ONLINE]';
          _subStatusLine = 'STATUS: ENCLAVE LOCKED';
          break;
      }
    });
  }

  void _handleKeyTap(int keyIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _pressedKeyIndex = keyIndex;
      if (_typedPin.length < 8) {
        _typedPin += '*';
      } else {
        _typedPin = '*';
      }
      _statusLine = 'KEY_IN: PIN [${_typedPin.length}/6]';
      _subStatusLine = 'AUTH BUFFER RECEIVING...';
    });

    widget.onKeyTap?.call();

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _pressedKeyIndex = null;
        });
      }
    });
  }

  void _handlePowerToggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _powerOn = !_powerOn;
      if (_powerOn) {
        _statusLine = 'VAULT-OS BOOT // OK';
        _subStatusLine = 'AUTHENTICATION READY';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 330,
        height: 290,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. ISOMETRIC DESK COMPUTER CUSTOM PAINTER (Chassis, screen bezel, vents, coiled cable, keyboard base)
            Positioned.fill(
              child: CustomPaint(
                painter: _AnatomyComputerPainter(
                  powerOn: _powerOn,
                  pressedKeyIndex: _pressedKeyIndex,
                ),
              ),
            ),

            // 2. INTERACTIVE CRT DISPLAY SCREEN AREA
            Positioned(
              left: 72,
              top: 76,
              width: 104,
              height: 94,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTerminalTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  decoration: BoxDecoration(
                    color: _powerOn ? const Color(0xFF141311) : const Color(0xFF0D0D0C),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _powerOn
                          ? const Color(0xFF2A2824)
                          : const Color(0xFF1F1E1B),
                      width: 1.2,
                    ),
                    boxShadow: _powerOn
                        ? [
                            BoxShadow(
                              color: VaultColors.accent.withValues(alpha: 0.08),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: _powerOn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'VAULT-OS v2.6',
                                      style: VaultTypography.mono(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.w700,
                                        color: VaultColors.accent,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF55B374), // Green terminal dot
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(height: 0.5, color: const Color(0xFF2E2C27)),
                                const SizedBox(height: 3),
                                Text(
                                  _statusLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VaultTypography.mono(
                                    fontSize: 6.8,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE2DDD3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _subStatusLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VaultTypography.mono(
                                    fontSize: 6.2,
                                    color: VaultColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                            // Terminal Command Prompt Line
                            AnimatedBuilder(
                              animation: _cursorController,
                              builder: (context, _) {
                                final cursorVisible = _cursorController.value > 0.45;
                                return Row(
                                  children: [
                                    Text(
                                      _typedPin.isEmpty
                                          ? '> UNLOCK_'
                                          : '> PIN: $_typedPin',
                                      style: VaultTypography.mono(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                        color: VaultColors.accent,
                                      ),
                                    ),
                                    if (cursorVisible && _typedPin.isNotEmpty)
                                      Text(
                                        '█',
                                        style: VaultTypography.mono(
                                          fontSize: 6.5,
                                          color: VaultColors.accent,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        )
                      : Center(
                          child: Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF333330),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // 3. POWER SWITCH INTERACTIVE HITBOX
            Positioned(
              left: 74,
              top: 178,
              width: 18,
              height: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handlePowerToggle,
                child: const SizedBox.expand(),
              ),
            ),

            // 4. INTERACTIVE KEYBOARD HITBOXES
            // Spacebar & Keys
            Positioned(
              left: 55,
              top: 228,
              width: 170,
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleKeyTap(0),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleKeyTap(1), // Spacebar
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleKeyTap(2),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),

            // 5. VALTO 2D PIXEL ART CAT PERCHED DIRECTLY ON TOP OF CRT
            Positioned(
              left: 108,
              top: 4, // Resting on the flat top plane of the monitor
              child: GestureDetector(
                onTap: _handleCatTap,
                child: Tooltip(
                  message: 'Tap Valto',
                  child: ValtoMascot(
                    size: 66,
                    mood: _catMood,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for Ryan's Anatomy-style desk computer.
/// Renders authentic isometric planes with four-tone warm porcelain/titanium shading.
class _AnatomyComputerPainter extends CustomPainter {
  final bool powerOn;
  final int? pressedKeyIndex;

  _AnatomyComputerPainter({
    required this.powerOn,
    this.pressedKeyIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF262422)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round;

    final hairlinePaint = Paint()
      ..color = const Color(0xFF383531)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // 1. SOFT DESKTOP DROP SHADOW (Diffused underneath machine and keyboard)
    final shadowPath = Path()
      ..moveTo(40, 245)
      ..lineTo(225, 205)
      ..lineTo(290, 165)
      ..lineTo(270, 140)
      ..lineTo(70, 200)
      ..close();

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x16000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ----------------------------------------------------
    // 2. MAIN COMPUTER CHASSIS (Deep CRT Housing)
    // ----------------------------------------------------
    // Palette:
    // Top roof face: Light porcelain/cream `#EDE8DF`
    // Front screen bezel: Medium warm tone `#DFD9CE`
    // Right depth side face: Darker tone with shadow `#CDC6B9`
    // Recessed chin: `#BFB8AA`

    // A. Top Roof Plane (where Valto sits)
    final topRoof = Path()
      ..moveTo(64, 66)
      ..lineTo(188, 48)
      ..lineTo(248, 28)
      ..lineTo(124, 46)
      ..close();

    canvas.drawPath(topRoof, Paint()..color = const Color(0xFFEBE6DC));
    canvas.drawPath(topRoof, hairlinePaint);

    // B. Right Depth Side Face
    final rightSide = Path()
      ..moveTo(188, 48)
      ..lineTo(248, 28)
      ..lineTo(248, 148)
      ..lineTo(188, 172)
      ..close();

    canvas.drawPath(rightSide, Paint()..color = const Color(0xFFC7C0B2));
    canvas.drawPath(rightSide, linePaint);

    // Right Side Cooling Vents (Horizontal architectural slit lines)
    final ventPaint = Paint()
      ..color = const Color(0xFF8F887C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final yOffset = 64.0 + (i * 12.0);
      final ventStart = Offset(202, yOffset);
      final ventEnd = Offset(236, yOffset - 11);
      canvas.drawLine(ventStart, ventEnd, ventPaint);
    }

    // Side Cable Receptacle Port
    final portCenter = const Offset(214, 142);
    canvas.drawCircle(
      portCenter,
      4.5,
      Paint()..color = const Color(0xFF262422),
    );
    canvas.drawCircle(
      portCenter,
      2.0,
      Paint()..color = const Color(0xFF5A554E),
    );

    // C. Front Screen Bezel Plane
    final frontFace = Path()
      ..moveTo(64, 66)
      ..lineTo(188, 48)
      ..lineTo(188, 172)
      ..lineTo(64, 190)
      ..close();

    canvas.drawPath(frontFace, Paint()..color = const Color(0xFFDFDAD0));
    canvas.drawPath(frontFace, linePaint);

    // D. Front Bezel Inset Border (Surrounding the screen)
    final screenBezel = Path()
      ..moveTo(70, 74)
      ..lineTo(178, 58)
      ..lineTo(178, 172)
      ..lineTo(70, 188)
      ..close();

    canvas.drawPath(
      screenBezel,
      Paint()
        ..color = const Color(0xFF282623)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // E. Lower Chin Detail (Floppy Disk Drive Slot & Power Switch)
    // Floppy Slot Line (angled matching perspective)
    canvas.drawLine(
      const Offset(104, 180),
      const Offset(158, 172),
      Paint()
        ..color = const Color(0xFF262422)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.square,
    );
    // Floppy Slot Gold Eject Button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(162, 169, 7, 4),
        const Radius.circular(1),
      ),
      Paint()..color = VaultColors.accent, // Warm gold luxury accent
    );

    // Power Rocker Switch & Green/Amber Status LED
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 181, 12, 6),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF33312E),
    );
    // Power LED Dot
    canvas.drawCircle(
      const Offset(72, 184),
      1.8,
      Paint()..color = powerOn ? const Color(0xFF55B374) : const Color(0xFF6E6A63),
    );

    // ----------------------------------------------------
    // 3. COILED CABLE (Connecting Keyboard to Side Port)
    // ----------------------------------------------------
    final cablePaint = Paint()
      ..color = const Color(0xFF302E2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cablePath = Path()..moveTo(214, 142); // From side port

    // Spiral coils down to the desk
    cablePath.cubicTo(230, 155, 238, 180, 230, 195);
    cablePath.cubicTo(225, 205, 215, 212, 222, 222);
    cablePath.cubicTo(226, 228, 220, 235, 212, 238);
    cablePath.lineTo(195, 240); // Enters keyboard back

    canvas.drawPath(cablePath, cablePaint);

    // ----------------------------------------------------
    // 4. MECHANICAL KEYBOARD PLATFORM
    // ----------------------------------------------------
    // Keyboard Base Isometric Coordinates
    final kbFrontLeft = const Offset(42, 248);
    final kbFrontRight = const Offset(195, 224);
    final kbBackRight = const Offset(215, 204);
    final kbBackLeft = const Offset(62, 228);

    // Keyboard Base Drop Edge (Front face depth)
    final kbFrontFace = Path()
      ..moveTo(kbFrontLeft.dx, kbFrontLeft.dy)
      ..lineTo(kbFrontRight.dx, kbFrontRight.dy)
      ..lineTo(kbFrontRight.dx, kbFrontRight.dy + 10)
      ..lineTo(kbFrontLeft.dx, kbFrontLeft.dy + 10)
      ..close();
    canvas.drawPath(kbFrontFace, Paint()..color = const Color(0xFFC7C0B2));
    canvas.drawPath(kbFrontFace, linePaint);

    // Keyboard Right Depth Face
    final kbRightFace = Path()
      ..moveTo(kbFrontRight.dx, kbFrontRight.dy)
      ..lineTo(kbBackRight.dx, kbBackRight.dy)
      ..lineTo(kbBackRight.dx, kbBackRight.dy + 10)
      ..lineTo(kbFrontRight.dx, kbFrontRight.dy + 10)
      ..close();
    canvas.drawPath(kbRightFace, Paint()..color = const Color(0xFFB5ADA0));
    canvas.drawPath(kbRightFace, linePaint);

    // Keyboard Deck Top Face
    final kbTopFace = Path()
      ..moveTo(kbFrontLeft.dx, kbFrontLeft.dy)
      ..lineTo(kbFrontRight.dx, kbFrontRight.dy)
      ..lineTo(kbBackRight.dx, kbBackRight.dy)
      ..lineTo(kbBackLeft.dx, kbBackLeft.dy)
      ..close();
    canvas.drawPath(kbTopFace, Paint()..color = const Color(0xFFE0DBD2));
    canvas.drawPath(kbTopFace, linePaint);

    // ----------------------------------------------------
    // 5. INDIVIDUAL MECHANICAL KEYCAPS
    // ----------------------------------------------------
    // Row 1 (Top keys)
    _drawKeyRow(
      canvas: canvas,
      start: const Offset(70, 230),
      count: 7,
      dx: 18,
      dy: -2.8,
      keyWidth: 14,
      keyHeight: 7,
      rowOffset: 0,
      pressedIndex: pressedKeyIndex,
    );

    // Row 2 (Home keys)
    _drawKeyRow(
      canvas: canvas,
      start: const Offset(64, 239),
      count: 7,
      dx: 18,
      dy: -2.8,
      keyWidth: 14,
      keyHeight: 7,
      rowOffset: 10,
      pressedIndex: pressedKeyIndex,
    );

    // Row 3: Modifiers + Long Spacebar
    // Left Ctrl Key
    _drawSingleKey(
      canvas: canvas,
      origin: const Offset(58, 248),
      width: 18,
      height: 7,
      isPressed: pressedKeyIndex == 0,
    );
    // Big Spacebar
    _drawSingleKey(
      canvas: canvas,
      origin: const Offset(82, 244),
      width: 78,
      height: 7,
      isPressed: pressedKeyIndex == 1,
      isAccent: true,
    );
    // Right Return Key
    _drawSingleKey(
      canvas: canvas,
      origin: const Offset(166, 231),
      width: 22,
      height: 7,
      isPressed: pressedKeyIndex == 2,
    );
  }

  void _drawKeyRow({
    required Canvas canvas,
    required Offset start,
    required int count,
    required double dx,
    required double dy,
    required double keyWidth,
    required double keyHeight,
    required int rowOffset,
    int? pressedIndex,
  }) {
    for (int i = 0; i < count; i++) {
      final pos = Offset(start.dx + (i * dx), start.dy + (i * dy));
      _drawSingleKey(
        canvas: canvas,
        origin: pos,
        width: keyWidth,
        height: keyHeight,
        isPressed: pressedIndex != null && (rowOffset + i) % 3 == pressedIndex,
      );
    }
  }

  void _drawSingleKey({
    required Canvas canvas,
    required Offset origin,
    required double width,
    required double height,
    bool isPressed = false,
    bool isAccent = false,
  }) {
    final yShift = isPressed ? 1.8 : 0.0;
    final p = Offset(origin.dx, origin.dy + yShift);

    // Keycap 3D Isometric Profile
    final keyTop = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(p.dx + width, p.dy - (width * 0.15))
      ..lineTo(p.dx + width + 4, p.dy - (width * 0.15) - height)
      ..lineTo(p.dx + 4, p.dy - height)
      ..close();

    final keyFront = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(p.dx + width, p.dy - (width * 0.15))
      ..lineTo(p.dx + width, p.dy - (width * 0.15) + 3)
      ..lineTo(p.dx, p.dy + 3)
      ..close();

    final capColor = isAccent
        ? const Color(0xFFC0A85C) // Warm gold spacebar
        : (isPressed ? const Color(0xFF1E1D1B) : const Color(0xFF33312E));

    final frontColor = isAccent
        ? const Color(0xFFA6904B)
        : (isPressed ? const Color(0xFF121211) : const Color(0xFF22211F));

    // Draw keycap front bevel
    canvas.drawPath(keyFront, Paint()..color = frontColor);

    // Draw keycap top surface
    canvas.drawPath(keyTop, Paint()..color = capColor);

    // Hairline outline
    canvas.drawPath(
      keyTop,
      Paint()
        ..color = const Color(0xFF45423E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _AnatomyComputerPainter oldDelegate) {
    return oldDelegate.powerOn != powerOn ||
        oldDelegate.pressedKeyIndex != pressedKeyIndex;
  }
}
