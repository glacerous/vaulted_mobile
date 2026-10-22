import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/colors.dart';
import 'core/constants/vault_config.dart';
import 'core/security/auth_service.dart';
import 'core/services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await VaultConfig.initialize();
  await NotificationService.instance.init();

  // Crisp dark status bar & navigation bar overlay on warm porcelain canvas
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: VaultColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
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
        brightness: Brightness.light,
        scaffoldBackgroundColor: VaultColors.background,
        colorScheme: const ColorScheme.light(
          primary: VaultColors.accent,
          surface: VaultColors.card,
        ),
        useMaterial3: true,
      ),
      home: initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
