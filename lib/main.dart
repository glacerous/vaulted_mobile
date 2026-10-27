import 'dart:ui';
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

/// Enables natural touch gestures, mouse drag scrolling, and elastic physics on all platforms
class VaultAppScrollBehavior extends MaterialScrollBehavior {
  const VaultAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class VaultedApp extends StatelessWidget {
  final bool initialLoggedIn;

  const VaultedApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAULTED',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const VaultAppScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: VaultColors.background,
        colorScheme: const ColorScheme.light(
          primary: VaultColors.accent,
          surface: VaultColors.card,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // On widescreen desktop/web, frame the app in a realistic mobile viewport (440px max width)
        // while on actual mobile devices, it spans full screen seamlessly.
        return Container(
          color: const Color(0xFF141413),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ClipRect(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
