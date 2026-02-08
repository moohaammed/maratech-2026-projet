import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../../coach/models/event_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    NotificationService.resetBadge();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         _speak(_T(context, 'Notifications', 'Notifications', 'الإشعارات'));
       }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    final provider = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = provider.profile;

    if (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision' || profile.ttsEnabled) {
      String lang = "fr-FR";
      if (provider.languageCode == 'en') lang = "en-US";
      if (provider.languageCode == 'ar') lang = "ar-SA";
      
      await _flutterTts.setLanguage(lang);
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;

    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _T(context, 'Notifications', 'Notifications', 'الإشعارات'),
          style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data?.docs ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, 
                       size: 64 * textScale, 
                       color: highContrast ? Colors.white54 : Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _T(context, 'Aucune nouvelle notification', 'No new notifications', 'لا توجد إشعارات جديدة'),
                    style: TextStyle(
                      fontSize: 18 * textScale,
                      color: highContrast ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final type = data['type'] ?? 'daily';
              
              return _NotificationTile(
                eventId: doc.id,
                title: data['title'] ?? 'Nouveau message',
                body: _getNotificationBody(context, data, type),
                time: DateFormat.jm(accessibility.languageCode).format(date),
                date: DateFormat.yMMMd(accessibility.languageCode).format(date),
                isEvent: true,
                type: type,
                textScale: textScale,
                highContrast: highContrast,
                primaryColor: primaryColor,
                onSpeak: _speak,
              );
            },
          );
        },
      ),
    );
  }

  String _getNotificationBody(BuildContext context, Map<String, dynamic> data, String type) {
    if (type == 'daily') {
      return _T(context, 
        'Entraînement quotidien à ${data['location'] ?? 'la plage'}.', 
        'Daily training at ${data['location'] ?? 'the beach'}.',
        'تدريب يومي في ${data['location'] ?? 'الشاطئ'}.');
    } else {
      return _T(context, 
        'Événement spécial : ${data['location'] ?? 'Tunis'}. Préparez-vous !', 
        'Special event: ${data['location'] ?? 'Tunis'}. Get ready!',
        'حدث خاص: ${data['location'] ?? 'تونس'}. استعد!');
    }
  }

  String _T(BuildContext context, String fr, String en, String ar) {
    final lang = Provider.of<AccessibilityProvider>(context, listen: false).languageCode;
    if (lang == 'ar') return ar;
    if (lang == 'en') return en;
    return fr;
  }
}

class _NotificationTile extends StatelessWidget {
  final String eventId;
  final String title;
  final String body;
  final String time;
  final String date;
  final bool isEvent;
  final String type;
  final double textScale;
  final bool highContrast;
  final Color primaryColor;
  final Function(String) onSpeak;

  const _NotificationTile({
    required this.eventId,
    required this.title,
    required this.body,
    required this.time,
    required this.date,
    required this.isEvent,
    required this.type,
    required this.textScale,
    required this.highContrast,
    required this.primaryColor,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = type == 'weekly' ? AppColors.accent : AppColors.primary;
    final itemBgColor = highContrast ? AppColors.highContrastSurface : Colors.white;
    final borderColor = highContrast ? Colors.white24 : Colors.grey.withOpacity(0.1);
    
    final speakText = "$title. $body. $time. $date.";

    return GestureDetector(
      onTap: () {
        onSpeak(speakText);
        Navigator.pushNamed(
          context,
          '/event-details',
          arguments: eventId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: itemBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: highContrast ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'weekly' ? Icons.star : Icons.run_circle,
                  color: iconColor,
                  size: 24 * textScale.clamp(1.0, 1.2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                              color: highContrast ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12 * textScale,
                            color: highContrast ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: highContrast ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11 * textScale,
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
