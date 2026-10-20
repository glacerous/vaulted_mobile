import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/vault_config.dart';
import '../database/database_helper.dart';

class ValtoAgentResult {
  final bool isAction; // true if it created a transaction/hardware item
  final String actionType; // 'expense', 'income', 'hardware', 'subscription', 'query'
  final String title;
  final String speechText; // Friendly AI assistant response text
  final double amount;
  final String currency; // 'IDR', 'USD'
  final String category;
  final String wallet;
  final String? serialNumber;
  final int? warrantyMonths;
  final List<String> suggestions;

  ValtoAgentResult({
    required this.isAction,
    required this.actionType,
    required this.title,
    required this.speechText,
    required this.amount,
    this.currency = 'IDR',
    required this.category,
    this.wallet = 'Cash',
    this.serialNumber,
    this.warrantyMonths,
    this.suggestions = const [],
  });
}

class ValtoAiService {
  ValtoAiService._();
  static final ValtoAiService instance = ValtoAiService._();

  /// Agentic processor: reads vault context and answers inquiries or executes structured actions
  Future<ValtoAgentResult> processInput(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return ValtoAgentResult(
        isAction: false,
        actionType: 'query',
        title: 'Empty prompt',
        speechText: 'I am Valto, your personal vault sentinel. How may I assist your portfolio today?',
        amount: 0,
        category: 'General',
        suggestions: ['"What can you do?"', '"Total vault value?"', '"Show active warranties"'],
      );
    }

    // 1. Gather live vault state for grounded context
    final items = await DatabaseHelper.instance.getItems();
    final totalItems = items.length;
    double totalValuation = 0.0;
    final List<Map<String, dynamic>> warrantyItems = [];

    for (final item in items) {
      final val = (item['current_valuation'] as num?)?.toDouble() ?? 0.0;
      totalValuation += val;
      if (item['warranty_expiry_date'] != null) {
        warrantyItems.add(item);
      }
    }

    final lower = cleanPrompt.toLowerCase();

    // 2. Fast Local Rule Evaluation for common assistant queries
    if (_isHelpQuery(lower)) {
      return ValtoAgentResult(
        isAction: false,
        actionType: 'query',
        title: 'Valto Capabilities',
        speechText: 'I am your Agentic Vault Sentinel. You can query your portfolio, check active warranties, or command me to register high-value tech and collectibles directly.\n\n'
            '• Portfolio Inquiries: "What is my total vault value?", "Show active warranties", "How many assets?".\n'
            '• Asset Commands: "Log Sony A7IV \$2500 warranty 24 mo", "Add RTX 4090 \$1600", "Steam AWP Dragon Lore \$4200".',
        amount: 0,
        category: 'Help',
        suggestions: ['"Total vault value?"', '"Show active warranties"', '"Log RTX 4090 \$1600"'],
      );
    }

    if (_isValuationQuery(lower)) {
      final idrVal = (totalValuation * 15850).toStringAsFixed(0);
      return ValtoAgentResult(
        isAction: false,
        actionType: 'query',
        title: 'Portfolio Valuation',
        speechText: 'Your vault currently holds $totalItems active assets with a total net worth of \$${totalValuation.toStringAsFixed(2)} (~Rp $idrVal).',
        amount: totalValuation,
        currency: 'USD',
        category: 'Valuation',
        suggestions: ['"Show active warranties"', '"Scan receipt"', '"Add new asset"'],
      );
    }

    if (_isWarrantyQuery(lower)) {
      if (warrantyItems.isEmpty) {
        return ValtoAgentResult(
          isAction: false,
          actionType: 'query',
          title: 'Warranty Status',
          speechText: 'You currently have no hardware items with active warranties recorded. You can add one manually or scan a purchase invoice!',
          amount: 0,
          category: 'Warranty',
          suggestions: ['"Scan receipt with OCR"', '"Add MacBook with 24 mo warranty"'],
        );
      } else {
        final sample = warrantyItems.map((i) => '${i['name']} (until ${i['warranty_expiry_date']})').join('\n• ');
        return ValtoAgentResult(
          isAction: false,
          actionType: 'query',
          title: 'Active Warranties',
          speechText: 'You have ${warrantyItems.length} protected hardware item(s):\n• $sample\n\nYou can locate official service centers in the Warranty LBS tab!',
          amount: warrantyItems.length.toDouble(),
          category: 'Warranty',
          suggestions: ['"Find nearest Apple service center"', '"Total vault value?"'],
        );
      }
    }

    // 3. Try Gemini Flash API for natural language extraction & deep query reasoning
    final apiKey = VaultConfig.geminiApiKey;
    if (apiKey.isNotEmpty && !apiKey.contains('your_gemini')) {
      final systemInstruction = '''
You are Valto, an ultra-luxury agentic assistant inside the VAULTED asset app.
Current User Context:
- Total Items in Vault: $totalItems
- Total Valuation: \$$totalValuation USD
- Active Warranty Items: ${warrantyItems.map((e) => e['name']).join(', ')}

Analyze the user's message.
Determine if they are ASKING A QUESTION (query/assistant) OR WANTING TO RECORD/LOG AN ASSET OR EXPENSE (action).

IMPORTANT RULES:
1. Title Cleaning: Strip leading command words ("masukkan", "tambahkan", "tambah", "catat", "simpan", "input", "beli", "log", "add", "insert", "record") and price connectors ("dengan harga", "seharga", "harga"). Strip the price completely from the title (e.g. "masukkan hp Xiaomi 17 dengan harga 18,999,000" -> title MUST be "Hp Xiaomi 17", never leave trailing zeros or commas like ",000" or ".000"). Do NOT remove model numbers that belong to the product (e.g. "Laptop Victus 15", "Xiaomi 17", "iPhone 15 Pro", "RTX 4090").
2. Price Parsing: Identify the actual price, NOT product model numbers. Handle Indonesian formatted prices with thousands separators like "18,999,000" or "18.999.000" -> 18999000 (NEVER treat commas in IDR prices as decimals!). Handle units like "12 juta" -> 12000000, "12jt" -> 12000000, "35k" -> 35000, "2.5 jt" -> 2500000, "\$1600" -> 1600.
3. Language: Respond in the EXACT same language as the user (e.g. Indonesian if the user writes in Indonesian). If Indonesian, use a polite luxury tone: "Berhasil mencatat aset '[Title]' senilai [Formatted Price] ke dalam Vault Anda."

Return ONLY valid JSON with no markdown formatting:
{
  "isAction": boolean (true ONLY if user is adding/buying/logging an expense or asset. false if asking questions, greeting, or chatting),
  "actionType": "expense" | "income" | "hardware" | "subscription" | "query",
  "title": "Clean item name or topic",
  "speechText": "Natural, helpful, and concise response in user's language acknowledging action or answering question.",
  "amount": number (extract amount, 0 if query),
  "currency": "IDR" | "USD",
  "category": "Tech & Gadgets" | "Gaming" | "Hardware" | "Cameras & Tech" | "Collectibles" | "Food & Beverage" | "General",
  "wallet": "Cash" | "BCA" | "GoPay" | "Steam" | "Vault Ledger",
  "serialNumber": string or null,
  "warrantyMonths": integer or null
}
''';

      for (final model in ['gemini-3.8-flash', 'gemini-flash-latest']) {
        try {
          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$systemInstruction\nUser input: "$cleanPrompt"'}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 1024,
                'responseMimeType': 'application/json',
              },
            }),
          ).timeout(const Duration(seconds: 12));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              String sanitized = text.replaceAll('```json', '').replaceAll('```', '').trim();
              final json = jsonDecode(sanitized);

              final isAct = json['isAction'] == true;
              return ValtoAgentResult(
                isAction: isAct,
                actionType: json['actionType'] as String? ?? (isAct ? 'hardware' : 'query'),
                title: json['title'] as String? ?? cleanPrompt,
                speechText: json['speechText'] as String? ?? 'Processed your request.',
                amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
                currency: json['currency'] as String? ?? (lower.contains('usd') || cleanPrompt.contains('\$') ? 'USD' : 'IDR'),
                category: json['category'] as String? ?? 'General',
                wallet: json['wallet'] as String? ?? 'Vault Ledger',
                serialNumber: json['serialNumber'] as String?,
                warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
              );
            }
          }
        } catch (e) {
          debugPrint('[ValtoAiService] Model $model error: $e');
        }
      }
    }

    // 4. Offline Fallback Logic
    return _parseOffline(cleanPrompt, totalItems, totalValuation, warrantyItems);
  }

  bool _isHelpQuery(String lower) {
    return lower.contains('what do i ask') ||
        lower.contains('what can you do') ||
        lower.contains('help') ||
        lower.contains('bantuan') ||
        lower.contains('cara pakai') ||
        lower.contains('contoh') ||
        lower.contains('menu');
  }

  bool _isValuationQuery(String lower) {
    return lower.contains('total') ||
        lower.contains('worth') ||
        lower.contains('valuation') ||
        lower.contains('berapa aset') ||
        lower.contains('saldo') ||
        lower.contains('nilai');
  }

  bool _isWarrantyQuery(String lower) {
    return lower.contains('garansi') ||
        lower.contains('warranty') ||
        lower.contains('habis') ||
        lower.contains('service center') ||
        lower.contains('servis');
  }

  static double _parsePriceString(String numStr, String? unit, String currency) {
    numStr = numStr.trim();
    if (unit != null && unit.isNotEmpty) {
      final normalized = numStr.replaceAll(',', '.');
      double val = double.tryParse(normalized) ?? 0.0;
      final u = unit.toLowerCase();
      if (u == 'k' || u == 'rb' || u == 'ribu') {
        val *= 1000;
      } else if (u == 'jt' || u == 'juta' || u == 'm') {
        val *= 1000000;
      } else if (u == 'miliar' || u == 'b') {
        val *= 1000000000;
      }
      return val;
    }

    if (currency == 'IDR') {
      // Indonesian Rupiah: all commas and periods in price digits are thousands separators
      // e.g. "18,999,000" -> 18999000, "18.999.000" -> 18999000, "50.000" -> 50000
      final digitsOnly = numStr.replaceAll(RegExp(r'[^0-9]'), '');
      return double.tryParse(digitsOnly) ?? 0.0;
    } else {
      // USD / Foreign currency
      if (numStr.contains(',') && numStr.contains('.')) {
        if (numStr.lastIndexOf('.') > numStr.lastIndexOf(',')) {
          numStr = numStr.replaceAll(',', '');
        } else {
          numStr = numStr.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (numStr.contains(',')) {
        final parts = numStr.split(',');
        if (parts.last.length == 3) {
          numStr = numStr.replaceAll(',', '');
        } else {
          numStr = numStr.replaceAll(',', '.');
        }
      } else if (numStr.contains('.')) {
        final parts = numStr.split('.');
        if (parts.last.length == 3) {
          numStr = numStr.replaceAll('.', '');
        }
      }
      return double.tryParse(numStr) ?? 0.0;
    }
  }

  ValtoAgentResult _parseOffline(
    String text,
    int totalItems,
    double totalValuation,
    List<Map<String, dynamic>> warrantyItems,
  ) {
    final lower = text.toLowerCase();
    final isIndo = RegExp(
      r'\b(masukkan|tambah|tambahkan|catat|simpan|beli|harga|juta|jt|ribu|rb|cari|tau|garansi|berapa|saldo|nilai|apa|ap|koleksi|servis|ini|itu|dong|bisa|kah|ya|sih|tolong)\b',
    ).hasMatch(lower);

    // 1. Extract Price & Currency (Prevent confusing model numbers like "Victus 15" or "Xiaomi 17" with price)
    double amount = 0.0;
    String currency = (lower.contains('usd') || lower.contains('\$')) ? 'USD' : 'IDR';
    String matchedPriceSubstring = '';

    // Robust pattern for numbers with thousands separators or decimals:
    // Matches e.g. 18,999,000 | 18.999.000 | 1,600 | 18.5 | 18,5 | 18999000 | 500
    const numPattern = r'(?:\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?|\d+(?:[.,]\d+)?)';

    // Priority A: USD patterns like "$1600", "$ 1,600", "1600 usd"
    final usdMatch = RegExp(
      r'(?:\$|usd\s*)\s*(' + numPattern + r')|\b(' + numPattern + r')\s*usd\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (usdMatch != null) {
      matchedPriceSubstring = usdMatch.group(0)!;
      final rawNum = (usdMatch.group(1) ?? usdMatch.group(2))!;
      amount = _parsePriceString(rawNum, null, 'USD');
      currency = 'USD';
    } else {
      // Priority B: Explicit price connectors like "dengan harga 18,999,000", "harga: 12 jt", "seharga 35k", "rp 18.999.000"
      final explicitPriceMatch = RegExp(
        r'(?:dengan\s+harga|seharga|harga|price|cost|for|rp\.?|idr)\s*[:=]?\s*(' + numPattern + r')\s*(k|rb|ribu|jt|juta|miliar|m|b)?\b',
        caseSensitive: false,
      ).firstMatch(lower);

      if (explicitPriceMatch != null) {
        matchedPriceSubstring = explicitPriceMatch.group(0)!;
        final rawNum = explicitPriceMatch.group(1)!;
        final unit = explicitPriceMatch.group(2)?.toLowerCase();
        amount = _parsePriceString(rawNum, unit, currency);
      } else {
        // Priority C: Standalone number with currency units like "12 juta", "12jt", "35k", "35rb", "18.5 jt"
        final unitMatch = RegExp(
          r'\b(' + numPattern + r')\s*(k|rb|ribu|jt|juta|miliar)\b',
          caseSensitive: false,
        ).firstMatch(lower);

        if (unitMatch != null) {
          matchedPriceSubstring = unitMatch.group(0)!;
          final rawNum = unitMatch.group(1)!;
          final unit = unitMatch.group(2)!.toLowerCase();
          amount = _parsePriceString(rawNum, unit, currency);
        } else {
          // Priority D: Standalone number formatted with thousands separators (e.g. "masukkan hp xiaomi 17 18,999,000")
          final thousandsMatch = RegExp(
            r'\b(\d{1,3}(?:[.,]\d{3})+)\b',
            caseSensitive: false,
          ).firstMatch(lower);

          if (thousandsMatch != null) {
            matchedPriceSubstring = thousandsMatch.group(0)!;
            amount = _parsePriceString(thousandsMatch.group(1)!, null, currency);
          }
        }
      }
    }

    // 2. Extract Warranty if specified
    int? warrantyMonths;
    String matchedWarrantySubstring = '';
    final warrantyMatch = RegExp(
      r'(?:garansi|warranty)\s*[:=]?\s*(\d+)\s*(bln|bulan|thn|tahun|mo|months|yr|years)?\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (warrantyMatch != null) {
      matchedWarrantySubstring = warrantyMatch.group(0)!;
      int val = int.tryParse(warrantyMatch.group(1)!) ?? 12;
      final unit = warrantyMatch.group(2)?.toLowerCase();
      if (unit == 'thn' || unit == 'tahun' || unit == 'yr' || unit == 'years') {
        val *= 12;
      }
      warrantyMonths = val;
    }

    // 3. Extract Serial Number if specified
    String? serialNumber;
    String matchedSnSubstring = '';
    final snMatch = RegExp(
      r'(?:sn|serial|s\/n)\s*[:=]?\s*([a-zA-Z0-9\-]+)\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (snMatch != null) {
      matchedSnSubstring = snMatch.group(0)!;
      serialNumber = snMatch.group(1)!.toUpperCase();
    }

    // 4. Clean Title without destroying product model numbers
    String cleanTitle = text;
    if (matchedPriceSubstring.isNotEmpty) {
      cleanTitle = cleanTitle.replaceAll(RegExp(RegExp.escape(matchedPriceSubstring), caseSensitive: false), '');
    }
    if (matchedWarrantySubstring.isNotEmpty) {
      cleanTitle = cleanTitle.replaceAll(RegExp(RegExp.escape(matchedWarrantySubstring), caseSensitive: false), '');
    }
    if (matchedSnSubstring.isNotEmpty) {
      cleanTitle = cleanTitle.replaceAll(RegExp(RegExp.escape(matchedSnSubstring), caseSensitive: false), '');
    }

    // Strip trailing connectors left behind like "dengan harga", "dengan", "seharga", "harga"
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\b(dengan\s+harga|dengan|seharga|harga|price|cost|for|at)\b', caseSensitive: false), '');

    // Strip leading command action verbs
    cleanTitle = cleanTitle.replaceAll(
      RegExp(r'^(masukkan|tambahkan|tambah|catat|simpan|input|beli|log|add|insert|record|buy)\s+', caseSensitive: false),
      '',
    );

    // Clean whitespace and boundary punctuation (including trailing/leading commas and periods)
    cleanTitle = cleanTitle.replaceAll(RegExp(r'^[:\s\-,\.]+|[:\s\-,\.]+$'), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // Capitalize words
    if (cleanTitle.isNotEmpty) {
      cleanTitle = cleanTitle.split(' ').map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
    }

    // Check if user is logging an asset or asking a query
    final hasActionWord = RegExp(r'\b(masukkan|tambah|tambahkan|catat|simpan|beli|input|log|add|insert|buy|record)\b').hasMatch(lower);
    final isAction = (amount > 0 && cleanTitle.isNotEmpty) || (hasActionWord && cleanTitle.isNotEmpty);

    // Infer Category
    String category = 'Tech & Gadgets';
    if (lower.contains('steam') || lower.contains('skin') || lower.contains('knife') || lower.contains('cs2') || lower.contains('valorant') || lower.contains('vp') || lower.contains('dota')) {
      category = 'Gaming';
    } else if (lower.contains('camera') || lower.contains('leica') || lower.contains('sony') || lower.contains('lens') || lower.contains('fujifilm')) {
      category = 'Cameras & Tech';
    } else if (lower.contains('watch') || lower.contains('rolex') || lower.contains('omega') || lower.contains('cartier')) {
      category = 'Collectibles';
    } else if (lower.contains('kopi') || lower.contains('makan') || lower.contains('cafe')) {
      category = 'Food & Beverage';
    } else if (lower.contains('laptop') || lower.contains('macbook') || lower.contains('gpu') || lower.contains('rtx') || lower.contains('pc') || lower.contains('monitor') || lower.contains('victus')) {
      category = 'Hardware';
    }

    String speechText;
    if (isAction) {
      String formattedAmount;
      if (currency == 'USD') {
        formattedAmount = '\$${NumberFormat('#,###').format(amount.toInt())}';
      } else {
        if (amount >= 1000000 && amount % 1000000 == 0) {
          final jt = (amount / 1000000).toInt();
          formattedAmount = 'Rp $jt Juta';
        } else if (amount >= 1000000 && amount % 100000 == 0) {
          final jt = (amount / 1000000).toStringAsFixed(1);
          formattedAmount = 'Rp $jt Juta';
        } else {
          final formatted = NumberFormat('#,###').format(amount.toInt());
          formattedAmount = 'Rp $formatted';
        }
      }

      if (isIndo) {
        speechText = 'Berhasil mencatat aset "$cleanTitle" senilai $formattedAmount ke dalam Vault Anda.';
        if (warrantyMonths != null) {
          speechText += ' Garansi aktif $warrantyMonths bulan.';
        }
      } else {
        speechText = 'Logged asset "$cleanTitle" valued at $formattedAmount into your vault.';
        if (warrantyMonths != null) {
          speechText += ' Active warranty: $warrantyMonths months.';
        }
      }
    } else {
      if (lower.contains('harga') || lower.contains('pasar') || lower.contains('market')) {
        speechText = isIndo
            ? 'Untuk riset harga pasar atau valuasi, sebutkan nama aset yang ingin Anda cek dari $totalItems item di Vault Anda (contoh: "harga pasar HP Victus 15" atau "harga RTX 4090").'
            : 'For market price valuation, specify which asset from your $totalItems vault items you would like to inspect (e.g. "Victus 15 market price" or "RTX 4090 value").';
      } else if (lower.contains('valorant')) {
        speechText = isIndo
            ? 'Untuk mencatat pembelian Valorant Points (VP) atau skin senjata Valorant, Anda bisa ketik seperti: "Beli Valorant Points 150k" atau "Log Skin Vandal 250k".'
            : 'To record Valorant items or points, you can type: "Buy Valorant Points \$20" or "Log Vandal Skin 250k".';
      } else {
        speechText = isIndo
            ? 'Saya siap membantu memantau aset Vault Anda. Anda bisa mengecek total saldo, garansi aktif, atau mencatat aset baru seperti "Laptop Victus 15 harga 12 juta".'
            : 'I am ready to assist with your portfolio. You can query your total net worth, active warranties, or log new assets like "Laptop Victus 15 \$800".';
      }
    }

    return ValtoAgentResult(
      isAction: isAction,
      actionType: 'hardware',
      title: cleanTitle.isEmpty ? (isIndo ? 'Aset Baru' : 'New Asset') : cleanTitle,
      speechText: speechText,
      amount: amount,
      currency: currency,
      category: category,
      wallet: 'Vault Ledger',
      serialNumber: serialNumber,
      warrantyMonths: warrantyMonths ?? (lower.contains('garansi') || lower.contains('warranty') ? 24 : 12),
      suggestions: isIndo
          ? ['"Cari tau harga pasar"', '"Berapa total aset?"', '"Cek garansi aktif"']
          : ['"What can you do?"', '"Total vault value?"', '"Show active warranties"'],
    );
  }
}
