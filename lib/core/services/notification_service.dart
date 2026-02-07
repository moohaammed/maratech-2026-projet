import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../../features/coach/models/event_model.dart';
import '../../features/coach/services/event_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final EventService _eventService = EventService();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Navigator key for handling navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();

    // 2. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked: ${response.payload}");
        _handleNotificationClick(response.payload);
      },
    );

    // 3. FCM Setup
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      await _fcm.subscribeToTopic('all_events');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      _showLocalNotification(message);
    });
    
    // Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification opened app: ${message.data}");
      _handleNotificationClick(jsonEncode(message.data));
    });
  }
  
  void _handleNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    
    try {
      final data = jsonDecode(payload);
      final eventId = data['eventId'];
      
      if (eventId != null && navigatorKey.currentContext != null) {
        navigatorKey.currentState?.pushNamed(
          '/event-details',
          arguments: eventId,
        );
      }
    } catch (e) {
      debugPrint("Error handling notification click: $e");
    }
  }

  void startListeningToEvents() {
    // Garder trace des événements déjà notifiés pour éviter les doublons
    final Set<String> notifiedEvents = {};
    
    _eventService.getEventsStream().listen((events) {
      debugPrint("📅 Détection de ${events.length} événements");
      
      for (var event in events) {
        // Si c'est un nouvel événement (pas encore notifié)
        if (!notifiedEvents.contains(event.id)) {
          notifiedEvents.add(event.id);
          
          // Envoyer une notification immédiate pour les nouveaux événements
          _sendImmediateEventNotification(event);
        }
      }
      
      // Programmer les rappels 30 min avant pour tous les événements
      scheduleMultipleReminders(events);
    });
  }
  
  Future<void> _sendImmediateEventNotification(EventModel event) async {
    debugPrint("🔔 Envoi notification immédiate pour: ${event.title}");
    
    final icon = event.type == EventType.daily ? '🏃' : '⭐';
    final payload = jsonEncode({
      'eventId': event.id,
      'type': 'new_event',
    });
    
    try {
      await _localNotifications.show(
        id: event.id.hashCode + 1000, // +1000 pour différencier des rappels
        title: '$icon Nouvel événement: ${event.title}',
        body: '${_formatDate(event.date)} à ${event.time} - ${event.location}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'new_events',
            'Nouveaux événements',
            channelDescription: 'Notifications pour les nouveaux événements créés',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
        ),
        payload: payload,
      );
      debugPrint("✅ Notification immédiate envoyée pour: ${event.title}");
    } catch (e) {
      debugPrint("❌ Erreur envoi notification immédiate: $e");
    }
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 
                     'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Positional arguments for channelId and channelName
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);
    
    // Create payload with event ID if available
    final payload = jsonEncode({
      'eventId': message.data['eventId'] ?? '',
      'type': message.data['type'] ?? 'event',
    });

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: details,
      payload: payload,
    );
  }


  Future<void> scheduleMultipleReminders(List<EventModel> events) async {
    for (var event in events) {
      final eventDateTime = _combineDateAndTime(event.date, event.time);
      if (eventDateTime.isAfter(DateTime.now())) {
        await scheduleEventReminder(
          id: event.id,
          title: event.type == EventType.daily 
            ? "Entraînement : ${event.title}" 
            : "Événement : ${event.title}",
          body: "Votre session à ${event.location} commence dans 30 minutes.",
          scheduledDate: eventDateTime,
        );
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      debugPrint("Error parsing time: $timeStr");
      return date;
    }
  }

  Future<void> scheduleEventReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final reminderTime = scheduledDate.subtract(const Duration(minutes: 30));
    
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint("Reminder time is in the past, skipping: $reminderTime");
      return;
    }
    
    // Create payload with event ID
    final payload = jsonEncode({
      'eventId': id,
      'type': 'reminder',
    });

    // Named parameters for zonedSchedule
    await _localNotifications.zonedSchedule(
      id: id.hashCode,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Rappels d\'événements',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint("Scheduled reminder for $title at $reminderTime");
  }


  Future<void> cancelReminder(String id) async {
    await _localNotifications.cancel(id: id.hashCode);
  }
}
