// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class HairlineVaultPlatform extends StatefulWidget {
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
  State<HairlineVaultPlatform> createState() => _HairlineVaultPlatformState();
}

class _HairlineVaultPlatformState extends State<HairlineVaultPlatform> {
  static int _viewCounter = 0;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'hairline-vault-view-${_viewCounter++}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.background = 'transparent'
        ..style.overflow = 'hidden'
        ..setAttribute('scrolling', 'no')
        ..srcdoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: transparent;
      display: flex;
      justify-content: center;
      align-items: center;

      /* Clean monochrome titanium tokens matching Vantis Vault */
      --hairline-plate: #131312;
      --hairline-edge: #8E8D8A;
      --hairline-mid: #383834;
      --hairline-lo: #4A4A45;
      --hairline-hi: #8E8D8A;

      --hl-plate: #131312;
      --hl-edge: #8E8D8A;
      --hl-mid: #383834;
      --hl-lo: #4A4A45;
      --hl-hi: #8E8D8A;
    }
    #figure {
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      cursor: grab;
      touch-action: none;
    }
    #figure:active {
      cursor: grabbing;
    }
    svg {
      width: 100% !important;
      height: 100% !important;
      max-width: 100%;
      max-height: 100%;
      display: block;
    }
    .hi, [data-hairline] .hi, svg .hi {
      stroke: var(--hairline-edge) !important;
      fill: transparent !important;
      filter: none !important;
      transition: none !important;
    }
  </style>
</head>
<body>
  <div id="figure" data-hairline-theme="dark"></div>
  <script type="module">
    import { vault } from "https://esm.sh/@lucasmarkes/hairline";

    const el = document.getElementById("figure");
    if (el) {
      vault(el, { theme: "dark" });
    }
  </script>
</body>
</html>
''';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
