import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily local reminder to open the app and check in.
class CheckInReminder {
  CheckInReminder._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  static Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();
    if (!_ready) return;
    await _plugin.zonedSchedule(
      1001,
      '该打卡了',
      '记录今天的体重、消耗与任务，只要 30 秒',
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_daily',
          '每日打卡提醒',
          channelDescription: '每天固定时间提醒你打卡',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    await init();
    if (!_ready) return;
    await _plugin.cancel(1001);
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
