import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/material.dart';
import '../../../../core/services/accessibility_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import '../../../accessibility/providers/accessibility_provider.dart';

/// Premium Event Detail Screen with immersive design and animations
class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {

  bool _hasSpoken = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Future<EventModel?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = EventService().getEventById(widget.eventId);
    // _initTts(); // Removed local TTS init
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    )..forward();
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {

    _animController.dispose();
    super.dispose();
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
             SnackBar(content: Text('Impossible d\'ouvrir la carte')),
           );
        }
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  Future<void> _addToCalendar(EventModel event) async {
    try {
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
      final endDate = startDate.add(const Duration(hours: 2));

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
           SnackBar(content: Text('Erreur calendrier')),
         );
      }
    }
  }

  Future<void> _speakEvent(EventModel event) async {
    if (_hasSpoken) return;
    
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    // Only speak if TTS is enabled AND (user needs it OR explicitly enabled)
    final shouldSpeak = profile.ttsEnabled && 
                       (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision');

    if (!shouldSpeak) {
      return;
    }

    _hasSpoken = true;
    
    await Future.delayed(const Duration(milliseconds: 500));
    final service = Provider.of<AccessibilityService>(context, listen: false);
    
    String text = "Détail de l'événement. Titre : ${event.title}. Date : ${_formatDate(event.date)}. Heure : ${event.time}. Lieu : ${event.location}.";
    await service.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final textColor = highContrast ? Colors.white : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<EventModel?>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Événement introuvable',
                style: TextStyle(color: Colors.grey, fontSize: 16 * textScale),
              ),
            );
          }
          final event = snapshot.data!;
          
          if (!_hasSpoken) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _speakEvent(event));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(event, primaryColor, textScale),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(20 * textScale.clamp(1.0, 1.1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventHeader(event, primaryColor, textScale),
                          SizedBox(height: 24 * textScale),
                          _buildActionButtons(event, primaryColor, textScale),
                          SizedBox(height: 24 * textScale),
                          _buildInfoSection(event, primaryColor, textScale, highContrast),
                          if (event.latitude != null && event.longitude != null) ...[
                            SizedBox(height: 24 * textScale),
                            _buildMapSection(event, primaryColor, textScale),
                          ],
                          SizedBox(height: 40 * textScale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(EventModel event, Color primaryColor, double textScale) {
    final groupColor = _getGroupColor(event.group);
    
    return SliverAppBar(
      expandedHeight: 200 * textScale.clamp(1.0, 1.3),
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    groupColor.withOpacity(0.8),
                    groupColor.withOpacity(0.4),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
            // Pattern Overlay
            Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
            // Bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A0A0F),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader(EventModel event, Color primaryColor, double textScale) {
    final groupColor = _getGroupColor(event.group);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: groupColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: groupColor.withOpacity(0.3)),
              ),
              child: Text(
                event.groupDisplayName.toUpperCase(),
                style: TextStyle(
                  color: groupColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12 * textScale,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.typeDisplayName,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12 * textScale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * textScale),
        Hero(
          tag: 'event_title_${event.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              event.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28 * textScale,
                fontWeight: FontWeight.bold,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: groupColor.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(EventModel event, Color primaryColor, double textScale) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassButton(
            icon: Icons.map_rounded,
            label: 'Carte',
            onTap: () => _openMap(event.location, event.latitude, event.longitude),
            color: Colors.blueAccent,
            textScale: textScale,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassButton(
            icon: Icons.calendar_month_rounded,
            label: 'Agenda',
            onTap: () => _addToCalendar(event),
            color: primaryColor,
            textScale: textScale,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16 * textScale.clamp(1.0, 1.1)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8 * textScale),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * textScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(EventModel event, Color primaryColor, double textScale, bool highContrast) {
    return Container(
      padding: EdgeInsets.all(24 * textScale.clamp(1.0, 1.1)),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatFullDate(event.date),
            primaryColor: primaryColor,
            textScale: textScale,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Heure',
            value: event.time,
            primaryColor: primaryColor,
            textScale: textScale,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Lieu',
            value: event.location,
            primaryColor: primaryColor,
            textScale: textScale,
          ),
          if (event.distanceKm != null) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.straighten_rounded,
              label: 'Distance',
              value: '${event.distanceKm} km',
              primaryColor: primaryColor,
              textScale: textScale,
            ),
          ],
          if (event.description != null && event.description!.isNotEmpty) ...[
            _buildDivider(),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13 * textScale,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * textScale,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required double textScale,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        SizedBox(width: 16 * textScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12 * textScale,
                ),
              ),
              SizedBox(height: 2 * textScale),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
    );
  }

  Widget _buildMapSection(EventModel event, Color primaryColor, double textScale) {
    if (event.latitude == null || event.longitude == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de la carte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16 * textScale),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(event.latitude!, event.longitude!),
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.maratech',
                  // Dark mode filter for map
                  tileBuilder: (context, widget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey, 
                        BlendMode.saturation,
                      ),
                      child: widget,
                    );
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(event.latitude!, event.longitude!),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getGroupColor(RunningGroup? group) {
    if (group == null) return AppColors.info;
    switch (group) {
      case RunningGroup.group1: return AppColors.beginner;
      case RunningGroup.group2: return AppColors.intermediate;
      case RunningGroup.group3:
      case RunningGroup.group4: return AppColors.advanced;
      case RunningGroup.group5: return AppColors.elite;
    }
  }

  String _formatFullDate(DateTime d) {
    final monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${d.day} ${monthsFr[d.month - 1]} ${d.year}';
  }

  String _formatDate(DateTime d) {
     return '${d.day}/${d.month}/${d.year}';
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
