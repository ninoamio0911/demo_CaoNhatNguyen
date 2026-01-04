import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Khởi tạo dữ liệu múi giờ
    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      print("Lỗi set timezone: $e");
    }

    // 2. Cấu hình icon (nhớ bỏ @mipmap/ nếu dùng Android cũ)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. Xin quyền (Bắt buộc cho Android 13+)
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // Hàm lên lịch nhắc nhở (cách cũ)
  Future<void> scheduleNotification(int id, String title, DateTime scheduledTime) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Lịch: $title',
        'Đã đến giờ cho sự kiện này!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'calendar_channel_vip',
            'Lịch Ưu Tiên',
            channelDescription: 'Thông báo có chuông và rung',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Lỗi đặt lịch: $e");
    }
  }

  // Hàm test thông báo
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'calendar_channel_vip', 'Lịch Ưu Tiên',
      channelDescription: 'Test thông báo',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
        0, 'Test Thông Báo', 'Nếu anh thấy dòng này là code ngon!', details);
  }

  // --- HÀM ANH ĐANG THIẾU (QUAN TRỌNG) ---
  Future<void> showNotificationNow(int id, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'calendar_channel_vip', 'Lịch Ưu Tiên',
      channelDescription: 'Thông báo sự kiện',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
        id, 'Sắp diễn ra!', body, details);
  }
  // ----------------------------------------

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}