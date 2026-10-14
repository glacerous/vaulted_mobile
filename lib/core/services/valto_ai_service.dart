import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ValtoParsedAction {
  final String type; // 'expense', 'income', 'hardware', 'subscription', 'query'
  final String title;
  final double amount;
  final String currency; // 'IDR', 'USD'
  final String category;
  final String wallet; // 'Cash', 'BCA', 'GoPay', 'Steam'
  final String? serialNumber;
  final int? warrantyMonths;
  final String rawResponse;

  ValtoParsedAction({
    required this.type,
    required this.title,
    required this.amount,
    this.currency = 'IDR',
    required this.category,
    this.wallet = 'Cash',
    this.serialNumber,
    this.warrantyMonths,
    required this.rawResponse,
  });
}

typedef VowlParsedAction = ValtoParsedAction;
typedef VowlAiService = ValtoAiService;

class ValtoAiService {
  ValtoAiService._();
  static final ValtoAiService instance = ValtoAiService._();

  /// Parses natural language input like "kopi 25k bca" or "macbook 2000 usd garansi 24 bln"
  Future<ValtoParsedAction> parseNaturalInput(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return ValtoParsedAction(
        type: 'query',
        title: 'Empty prompt',
        amount: 0,
        category: 'General',
        rawResponse: 'Please type something',
      );
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty && !apiKey.contains('your_gemini')) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
        );

        final systemInstruction = '''
You are Valto, an ultra-smart financial and asset vault assistant.
Analyze this user text (in Indonesian or English) and extract structured financial or asset intent.
Return ONLY valid JSON with no markdown wrapping:
{
  "type": "expense" | "income" | "hardware" | "subscription" | "query",
  "title": "Clear concise item/description name",
  "amount": number (convert Indonesian "k" to thousands, e.g. 25k -> 25000, "jt" to millions, e.g. 2jt -> 2000000. If USD mentioned, keep numeric dollars),
  "currency": "IDR" | "USD",
  "category": "Food & Beverage" | "Gaming" | "Hardware" | "Entertainment" | "Living" | "General",
  "wallet": "Cash" | "BCA" | "GoPay" | "Steam",
  "serialNumber": string or null,
  "warrantyMonths": integer number of months or null
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
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256},
          }),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

          if (text != null) {
            String sanitized = text.replaceAll('```json', '').replaceAll('```', '').trim();
            final json = jsonDecode(sanitized);

            return ValtoParsedAction(
              type: json['type'] as String? ?? 'expense',
              title: json['title'] as String? ?? cleanPrompt,
              amount: (json['amount'] as num?)?.toDouble() ?? _fallbackAmount(cleanPrompt),
              currency: json['currency'] as String? ?? (cleanPrompt.toLowerCase().contains('usd') || cleanPrompt.contains('\$') ? 'USD' : 'IDR'),
              category: json['category'] as String? ?? 'General',
              wallet: json['wallet'] as String? ?? 'Cash',
              serialNumber: json['serialNumber'] as String?,
              warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
              rawResponse: text,
            );
          }
        }
      } catch (e) {
        debugPrint('Valto Gemini AI natural language notice: $e');
      }
    }

    // Offline / Fallback Regex Parser for speed and offline resilience
    return _parseOffline(cleanPrompt);
  }

  ValtoParsedAction _parseOffline(String text) {
    final lower = text.toLowerCase();
    double amount = _fallbackAmount(text);
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
    } else if (lower.contains('laptop') || lower.contains('macbook') || lower.contains('hp') || lower.contains('phone')) {
      type = 'hardware';
      category = 'Hardware';
    } else if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('youtube') || lower.contains('monthly')) {
      type = 'subscription';
      category = 'Entertainment';
    }

    if (lower.contains('bca')) wallet = 'BCA';
    if (lower.contains('gopay')) wallet = 'GoPay';

    return ValtoParsedAction(
      type: type,
      title: text.split(RegExp(r'\d+')).first.trim().isEmpty ? text : text.split(RegExp(r'\d+')).first.trim(),
      amount: amount,
      currency: lower.contains('usd') || lower.contains('\$') ? 'USD' : 'IDR',
      category: category,
      wallet: wallet,
      rawResponse: 'Parsed offline with Valto Rules',
    );
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
