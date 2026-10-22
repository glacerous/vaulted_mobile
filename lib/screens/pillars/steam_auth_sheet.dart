import 'dart:async';
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
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isExtracting = false;
  String _statusText = 'Connecting to Steam...';

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startPeriodicDetection();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicDetection() {
    // Continuously probe the active page for authenticated Steam ID session
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted && !_isExtracting) {
        _checkAuthentication();
      }
    });
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
            _checkAuthentication();
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkAuthentication();
          },
          onUrlChange: (UrlChange change) {
            _checkAuthentication();
          },
          onWebResourceError: (error) {
            debugPrint('Steam WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://steamcommunity.com/login/home/'));
  }

  Future<void> _checkAuthentication({bool manual = false}) async {
    if (_isExtracting) return;

    try {
      String? detectedId;
      String? detectedPersona;

      // 1. Direct URL inspection from WebView controller
      final currentUrl = await _controller.currentUrl();
      if (currentUrl != null) {
        final urlMatch = RegExp(r'/profiles/(7656119\d{10})').firstMatch(currentUrl);
        if (urlMatch != null) {
          detectedId = urlMatch.group(1);
        }
      }

      // 2. Comprehensive JavaScript page inspection
      if (detectedId == null) {
        const jsDetect = '''
          (async function() {
            try {
              // 1. window.g_rgProfileData (embedded by Valve on every profile page)
              if (window.g_rgProfileData && window.g_rgProfileData.steamid) {
                return JSON.stringify({
                  steamId: String(window.g_rgProfileData.steamid),
                  persona: window.g_rgProfileData.personaname || null
                });
              }

              // 2. window.g_steamID
              if (window.g_steamID && window.g_steamID !== "0" && window.g_steamID !== false) {
                return JSON.stringify({
                  steamId: String(window.g_steamID)
                });
              }

              // 3. Navigation / profile anchor links
              const profileLinks = document.querySelectorAll('a[href*="/profiles/7656119"]');
              for (const l of profileLinks) {
                const m = l.href.match(/\\/profiles\\/(7656119\\d{10})/);
                if (m && m[1]) {
                  return JSON.stringify({ steamId: m[1] });
                }
              }

              // 4. data-miniprofile on user menu or avatar
              const minis = document.querySelectorAll('[data-miniprofile]');
              for (const el of minis) {
                const v = el.getAttribute('data-miniprofile');
                if (v && /^\\d+\$/.test(v) && v !== "0") {
                  try {
                    const s64 = (BigInt(v) + 76561197960265728n).toString();
                    if (/^7656119\\d{10}\$/.test(s64)) {
                      return JSON.stringify({ steamId: s64 });
                    }
                  } catch(_) {}
                }
              }

              // 5. HTML script tags metadata regex
              const html = document.documentElement ? document.documentElement.innerHTML : '';
              const rgMatch = html.match(/g_rgProfileData\\s*=\\s*\\{[^}]*?"steamid"\\s*:\\s*"(\\d{17})"/);
              if (rgMatch && rgMatch[1]) {
                const pMatch = html.match(/g_rgProfileData\\s*=\\s*\\{[^}]*?"personaname"\\s*:\\s*"([^"]+)"/);
                return JSON.stringify({
                  steamId: rgMatch[1],
                  persona: pMatch ? pMatch[1] : null
                });
              }

              const sidMatch = html.match(/"steamid"\\s*:\\s*"(\\d{17})"/);
              if (sidMatch && sidMatch[1]) {
                return JSON.stringify({ steamId: sidMatch[1] });
              }

              const gSidMatch = html.match(/g_steamID\\s*=\\s*"?(\\d{17})"?/);
              if (gSidMatch && gSidMatch[1]) {
                return JSON.stringify({ steamId: gSidMatch[1] });
              }

              // 6. Vanity profile URL XML lookup
              const vanityMatch = window.location.href.match(/\\/id\\/([a-zA-Z0-9_\\-]+)/);
              if (vanityMatch && vanityMatch[1]) {
                try {
                  const xmlRes = await fetch('/id/' + vanityMatch[1] + '/?xml=1');
                  if (xmlRes.ok) {
                    const xmlText = await xmlRes.text();
                    const xMatch = xmlText.match(/<steamID64>(7656119\\d{10})<\\/steamID64>/);
                    const xName = xmlText.match(/<steamID><!\\[CDATA\\[(.*?)\\]\\]><\\/steamID>/);
                    if (xMatch && xMatch[1]) {
                      return JSON.stringify({
                        steamId: xMatch[1],
                        persona: xName ? xName[1] : null
                      });
                    }
                  }
                } catch (_) {}
              }

              return null;
            } catch (e) {
              return null;
            }
          })()
        ''';

        final rawResult = await _controller.runJavaScriptReturningResult(jsDetect);
        var clean = rawResult.toString().trim();
        if (clean.startsWith('"') && clean.endsWith('"')) {
          try {
            clean = jsonDecode(clean);
          } catch (_) {}
        }

        if (clean != 'null' && clean.isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(clean);
            if (decoded is Map) {
              final id = decoded['steamId']?.toString();
              if (id != null && RegExp(r'^7656119\d{10}$').hasMatch(id)) {
                detectedId = id;
                detectedPersona = decoded['persona']?.toString();
              }
            }
          } catch (_) {}
        }
      }

      if (detectedId != null && RegExp(r'^7656119\d{10}$').hasMatch(detectedId)) {
        _pollTimer?.cancel();
        _startInventoryExtraction(detectedId, detectedPersona);
      } else if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VaultColors.card,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Please complete Steam sign-in above before connecting.',
              style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
  }

  Future<void> _startInventoryExtraction(String steamId, String? persona) async {
    if (_isExtracting) return;
    if (!mounted) return;

    setState(() {
      _isExtracting = true;
      _statusText = persona != null && persona.isNotEmpty
          ? 'Authenticated as $persona. Syncing real inventory...'
          : 'Authenticated. Syncing real inventory from Valve...';
    });

    HapticFeedback.mediumImpact();

    try {
      final extractJs = '''
        (async function() {
          try {
            const steamId = "$steamId";

            // 1. Fetch CS2 items dynamically with authenticated session
            let cs2 = null;
            try {
              const r1 = await fetch("https://steamcommunity.com/inventory/" + steamId + "/730/2?l=english&count=100", {
                credentials: "include",
                headers: { "Accept": "application/json" }
              });
              if (r1.ok) {
                cs2 = await r1.json();
              } else {
                cs2 = { error: "HTTP " + r1.status };
              }
            } catch(e1) {
              cs2 = { error: e1.toString() };
            }

            // 2. Fetch Steam community items (cards, avatars) dynamically
            let steam = null;
            try {
              const r2 = await fetch("https://steamcommunity.com/inventory/" + steamId + "/753/6?l=english&count=100", {
                credentials: "include",
                headers: { "Accept": "application/json" }
              });
              if (r2.ok) {
                steam = await r2.json();
              } else {
                steam = { error: "HTTP " + r2.status };
              }
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
            return JSON.stringify({ success: true, steamId: "$steamId", error: err.toString() });
          }
        })()
      ''';

      final payloadRaw = await _controller.runJavaScriptReturningResult(extractJs);
      String payloadClean = payloadRaw.toString().trim();
      if (payloadClean.startsWith('"') && payloadClean.endsWith('"')) {
        try {
          payloadClean = jsonDecode(payloadClean);
        } catch (_) {}
      }

      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(payloadClean) as Map<String, dynamic>?;
      } catch (_) {}

      final res = SteamAuthResult(
        steamId: steamId,
        personaName: persona,
        cs2Data: parsed?['cs2'] as Map<String, dynamic>?,
        steamData: parsed?['steam'] as Map<String, dynamic>?,
      );

      if (mounted) {
        Navigator.of(context).pop(res);
      }
    } catch (e) {
      debugPrint('Sync extract notice: $e');
      if (mounted) {
        Navigator.of(context).pop(SteamAuthResult(
          steamId: steamId,
          personaName: persona,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.90;

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

          // Ergonomic Thumb-Zone Floating Confirmation Dock
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: VaultColors.card,
                border: Border(top: BorderSide(color: VaultColors.hairline)),
              ),
              child: _isExtracting
                  ? Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: VaultColors.cardHover,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VaultColors.accent.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(VaultColors.accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _statusText,
                              style: VaultTypography.mono(fontSize: 12, color: VaultColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _checkAuthentication(manual: true),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'Confirm & Connect Account',
                          style: VaultTypography.sans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VaultColors.primaryButton,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

