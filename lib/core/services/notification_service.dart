import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules on-device "horse due for a trim" reminders. Inexact scheduling, so
/// it needs no exact-alarm permission on Android.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'trim_reminders',
    'Trim reminders',
    description: 'Reminders when a horse is due for a trim or shoe',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    // Some devices report a timezone id that isn't in the tz database; fall
    // back to UTC so startup can't be blocked.
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _ready = true;
  }

  /// Prompts for notification permission; true if granted (or already).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// Cancel and re-schedule a reminder for every horse with a future due date.
  Future<void> syncDueReminders(
    List<({Client client, Horse horse})> due, {
    required bool enabled,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    if (!enabled) return;
    for (final d in due) {
      final dueDate = d.horse.nextDueDate;
      if (dueDate == null) continue;
      final at = tz.TZDateTime(
        tz.local,
        dueDate.year,
        dueDate.month,
        dueDate.day,
        7,
      );
      if (at.isBefore(tz.TZDateTime.now(tz.local))) continue; // already overdue
      await _plugin.zonedSchedule(
        id: d.horse.id.hashCode & 0x7fffffff,
        title: 'Trim due',
        body: '${d.horse.name} (${d.client.name}) is due for a trim.',
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'trim_reminders',
            'Trim reminders',
            channelDescription:
                'Reminders when a horse is due for a trim or shoe',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
