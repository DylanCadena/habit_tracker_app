import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _noonId = 1200;
  static const _eveningId = 2000;
  static const _channelId = 'habit_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    var granted = true;
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    granted = androidGranted != false &&
        iosGranted != false &&
        macosGranted != false;
    return granted;
  }

  Future<void> syncForPendingHabits(int pendingCount) async {
    await initialize();
    await _plugin.cancel(id: _noonId);
    await _plugin.cancel(id: _eveningId);

    if (pendingCount == 0) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _isSpanish ? 'Recordatorios de hábitos' : 'Habit reminders',
        channelDescription: _isSpanish
            ? 'Avisos de hábitos pendientes'
            : 'Reminders for pending habits',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _scheduleDaily(
      id: _noonId,
      hour: 12,
      minute: 0,
      details: details,
      pendingCount: pendingCount,
    );
    await _scheduleDaily(
      id: _eveningId,
      hour: 20,
      minute: 0,
      details: details,
      pendingCount: pendingCount,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required NotificationDetails details,
    required int pendingCount,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: scheduled,
      notificationDetails: details,
      title: _isSpanish ? 'Hábitos pendientes' : 'Pending habits',
      body: pendingCount == 1
          ? (_isSpanish
                ? 'Aún tienes 1 hábito por completar.'
                : 'You still have 1 habit to complete.')
          : (_isSpanish
                ? 'Aún tienes $pendingCount hábitos por completar.'
                : 'You still have $pendingCount habits to complete.'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'open_habits',
    );
  }

  bool get _isSpanish =>
      PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'es';
}
