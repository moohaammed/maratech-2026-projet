import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import '../../../accessibility/providers/accessibility_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final langCode = accessibility.languageCode;
    
    String ttsCode = 'fr-FR';
    if (langCode == 'ar') ttsCode = 'ar-SA';
    if (langCode == 'en') ttsCode = 'en-US';
    
    await _tts.setLanguage(ttsCode);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  String _T(String fr, String en, String ar) {
    final lang = Provider.of<AccessibilityProvider>(context, listen: false).languageCode;
    switch (lang) {
      case 'ar': return ar;
      case 'en': return en;
      default: return fr;
    }
  }

  Future<void> _openMap(String location, double? lat, double? lng) async {
    Uri googleUrl;
    if (lat != null && lng != null) {
      googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    } else {
      final query = Uri.encodeComponent(location);
      googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    }
    
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(_T('Impossible d\'ouvrir la carte', 'Could not open map', 'تعذر فتح الخريطة'))),
           );
        }
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  Future<void> _addToCalendar(EventModel event) async {
    try {
      // Parse time
      final timeParts = event.time.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
      final startDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        hour,
        minute,
      );
      final endDate = startDate.add(const Duration(hours: 2)); // Assume 2h duration

      final calendarEvent = calendar.Event(
        title: event.title,
        description: event.description ?? '',
        location: event.location,
        startDate: startDate,
        endDate: endDate,
        allDay: false,
      );

      await calendar.Add2Calendar.addEvent2Cal(calendarEvent);
    } catch (e) {
      debugPrint('Error adding to calendar: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(_T('Erreur calendrier', 'Calendar error', 'خطأ في التقويم'))),
         );
      }
    }
  }

  Future<void> _speakEvent(EventModel event) async {
    if (_hasSpoken) return;
    
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibility.profile.visualNeeds != 'blind' && accessibility.profile.visualNeeds != 'low_vision') {
      debugPrint('🔇 Voice guidance skipped: visualNeeds is ${accessibility.profile.visualNeeds}');
      return;
    }

    _hasSpoken = true;
    final lang = accessibility.languageCode;
    debugPrint('🗣️ Speaking event details in $lang');

    // Small delay to let the screen transition finish
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ensure language is set before each speak to be safe
    String ttsCode = 'fr-FR';
    if (lang == 'ar') ttsCode = 'ar-SA';
    if (lang == 'en') ttsCode = 'en-US';
    await _tts.setLanguage(ttsCode);
    String text = '';
    if (lang == 'ar') {
      text = "تفاصيل الفعالية. العنوان: ${event.title}. "
             "التاريخ: ${_formatDate(event.date)}. "
             "الوقت: ${event.time}. "
             "المكان: ${event.location}. "
             "${event.distanceKm != null ? 'المسافة: ${event.distanceKm} كيلومتر.' : ''} "
             "النوع: ${event.typeDisplayName}. "
             "المجموعة: ${event.groupDisplayName}. "
             "${event.description != null ? 'الوصف: ${event.description}' : ''}";
    } else if (lang == 'en') {
      text = "Event details. Title: ${event.title}. "
             "Date: ${_formatDate(event.date)}. "
             "Time: ${event.time}. "
             "Location: ${event.location}. "
             "${event.distanceKm != null ? 'Distance: ${event.distanceKm} kilometers.' : ''} "
             "Type: ${event.typeDisplayName}. "
             "Group: ${event.groupDisplayName}. "
             "${event.description != null ? 'Description: ${event.description}' : ''}";
    } else {
      text = "Détails de l'événement. Titre : ${event.title}. "
             "Date : ${_formatDate(event.date)}. "
             "Heure : ${event.time}. "
             "Lieu : ${event.location}. "
             "${event.distanceKm != null ? 'Distance : ${event.distanceKm} kilomètres.' : ''} "
             "Type : ${event.typeDisplayName}. "
             "Groupe : ${event.groupDisplayName}. "
             "${event.description != null ? 'Description : ${event.description}' : ''}";
    }

    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_T('Détail de l\'événement', 'Event Detail', 'تفاصيل الفعالية'), 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<EventModel?>(
        future: EventService().getEventById(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.hasError ? 'Erreur: ${snapshot.error}' : _T('Événement introuvable', 'Event not found', 'الفعالية غير موجودة'),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final event = snapshot.data!;
          
          // Speak content if accessibility is enabled
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _speakEvent(event);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, event),
                const SizedBox(height: 16),
                
                if (event.latitude != null && event.longitude != null) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(event.latitude!, event.longitude!),
                          initialZoom: 14.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.impact',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(event.latitude!, event.longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openMap(event.location, event.latitude, event.longitude),
                        icon: const Icon(Icons.map, size: 20),
                        label: Text(_T('Carte', 'Map', 'خريطة')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 1,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addToCalendar(event),
                        icon: const Icon(Icons.calendar_month, size: 20),
                        label: Text(_T('Agenda', 'Add', 'إضافة')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                _buildSection(_T('Informations', 'Information', 'معلومات'), [
                  _infoRow(Icons.calendar_today, _T('Date', 'Date', 'التاريخ'), _formatDate(event.date)),
                  _infoRow(Icons.access_time, _T('Heure', 'Time', 'الوقت'), event.time),
                  _infoRow(Icons.location_on, _T('Lieu', 'Location', 'المكان'), event.location),
                  if (event.distanceKm != null)
                    _infoRow(Icons.straighten, _T('Distance', 'Distance', 'المسافة'), '${event.distanceKm} km'),
                  _infoRow(Icons.category, _T('Type', 'Type', 'النوع'), event.typeDisplayName),
                  if (event.weeklySubType != null)
                    _infoRow(Icons.directions_run, _T('Sous-type', 'Sub-type', 'النوع الفرعي'), event.weeklySubTypeDisplayName),
                  _infoRow(Icons.group, _T('Groupe', 'Group', 'المجموعة'), event.groupDisplayName),
                ]),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSection(_T('Description', 'Description', 'الوصف'), [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EventModel event) {
    Color groupColor = AppColors.info;
    if (event.group != null) {
      switch (event.group!) {
        case RunningGroup.group1: groupColor = AppColors.beginner; break;
        case RunningGroup.group2: groupColor = AppColors.intermediate; break;
        case RunningGroup.group3:
        case RunningGroup.group4: groupColor = AppColors.advanced; break;
        case RunningGroup.group5: groupColor = AppColors.elite; break;
      }
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              groupColor.withOpacity(0.15),
              groupColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: groupColor),
                  ),
                  child: Text(
                    event.groupDisplayName,
                    style: TextStyle(
                      color: groupColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  event.typeDisplayName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(event.date)} · ${event.time}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      _T('Jan', 'Jan', 'جانفي'),
      _T('Fév', 'Feb', 'فيفري'),
      _T('Mar', 'Mar', 'مارس'),
      _T('Avr', 'Apr', 'أفريل'),
      _T('Mai', 'May', 'ماي'),
      _T('Juin', 'Jun', 'جوان'),
      _T('Juil', 'Jul', 'جويلية'),
      _T('Août', 'Aug', 'أوت'),
      _T('Sep', 'Sep', 'سبتمبر'),
      _T('Oct', 'Oct', 'أكتوبر'),
      _T('Nov', 'Nov', 'نوفمبر'),
      _T('Déc', 'Dec', 'ديسمبر'),
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
