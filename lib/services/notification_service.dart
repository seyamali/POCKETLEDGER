import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes timezone data and notifications plugin settings for Android and iOS.
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Optional: Handle notification tap
      },
    );
  }

  /// Request permissions for iOS and Android 13+
  Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Schedules a notification reminder 1 day before the bill due date.
  /// If the due date is within 1 day but in the future, it schedules it for 5 seconds from now.
  /// If the due date is in the past, it skips scheduling.
  Future<void> scheduleBillReminder({
    required String id,
    required String title,
    required DateTime dueDate,
    required double amount,
  }) async {
    final int notificationId = id.hashCode;

    // Schedule 1 day before due date
    final scheduleDate = dueDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    tz.TZDateTime tzScheduleDate;
    if (scheduleDate.isBefore(now)) {
      if (dueDate.isBefore(now)) {
        // Due date is in the past, do not schedule
        return;
      }
      // Schedule immediately (5 seconds from now)
      tzScheduleDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    } else {
      tzScheduleDate = tz.TZDateTime.from(scheduleDate, tz.local);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bill_reminders_channel',
      'Bill Reminders',
      channelDescription: 'Notifications for upcoming bills and subscriptions',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming Bill Reminder',
      'Your subscription "$title" for BDT ${amount.toStringAsFixed(2)} is due tomorrow!',
      tzScheduleDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a scheduled bill reminder by its ID.
  Future<void> cancelBillReminder(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }

  /// Schedules a credit card payment due reminder 3 days before the due date.
  Future<void> scheduleCardDueReminder({
    required String cardId,
    required String cardNickname,
    required DateTime dueDate,
    required double minimumPayment,
  }) async {
    final int notificationId = 'card_$cardId'.hashCode;
    final scheduleDate = dueDate.subtract(const Duration(days: 3));
    final now = DateTime.now();

    tz.TZDateTime tzScheduleDate;
    if (scheduleDate.isBefore(now)) {
      if (dueDate.isBefore(now)) return; // past due, skip
      tzScheduleDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    } else {
      tzScheduleDate = tz.TZDateTime.from(scheduleDate, tz.local);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'credit_card_reminders',
      'Credit Card Reminders',
      channelDescription: 'Reminders for upcoming credit card payment due dates',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFFB800),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '💳 Credit Card Due Soon',
      '$cardNickname payment due in 3 days! Min. payment: BDT ${minimumPayment.toStringAsFixed(0)}',
      tzScheduleDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules a Savings Installment (DPS) reminder 1 day before the due date.
  Future<void> scheduleSavingsInstallmentReminder({
    required String accountId,
    required String accountName,
    required DateTime dueDate,
    required double installmentAmount,
  }) async {
    final int notificationId = 'savings_$accountId'.hashCode;
    final scheduleDate = dueDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    tz.TZDateTime tzScheduleDate;
    if (scheduleDate.isBefore(now)) {
      if (dueDate.isBefore(now)) return; // past due, skip
      tzScheduleDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    } else {
      tzScheduleDate = tz.TZDateTime.from(scheduleDate, tz.local);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'savings_reminders',
      'Savings Reminders',
      channelDescription: 'Reminders for upcoming savings installments',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF4CAF50), // Green color
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '💰 Savings Installment Due Tomorrow',
      'It is almost time to save BDT ${installmentAmount.toStringAsFixed(0)} in your $accountName vault.',
      tzScheduleDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a scheduled credit card due reminder.
  Future<void> cancelCardReminder(String cardId) async {
    await _notificationsPlugin.cancel('card_$cardId'.hashCode);
  }

  /// Schedules daily notifications starting 3 days before the loan due date until the due date.
  Future<void> scheduleLoanReminders({
    required String loanId,
    required String personName,
    required DateTime dueDate,
    required double amount,
    required bool isGiven,
  }) async {
    // We will schedule up to 4 notifications: 3 days before, 2 days before, 1 day before, and on the day.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'loan_reminders',
      'Loan Reminders',
      channelDescription: 'Reminders for upcoming loan due dates',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF4ADE80),
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();

    for (int daysBefore = 3; daysBefore >= 0; daysBefore--) {
      // Create a unique notification ID for each day
      final int notificationId = 'loan_${loanId}_$daysBefore'.hashCode;
      
      // Target time: 10:00 AM on the specific day
      final targetDate = dueDate.subtract(Duration(days: daysBefore));
      final scheduleTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 0);

      tz.TZDateTime tzScheduleDate;
      if (scheduleTime.isBefore(now)) {
        // If it's today and past 10 AM, we could skip or schedule immediately. Let's just skip past dates.
        if (daysBefore == 0 && dueDate.day == now.day && dueDate.month == now.month && dueDate.year == now.year) {
           tzScheduleDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
        } else {
           continue;
        }
      } else {
        tzScheduleDate = tz.TZDateTime.from(scheduleTime, tz.local);
      }

      String dayText = daysBefore == 0 ? 'Today' : 'in $daysBefore days';
      if (daysBefore == 1) dayText = 'Tomorrow';

      String title = isGiven ? '💰 Money Collection Due!' : '⚠️ Loan Repayment Due!';
      String body = isGiven
          ? 'Collect BDT ${amount.toStringAsFixed(0)} from $personName $dayText.'
          : 'You need to repay BDT ${amount.toStringAsFixed(0)} to $personName $dayText.';

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduleDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancels all scheduled reminders for a specific loan.
  Future<void> cancelLoanReminders(String loanId) async {
    for (int i = 0; i <= 3; i++) {
      await _notificationsPlugin.cancel('loan_${loanId}_$i'.hashCode);
    }
  }
}
