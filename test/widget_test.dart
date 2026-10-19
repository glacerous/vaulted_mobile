// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/core/constants/vault_config.dart';
import 'package:vaulted/core/database/database_helper.dart';
import 'package:vaulted/core/services/gemini_service.dart';
import 'package:vaulted/core/services/valto_ai_service.dart';
import 'package:vaulted/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VaultedApp(initialLoggedIn: false));
    // Verify VaultedApp runs
    expect(find.byType(VaultedApp), findsOneWidget);
  });

  test('VaultConfig has non-empty keys by default', () {
    expect(VaultConfig.steamApiKey.isNotEmpty, isTrue);
    expect(VaultConfig.geminiApiKey.isNotEmpty, isTrue);
    expect(VaultConfig.hasGeminiKey, isTrue);
    expect(VaultConfig.hasSteamKey, isTrue);
  });

  test('DatabaseHelper authenticates demo user safely', () async {
    final user = await DatabaseHelper.instance.authenticateUser('azzaky', 'admin123');
    expect(user, isNotNull);
    expect(user?['username'], 'azzaky');

    final upperCaseUser = await DatabaseHelper.instance.authenticateUser(' AZZAKY ', 'admin123');
    expect(upperCaseUser, isNotNull);
  });

  test('GeminiService invoice parser handles input gracefully', () async {
    final result = await GeminiService.instance.parseInvoiceText('MacBook Pro M3 Max, \$1999');
    expect(result.itemName.isNotEmpty, isTrue);
    expect(result.purchasePrice, greaterThan(0));
  });

  test('ValtoAiService processes portfolio queries', () async {
    final result = await ValtoAiService.instance.processInput('What is my total vault value?');
    expect(result.actionType, 'query');
    expect(result.speechText.isNotEmpty, isTrue);
  });
}
