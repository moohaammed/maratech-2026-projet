import 'dart:convert';
import 'dart:typed_data';
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
  
  // Badge counter - compte le nombre de notifications non lues
  static int _badgeCount = 0;
  
  // Incrémenter le badge
  Future<void> _incrementBadge() async {
    _badgeCount++;
    debugPrint("📊 Badge count: $_badgeCount");
  }
  
  // Réinitialiser le badge (quand l'utilisateur ouvre les notifications)
  static Future<void> resetBadge() async {
    _badgeCount = 0;
    debugPrint("📊 Badge reset to 0");
  }

  Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();

    // 2. Créer les canaux de notification Android avec les bons paramètres
    // Ceci est CRUCIAL pour que le son et le popup fonctionnent!
    const AndroidNotificationChannel newEventsChannel = AndroidNotificationChannel(
      'new_events', // id
      'Nouveaux événements', // name
      description: 'Notifications pour les nouveaux événements créés',
      importance: Importance.max, // MAX pour popup heads-up
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
      'event_reminders', // id
      'Rappels d\'événements', // name
      description: 'Rappels 30 minutes avant les événements',
      importance: Importance.max, // MAX pour popup heads-up
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'Notifications importantes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel chatMessagesChannel = AndroidNotificationChannel(
      'chat_messages',
      'Messages de chat',
      description: 'Notifications pour les nouveaux messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Créer les canaux sur l'appareil Android
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(newEventsChannel);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(remindersChannel);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatMessagesChannel);

    debugPrint("✅ Canaux de notification créés avec importance MAX");

    // 3. Local Notifications Setup
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
    bool isFirstLoad = true; // Flag pour le premier chargement
    
    _eventService.getEventsStream().listen((events) {
      debugPrint("📅 Détection de ${events.length} événements");
      
      if (isFirstLoad) {
        // PREMIER CHARGEMENT: Ajouter tous les événements existants au Set SANS notifier
        debugPrint("🔄 Premier chargement: Enregistrement de ${events.length} événements existants (pas de notification)");
        for (var event in events) {
          notifiedEvents.add(event.id);
        }
        isFirstLoad = false;
      } else {
        // CHARGEMENTS SUIVANTS: Notifier seulement les NOUVEAUX événements
        for (var event in events) {
          // Si c'est un nouvel événement (pas encore dans le Set)
          if (!notifiedEvents.contains(event.id)) {
            notifiedEvents.add(event.id);
            
            // Envoyer une notification immédiate SEULEMENT pour les vrais nouveaux événements
            debugPrint("🆕 Nouvel événement détecté: ${event.title}");
            _sendImmediateEventNotification(event);
          }
        }
      }
      
      // Programmer les rappels 30 min avant pour tous les événements (nouveaux ET existants)
      scheduleMultipleReminders(events);
    });
  }
  
  Future<void> _sendImmediateEventNotification(EventModel event) async {
    debugPrint("🔔 Envoi notification immédiate pour: ${event.title}");
    
    // Incrémenter le badge
    await _incrementBadge();
    
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
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'new_events',
            'Nouveaux événements',
            channelDescription: 'Notifications pour les nouveaux événements créés',
            importance: Importance.max, // Max pour la popup heads-up
            priority: Priority.high,
            
            // SON - Active le son par défaut du système
            playSound: true,
            
            // VIBRATION - Pattern de vibration
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Vibration: pause, vibrer, pause, vibrer
            
            // POPUP HEADS-UP - Affiche en haut de l'écran
            fullScreenIntent: true,
            
            // STYLE - Couleur
            color: const Color(0xFF1565C0), // Bleu pour les événements
            
            // LED - Pour les appareils qui ont une LED
            enableLights: true,
            ledColor: const Color(0xFF1565C0),
            ledOnMs: 1000,
            ledOffMs: 500,
            
            // CATÉGORIE - Pour le système Android
            category: AndroidNotificationCategory.event,
            
            // TICKER - Texte qui défile brièvement
            ticker: 'Nouvel événement: ${event.title}',
            
            // VISIBILITÉ - Apparaît sur lockscreen
            visibility: NotificationVisibility.public,
            
            // BADGE - Nombre de notifications non lues
            number: _badgeCount,
          ),
        ),
        payload: payload,
      );
      debugPrint("✅ Notification immédiate envoyée pour: ${event.title} (Badge: $_badgeCount)");
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Rappels d\'événements',
          channelDescription: 'Rappels 30 minutes avant les événements',
          importance: Importance.max, // Max pour la popup heads-up
          priority: Priority.high,
          
          // SON - Active le son par défaut du système
          playSound: true,
          
          // VIBRATION - Pattern de vibration
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 300]), // Triple vibration
          
          // POPUP HEADS-UP
          fullScreenIntent: true,
          
          // STYLE
          color: const Color(0xFFFF9800), // Orange pour les rappels
          
          // LED
          enableLights: true,
          ledColor: const Color(0xFFFF9800),
          ledOnMs: 1000,
          ledOffMs: 500,
          
          // CATÉGORIE
          category: AndroidNotificationCategory.reminder,
          
          // TICKER
          ticker: 'Rappel: $title',
          
          // VISIBILITÉ
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint("✅ Rappel programmé pour $title à $reminderTime");
  }

  Future<void> showChatMessageNotification(String sender, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Messages de chat',
      channelDescription: 'Notifications pour les nouveaux messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Nouveau message',
      playSound: true,
      enableVibration: true,
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: sender,
      body: message,
      notificationDetails: details,
    );
  }

  Future<void> cancelReminder(String id) async {
    await _localNotifications.cancel(id: id.hashCode);
  }
}

