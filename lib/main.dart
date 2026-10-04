import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/colors.dart';
import 'core/security/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback if .env is missing
  }

  // Dark navigation bar & status bar overlay matching Vantis Vault
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VaultColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final bool loggedIn = await AuthService.instance.isLoggedIn();

  runApp(VaultedApp(initialLoggedIn: loggedIn));
}

class VaultedApp extends StatelessWidget {
  final bool initialLoggedIn;

  const VaultedApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAULTED',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: VaultColors.background,
        colorScheme: const ColorScheme.dark(
          primary: VaultColors.accent,
          surface: VaultColors.card,
        ),
        useMaterial3: true,
      ),
      home: initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
