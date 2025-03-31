import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Додаємо змінну для відстеження стану нотифікацій
  bool _notificationsEnabled = true;

  // Константи для нотифікацій
  static const _blue = Color.fromARGB(255, 47, 128, 237);
  static final _vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

  static Future<NotificationService> getInstance() async {
    if (_instance == null) {
      _instance = NotificationService._();
      await _instance!._init();
    }
    return _instance!;
  }

  factory NotificationService() {
    if (_instance == null) {
      throw Exception('NotificationService not initialized. Call getInstance() first.');
    }
    return _instance!;
  }

  NotificationService._();

  Future<void> _init() async {
    try {
      // Завантажуємо збережений стан нотифікацій
      await _loadNotificationSettings();
      
      // Ініціалізуємо часові зони
      tz.initializeTimeZones();
      
      // Отримуємо системну часову зону
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
      
      print('Системна часова зона: $locationName');
      
      // Ініціалізуємо налаштування для Android
      const androidSettings = AndroidInitializationSettings('ic_notification');
      
      // Ініціалізуємо налаштування для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Об'єднуємо налаштування
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Ініціалізуємо плагін
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Отримано відповідь на нотифікацію: ${response.payload}');
        },
      );
      
      // Додаємо обробник для відстеження показу нотифікацій
      _notifications.getNotificationAppLaunchDetails().then((details) {
        if (details?.didNotificationLaunchApp ?? false) {
          print('Додаток запущено через нотифікацію: ${details?.notificationResponse?.payload}');
        }
      });
      
      print('Сервіс нотифікацій успішно ініціалізовано');
    } catch (e) {
      print('Помилка при ініціалізації нотифікацій: $e');
      rethrow;
    }
  }

 Future<void> showTaskNotification(
  String title,
  String body,
  DateTime scheduledDate, // припускаємо, що це вже в UTC
) async {
  try {
    print('Планування нотифікації для: $title');
    print('Запланований час (UTC): $scheduledDate');
    
    // Перевіряємо, чи увімкнуті нотифікації в налаштуваннях
    if (!_notificationsEnabled) {
      print('Нотифікацію не буде показано - нотифікації вимкнені у налаштуваннях');
      return;
    }
    
    // Перевіряємо дозволи перед плануванням
    final hasPermission = await requestNotificationPermissions();
    if (!hasPermission) {
      print('Нотифікацію не буде показано - немає дозволів');
      return;
    }
    
    // Перетворення UTC часу на локальний час з часовим поясом
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
    print('Час в локальній часовій зоні: $scheduledTZ');
    
    // Перевіряємо чи час не в минулому (порівнюємо UTC з UTC)
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTZ.isBefore(now)) {
      print('Нотифікація не буде показана - час вже минув');
      return;
    }
    
    // Решта коду як є...
      
      // Налаштовуємо деталі нотифікації
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        
        // Стилізація
        enableLights: true,
        ledColor: _blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        
        // Налаштування іконки
        icon: 'ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
        
        // Стиль нотифікації
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: '<b>$title</b>',
          htmlFormatContentTitle: true,
          summaryText: 'Task Manager',
          htmlFormatSummaryText: true,
        ),
        
        // Додаткові налаштування
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        color: _blue,
        colorized: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Плануємо нотифікацію
      await _notifications.zonedSchedule(
        scheduledDate.millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task_${scheduledDate.millisecondsSinceEpoch}',
      );
      
      print('Нотифікація успішно запланована на: ${scheduledTZ.toString()}');
      
      // Додаємо обробник для відстеження показу нотифікації
      _notifications.getNotificationAppLaunchDetails().then((details) {
        if (details?.didNotificationLaunchApp ?? false) {
          print('Нотифікація показана: $title');
          print('Час показу: ${DateTime.now()}');
        }
      });
    } catch (e) {
      print('Помилка при плануванні нотифікації: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('Нотифікація $id успішно скасована');
    } catch (e) {
      print('Помилка при скасуванні нотифікації: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Всі нотифікації успішно скасовані');
    } catch (e) {
      print('Помилка при скасуванні всіх нотифікацій: $e');
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      print('Запит дозволів на нотифікації...');
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      bool granted = true;

      if (androidImplementation != null) {
        print('Запит дозволів для Android...');
        final androidGranted = await androidImplementation.requestNotificationsPermission();
        if (androidGranted != true) {
          print('Дозвіл для Android не надано');
          granted = false;
        } else {
          print('Дозвіл для Android надано');
        }
      }

      print('Результат запиту дозволів: ${granted ? "надано" : "не надано"}');
      return granted;
    } catch (e) {
      print('Помилка при запиті дозволів на нотифікації: $e');
      return false;
    }
  }

  // Додаємо методи для керування станом нотифікацій
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    print('Нотифікації ${enabled ? "увімкнено" : "вимкнено"}');
    _saveNotificationSettings();
  }
  
  bool isNotificationsEnabled() {
    return _notificationsEnabled;
  }
  
  // Збереження стану нотифікацій
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      print('Налаштування нотифікацій збережено: ${_notificationsEnabled ? "увімкнено" : "вимкнено"}');
    } catch (e) {
      print('Помилка при збереженні налаштувань нотифікацій: $e');
    }
  }
  
  // Завантаження стану нотифікацій
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      print('Налаштування нотифікацій завантажено: ${_notificationsEnabled ? "увімкнено" : "вимкнено"}');
    } catch (e) {
      print('Помилка при завантаженні налаштувань нотифікацій: $e');
      _notificationsEnabled = true; // за замовчуванням увімкнено
    }
  }
} 