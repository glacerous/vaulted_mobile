import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

class SteamAuthResult {
  final String steamId;
  final String? personaName;
  final String? avatarUrl;
  final Map<String, dynamic>? cs2Data;
  final Map<String, dynamic>? steamData;

  const SteamAuthResult({
    required this.steamId,
    this.personaName,
    this.avatarUrl,
    this.cs2Data,
    this.steamData,
  });
}

class SteamAuthSheet extends StatefulWidget {
  const SteamAuthSheet({super.key});

  static Future<SteamAuthResult?> show(BuildContext context) {
    return showModalBottomSheet<SteamAuthResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => const SteamAuthSheet(),
    );
  }

  @override
  State<SteamAuthSheet> createState() => _SteamAuthSheetState();
}

class _SteamAuthSheetState extends State<SteamAuthSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isExtracting = false;
  String _statusText = 'Connecting to Steam...';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _statusText = 'Loading Steam Community...';
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkAuthentication();
          },
          onWebResourceError: (error) {
            debugPrint('Steam WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://steamcommunity.com/login/home/'));
  }

  Future<void> _checkAuthentication() async {
    if (_isExtracting) return;

    try {
      final jsCheck = '''
        (function() {
          if (window.g_steamID && window.g_steamID !== "0" && window.g_steamID !== false) {
            return String(window.g_steamID);
          }
          const m = (document.cookie || '').match(/steamLoginSecure=([0-9]{17})/);
          if (m && m[1]) return m[1];
          return null;
        })()
      ''';

      final rawResult = await _controller.runJavaScriptReturningResult(jsCheck);
      final steamIdCandidate = rawResult.toString().replaceAll('"', '').trim();

      if (RegExp(r'^7656119\d{10}$').hasMatch(steamIdCandidate)) {
        if (!mounted) return;
        setState(() {
          _isExtracting = true;
          _statusText = 'Authenticated. Syncing real inventory from Valve...';
        });

        HapticFeedback.mediumImpact();

        final extractJs = '''
          (async function() {
            try {
              const steamId = "$steamIdCandidate";

              // 1. Fetch CS2 items dynamically with authenticated session
              let cs2 = null;
              try {
                const r1 = await fetch("https://steamcommunity.com/inventory/" + steamId + "/730/2?l=english&count=100");
                cs2 = await r1.json();
              } catch(e1) {
                cs2 = { error: e1.toString() };
              }

              // 2. Fetch Steam community items (cards, avatars) dynamically
              let steam = null;
              try {
                const r2 = await fetch("https://steamcommunity.com/inventory/" + steamId + "/753/6?l=english&count=100");
                steam = await r2.json();
              } catch(e2) {
                steam = { error: e2.toString() };
              }

              return JSON.stringify({
                success: true,
                steamId: steamId,
                cs2: cs2,
                steam: steam
              });
            } catch(err) {
              return JSON.stringify({ success: false, error: err.toString() });
            }
          })()
        ''';

        final payloadRaw = await _controller.runJavaScriptReturningResult(extractJs);
        String payloadClean = payloadRaw.toString();
        if (payloadClean.startsWith('"') && payloadClean.endsWith('"')) {
          payloadClean = jsonDecode(payloadClean);
        }

        final parsed = jsonDecode(payloadClean) as Map<String, dynamic>;
        if (parsed['success'] == true) {
          final res = SteamAuthResult(
            steamId: steamIdCandidate,
            cs2Data: parsed['cs2'] as Map<String, dynamic>?,
            steamData: parsed['steam'] as Map<String, dynamic>?,
          );

          if (mounted) {
            Navigator.of(context).pop(res);
          }
        } else {
          if (mounted) {
            setState(() {
              _isExtracting = false;
              _statusText = 'Session check completed.';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      if (mounted) {
        setState(() => _isExtracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.88;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: VaultColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: VaultColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEAM AUTHENTICATION',
                        style: VaultTypography.mono(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: VaultColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect Your Vault',
                        style: VaultTypography.sans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: VaultColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: const Icon(Icons.close, size: 16, color: VaultColors.ink2),
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator / status bar
          if (_isLoading || _isExtracting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: VaultColors.accent.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(VaultColors.accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: VaultTypography.mono(
                        fontSize: 11,
                        color: VaultColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: VaultColors.hairline),

          // WebView content
          Expanded(
            child: ClipRRect(
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}
