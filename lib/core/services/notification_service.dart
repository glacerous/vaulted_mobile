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
        await _notificationsPlugin.initialize(
          settings,
          onDidReceiveNotificationResponse: (NotificationResponse details) {
            debugPrint('Notification tapped: ${details.payload}');
          },
        );

        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          // Inisialisasi channel notifikasi dengan importance max agar banner heads-up muncul
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              'vaulted_event_channel',
              'Market Radar Events',
              description: 'Reminders for upcoming market drops and events',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              'vaulted_warranty_channel',
              'Warranty Alerts',
              description: 'Alerts for expiring warranties on registered vault items',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              'vaulted_subs_channel',
              'Subscription Renewals',
              description: 'Reminders for recurring subscriptions',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
        _isInitialized = true;
      } catch (e) {
        debugPrint('NotificationService init error: $e');
      }
    } else {
      _isInitialized = true;
    }
  }

  Future<bool> requestPermission() async {
    await init();
    if (kIsWeb) return true;

    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return true;
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
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        1001,
        'VAULTED Warranty Alert: $itemName',
        'Official warranty coverage ends in $daysLeft days. Tap to find nearest authorized service center.',
        platformDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }

  // Pengingat event Market Radar
  Future<bool> showEventReminder({required String title, required String body}) async {
    await init();
    if (kIsWeb) {
      debugPrint('[Web Simulation] Event Notification: $title - $body');
      return true;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vaulted_event_channel',
      'Market Radar Events',
      channelDescription: 'Reminders for upcoming market drops and events',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        1003,
        'Event starting: $title',
        body,
        platformDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing event notification: $e');
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
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        1002,
        'Subscription Renewal Due: $serviceName',
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
