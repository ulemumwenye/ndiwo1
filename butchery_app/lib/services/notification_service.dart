import '../models/sale.dart';
import 'dart:async'; // Required for Future
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // TODO: Request permissions for iOS/macOS if needed in a real app
    // const DarwinInitializationSettings darwinInitializationSettings = DarwinInitializationSettings(
    //   requestAlertPermission: true,
    //   requestBadgePermission: true,
    //   requestSoundPermission: true,
    // );

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(); // Default settings for iOS/macOS

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
      // macOS: darwinInitializationSettings, // Uncomment if targeting macOS specifically with permissions
    );

    await _notificationsPlugin.initialize(initializationSettings);
    print("NotificationService: Initialized.");

    // Request iOS permissions
    await _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request Android permissions (API 33+)
    // For exact alarms (e.g., for scheduled notifications) and general notifications
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showSaleNotification(Sale sale) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'sale_channel_id',
      'Sale Notifications',
      channelDescription: 'Notifications about new sales',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true, // Show timestamp
    );
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      // macOS: darwinNotificationDetails, // Use if specific macOS settings are needed
    );

    await _notificationsPlugin.show(
      0, // Notification ID
      'New Sale Recorded!',
      'Sale ID: ${sale.id}\nTotal Amount: ${sale.totalAmount.toStringAsFixed(2)}',
      notificationDetails,
      // payload: 'sale_id_${sale.id}', // Optional: to handle tap events
    );
    print("Notification: New sale recorded - ID: ${sale.id}, Amount: ${sale.totalAmount}");
  }
}
