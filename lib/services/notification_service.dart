import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications: an instant alert + a message every morning.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _reminderId = 1;
  static const _alertId = 2;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'weight_alerts',
      'Weight alerts',
      channelDescription: 'BMI alerts and weight reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (kIsWeb) return; // not supported on web
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      tzdata.initializeTimeZones();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Instant alert.
  Future<void> showNow({required String title, required String body}) async {
    if (!_ready) return;
    try {
      await _plugin.show(_alertId, title, body, _details);
    } catch (e) {
      debugPrint('showNow failed: $e');
    }
  }

  /// Fires every day at [hour]:[minute] (device local time) with this message.
  /// Calling it again replaces the previous one, so the text always matches
  /// the latest BMI.
  Future<void> scheduleMorning({
    required String title,
    required String body,
    int hour = 8,
    int minute = 0,
  }) async {
    if (!_ready) return;
    try {
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day, hour, minute);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      // Same instant, expressed in UTC (no device-timezone plugin needed).
      final when = tz.TZDateTime.from(next, tz.UTC);

      await _plugin.zonedSchedule(
        _reminderId,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (e) {
      debugPrint('scheduleMorning failed: $e');
    }
  }

  Future<void> cancelReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_reminderId);
    } catch (e) {
      debugPrint('cancelReminder failed: $e');
    }
  }
}
