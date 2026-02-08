import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
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
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: AnnouncementService().getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
          }

          final announcements = snapshot.data ?? [];
          if (announcements.isEmpty) {
            return Center(child: Text(_getLocalizedEmpty(langCode), style: TextStyle(color: textColor)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              return _buildAnnouncementCard(item, langCode, textScale, isHighContrast, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel item, String langCode, double textScale, bool highContrast, Color primary) {
    final title = item.getLocalizedTitle(langCode);
    final content = item.getLocalizedContent(langCode);
    final date = _formatDate(item.timestamp, langCode);
    final author = item.author;
    
    // Construct speech text
    final speakText = "$title. $content. ${item.group}. $author. $date.";

    return GestureDetector(
      onTap: () => _speak(speakText),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: highContrast ? Colors.grey[900] : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.isPinned)
                    Icon(Icons.push_pin, color: primary, size: 20 * textScale),
                  if (item.isPinned) SizedBox(width: 8),
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
                  _buildPriorityBadge(item.priority, textScale),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14 * textScale,
                  color: highContrast ? Colors.grey[300] : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      '$author • $date',
                      style: TextStyle(
                        fontSize: 12 * textScale,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.group,
                        style: TextStyle(
                          fontSize: 12 * textScale,
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, double textScale) {
    Color color;
    IconData icon;
    
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case 'celebration':
        color = Colors.purple;
        icon = Icons.celebration;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, color: color, size: 20 * textScale);
  }

  String _formatDate(DateTime date, String langCode) {
    try {
      return DateFormat.yMMMd(langCode).add_jm().format(date);
    } catch (e) {
      return date.toString();
    }
  }

  String _getLocalizedTitle(String langCode) {
    switch (langCode) {
      case 'ar': return 'الإعلانات';
      case 'en': return 'Announcements';
      default: return 'Annonces';
    }
  }

  String _getLocalizedEmpty(String langCode) {
    switch (langCode) {
      case 'ar': return 'لا توجد إعلانات';
      case 'en': return 'No announcements';
      default: return 'Aucune annonce';
    }
  }
}
