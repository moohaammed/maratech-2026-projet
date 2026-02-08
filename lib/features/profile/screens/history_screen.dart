import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../services/history_service.dart';
import '../models/history_event_model.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
         _speak(_getLocalizedTitle(accessibility.languageCode));
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
    final langCode = accessibility.languageCode;
    final isHighContrast = accessibility.profile.highContrast;
    final textScale = accessibility.profile.textSize;

    final primaryColor = isHighContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = isHighContrast ? Colors.black : AppColors.background;
    final textColor = isHighContrast ? Colors.white : AppColors.textPrimary;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('Veuillez vous connecter', style: TextStyle(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _getLocalizedTitle(langCode),
          style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<HistoryEventModel>>(
        stream: HistoryService().getUserHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(child: Text(_getLocalizedEmpty(langCode), style: TextStyle(color: textColor)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildHistoryCard(event, langCode, textScale, isHighContrast, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryEventModel event, String langCode, double textScale, bool highContrast, Color primary) {
    final title = event.getLocalizedTitle(langCode);
    final location = event.getLocalizedLocation(langCode);
    final date = _formatDate(event.date, langCode);
    
    // Construct speech text
    final speakText = "$title. $location. $date. ${event.distance}. ${event.pace}.";

    return GestureDetector(
      onTap: () => _speak(speakText),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: highContrast ? Colors.grey[900] : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 18 * textScale,
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (event.attended)
                    Icon(Icons.check_circle, color: Colors.green, size: 24 * textScale)
                  else
                    Icon(Icons.cancel, color: Colors.grey, size: 24 * textScale),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16 * textScale, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: highContrast ? Colors.grey[300] : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(Icons.calendar_today, date, textScale, highContrast),
                  _buildStat(Icons.directions_run, event.distance, textScale, highContrast),
                  _buildStat(Icons.timer, event.pace, textScale, highContrast),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, double textScale, bool highContrast) {
    return Row(
      children: [
        Icon(icon, size: 16 * textScale, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14 * textScale,
            fontWeight: FontWeight.w500,
            color: highContrast ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, String langCode) {
    try {
      return DateFormat.yMMMd(langCode).format(date);
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getLocalizedTitle(String langCode) {
    switch (langCode) {
      case 'ar': return 'سجل النشاط';
      case 'en': return 'Activity History';
      default: return 'Historique';
    }
  }

  String _getLocalizedEmpty(String langCode) {
    switch (langCode) {
      case 'ar': return 'لا يوجد سجل';
      case 'en': return 'No history found';
      default: return 'Aucun historique';
    }
  }
}
