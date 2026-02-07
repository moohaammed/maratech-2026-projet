import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../../coach/models/event_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = type == 'weekly' ? AppColors.accent : AppColors.primary;
    final itemBgColor = highContrast ? AppColors.highContrastSurface : Colors.white;
    final borderColor = highContrast ? Colors.white24 : Colors.grey.withOpacity(0.1);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/event-details',
              arguments: eventId,
            );
          },
          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
