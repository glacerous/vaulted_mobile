import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      try {
        await _notificationsPlugin.initialize(settings);
        _isInitialized = true;
      } catch (e) {
        debugPrint('NotificationService init error: $e');
      }
    } else {
      _isInitialized = true;
    }
  }

  Future<bool> showWarrantyAlert({required String itemName, required int daysLeft}) async {
    await init();
    if (kIsWeb) {
      debugPrint('[Web Simulation] Warranty Notification: $itemName expires in $daysLeft days');
      return true;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vaulted_warranty_channel',
      'Warranty Alerts',
      channelDescription: 'Alerts for expiring warranties on registered vault items',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        1001,
        '🛡️ VAULTED Warranty Alert: $itemName',
        'Official warranty coverage ends in $daysLeft days. Tap to find nearest authorized service center.',
        platformDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }

  Future<bool> showSubscriptionDueAlert({required String serviceName, required double amount}) async {
    await init();
    if (kIsWeb) {
      debugPrint('[Web Simulation] Subscription Notification: $serviceName renewal due (\$$amount)');
      return true;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vaulted_subs_channel',
      'Subscription Renewals',
      channelDescription: 'Reminders for recurring subscriptions',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        1002,
        '💳 Subscription Renewal Due: $serviceName',
        'Auto-debit of \$$amount scheduled in 3 days. Review active seats in Vault.',
        platformDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing subscription notification: $e');
      return false;
    }
  }
}
