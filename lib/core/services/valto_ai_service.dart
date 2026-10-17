import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
        speechText: 'I am your Agentic Vault Sentinel. You can ask me questions about your portfolio, or command me to log items and expenses directly.\n\n'
            '• Inquiries: "How much is my vault worth?", "Do I have active warranties?", "Show my hardware".\n'
            '• Auto-Log: "Kopi 25k BCA", "Beli monitor Asus 2.5jt garansi 24 bln", "Steam game 150rb".',
        amount: 0,
        category: 'Help',
        suggestions: ['"Total vault value?"', '"Do I have active warranties?"', '"Kopi 25k BCA"'],
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

    // 3. Try Gemini 2.5 Flash API for natural language extraction & deep query reasoning
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty && !apiKey.contains('your_gemini')) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        );

        final systemInstruction = '''
You are Valto, an ultra-luxury agentic assistant inside the VAULTED asset app.
Current User Context:
- Total Items in Vault: $totalItems
- Total Valuation: \$$totalValuation USD
- Active Warranty Items: ${warrantyItems.map((e) => e['name']).join(', ')}

Analyze the user's message.
Determine if they are ASKING A QUESTION (query/assistant) OR WANTING TO RECORD/LOG AN ASSET OR EXPENSE (action).
Return ONLY valid JSON with no markdown formatting:
{
  "isAction": boolean (true ONLY if user is adding/buying/logging an expense or asset. false if asking questions, greeting, or chatting),
  "actionType": "expense" | "income" | "hardware" | "subscription" | "query",
  "title": "Concise title or question topic",
  "speechText": "Natural, helpful, and concise response to user. If isAction is true, acknowledge what was recorded.",
  "amount": number (extract amount, 0 if query. Handle 25k -> 25000, 2jt -> 2000000, or USD numbers),
  "currency": "IDR" | "USD",
  "category": "Food & Beverage" | "Gaming" | "Hardware" | "Entertainment" | "Living" | "General",
  "wallet": "Cash" | "BCA" | "GoPay" | "Steam",
  "serialNumber": string or null,
  "warrantyMonths": integer or null
}
''';

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
            'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 300},
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null) {
            final sanitized = text.replaceAll('```json', '').replaceAll('```', '').trim();
            final json = jsonDecode(sanitized);

            final isAct = json['isAction'] == true;
            return ValtoAgentResult(
              isAction: isAct,
              actionType: json['actionType'] as String? ?? (isAct ? 'expense' : 'query'),
              title: json['title'] as String? ?? cleanPrompt,
              speechText: json['speechText'] as String? ?? 'Processed your request.',
              amount: (json['amount'] as num?)?.toDouble() ?? (isAct ? _fallbackAmount(cleanPrompt) : 0),
              currency: json['currency'] as String? ?? (lower.contains('usd') || cleanPrompt.contains('\$') ? 'USD' : 'IDR'),
              category: json['category'] as String? ?? 'General',
              wallet: json['wallet'] as String? ?? 'Cash',
              serialNumber: json['serialNumber'] as String?,
              warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
            );
          }
        }
      } catch (e) {
        debugPrint('Valto Gemini processor fallback: $e');
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

  ValtoAgentResult _parseOffline(
    String text,
    int totalItems,
    double totalValuation,
    List<Map<String, dynamic>> warrantyItems,
  ) {
    final lower = text.toLowerCase();
    final double amount = _fallbackAmount(text);

    // If there is no numeric amount and it looks like general speech/query
    if (amount <= 0 && !_hasActionKeyword(lower)) {
      return ValtoAgentResult(
        isAction: false,
        actionType: 'query',
        title: 'Valto Sentinel',
        speechText: 'I received: "$text". You can ask about your total assets, check active warranties, or log purchases like "Kopi 25k BCA" or "MacBook 2000 usd".',
        amount: 0,
        category: 'General',
        suggestions: ['"What can you do?"', '"Total vault value?"', '"Show active warranties"'],
      );
    }

    // It is an action (Expense or Hardware)
    String type = 'expense';
    String category = 'General';
    String wallet = 'Cash';

    if (lower.contains('gaji') || lower.contains('income') || lower.contains('bonus')) {
      type = 'income';
      category = 'Salary';
    } else if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('makan') || lower.contains('nasi')) {
      category = 'Food & Beverage';
    } else if (lower.contains('steam') || lower.contains('game') || lower.contains('skin')) {
      category = 'Gaming';
      wallet = 'Steam';
    } else if (lower.contains('laptop') || lower.contains('macbook') || lower.contains('phone') || lower.contains('monitor') || lower.contains('beli')) {
      type = 'hardware';
      category = 'Hardware';
    }

    if (lower.contains('bca')) wallet = 'BCA';
    if (lower.contains('gopay')) wallet = 'GoPay';

    final cleanTitle = text.split(RegExp(r'\d+')).first.trim().isEmpty ? text : text.split(RegExp(r'\d+')).first.trim();

    return ValtoAgentResult(
      isAction: true,
      actionType: type,
      title: cleanTitle,
      speechText: 'Recorded $cleanTitle for ${amount > 0 ? (lower.contains('usd') || lower.contains('\$') ? '\$$amount' : 'Rp ${amount.toStringAsFixed(0)}') : 'item'} to your vault ledger.',
      amount: amount,
      currency: lower.contains('usd') || lower.contains('\$') ? 'USD' : 'IDR',
      category: category,
      wallet: wallet,
      warrantyMonths: lower.contains('garansi') || lower.contains('warranty') ? 12 : null,
    );
  }

  bool _hasActionKeyword(String lower) {
    return lower.contains('beli') ||
        lower.contains('buy') ||
        lower.contains('kopi') ||
        lower.contains('makan') ||
        lower.contains('bayar') ||
        lower.contains('gaji') ||
        lower.contains('sn:');
  }

  double _fallbackAmount(String text) {
    final lower = text.toLowerCase();
    final match = RegExp(r'(\d+[\.,]?\d*)\s*(k|rb|ribu|jt|juta)?').firstMatch(lower);
    if (match != null) {
      double numVal = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
      final unit = match.group(2);
      if (unit == 'k' || unit == 'rb' || unit == 'ribu') {
        numVal *= 1000;
      } else if (unit == 'jt' || unit == 'juta') {
        numVal *= 1000000;
      }
      return numVal;
    }
    return 0.0;
  }
}
