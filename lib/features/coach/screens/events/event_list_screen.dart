import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import '../../../accessibility/providers/accessibility_provider.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

/// Event list with filters by date and group. All users can consult; FAB for create only when [canCreate] (coach/admin).
class EventListScreen extends StatefulWidget {
  final bool canCreate;
  final bool hideAppBar;

  const EventListScreen({
    super.key, 
    this.canCreate = false,
    this.hideAppBar = false,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventService _eventService = EventService();
  final FlutterTts _tts = FlutterTts();
  DateTime? _filterFrom;
  DateTime? _filterTo;
  RunningGroup? _filterGroup;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speakSelection(String title) async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibility.profile.visualNeeds != 'blind' && accessibility.profile.visualNeeds != 'low_vision') {
      return;
    }

    final lang = accessibility.languageCode;
    String ttsCode = 'fr-FR';
    String prefix = 'Ouverture de';
    
    if (lang == 'ar') {
      ttsCode = 'ar-SA';
      prefix = 'فتح';
    } else if (lang == 'en') {
      ttsCode = 'en-US';
      prefix = 'Opening';
    }
    
    await _tts.setLanguage(ttsCode);
    await _tts.speak('$prefix $title');
  }

  String _T(String fr, String en, String ar) {
    final lang = Provider.of<AccessibilityProvider>(context, listen: false).languageCode;
    switch (lang) {
      case 'ar': return ar;
      case 'en': return en;
      default: return fr;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: _eventService.getEventsStream(
              fromDate: _filterFrom,
              toDate: _filterTo,
              group: _filterGroup,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${_T('Erreur', 'Error', 'خطأ')}: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    _T('Aucun événement', 'No events', 'لا توجد فعاليات'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 8, 16, widget.canCreate ? 80 : 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(context, event);
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.hideAppBar) {
      return Material(
        color: AppColors.background,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_T('Événements', 'Events', 'الفعاليات'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToCreate(context),
              tooltip: _T('Créer un événement', 'Create an event', 'إنشاء فعالية'),
            ),
          if (widget.canCreate)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              tooltip: _T('Déconnexion', 'Logout', 'تسجيل الخروج'),
            ),
        ],
      ),
      body: content,
      floatingActionButton: widget.canCreate
          ? FloatingActionButton(
              onPressed: () => _navigateToCreate(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
              tooltip: _T('Créer un événement', 'Create an event', 'إنشاء فعالية'),
            )
          : null,
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: OutlinedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Flexible(
                child: Text(
                  _filterFrom == null && _filterTo == null
                      ? _T('Date', 'Date', 'التاريخ')
                      : _formatDateRange(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<RunningGroup?>(
              value: _filterGroup,
              decoration: InputDecoration(
                labelText: _T('Groupe', 'Group', 'المجموعة'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                labelStyle: const TextStyle(fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: [
                DropdownMenuItem(value: null, child: Text(_T('Tous', 'All', 'الكل'), style: const TextStyle(fontSize: 13))),
                ...RunningGroup.values.map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(_groupLabel(g), style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _filterGroup = value),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (_filterFrom != null && _filterTo != null) {
      return '${_formatDate(_filterFrom!)} - ${_formatDate(_filterTo!)}';
    }
    if (_filterFrom != null) return '${_T('À partir du', 'From', 'من')} ${_formatDate(_filterFrom!)}';
    if (_filterTo != null) return '${_T('Jusqu\'au', 'To', 'إلى')} ${_formatDate(_filterTo!)}';
    return _T('Date', 'Date', 'التاريخ');
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _groupLabel(RunningGroup g) {
    String label = 'Groupe';
    if (Provider.of<AccessibilityProvider>(context, listen: false).languageCode == 'en') label = 'Group';
    if (Provider.of<AccessibilityProvider>(context, listen: false).languageCode == 'ar') label = 'المجموعة';

    switch (g) {
      case RunningGroup.group1: return '$label 1';
      case RunningGroup.group2: return '$label 2';
      case RunningGroup.group3: return '$label 3';
      case RunningGroup.group4: return '$label 4';
      case RunningGroup.group5: return '$label 5';
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _filterFrom != null && _filterTo != null
          ? DateTimeRange(start: _filterFrom!, end: _filterTo!)
          : DateTimeRange(
              start: now,
              end: now.add(const Duration(days: 30)),
            ),
    );
    if (picked != null && mounted) {
      setState(() {
        _filterFrom = picked.start;
        _filterTo = picked.end;
      });
    }
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOUT', 'SEPT', 'OCT', 'NOV', 'DEC'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: groupColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _speakSelection(event.title);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(eventId: event.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Box
                Container(
                  width: 56,
                  height: 64,
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: groupColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.date.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: groupColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMonthName(event.date.month),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: groupColor.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: groupColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.groupDisplayName,
                              style: TextStyle(
                                color: groupColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.typeDisplayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Hero(
                        tag: 'event_title_${event.id}', // Ensure unique tag
                        child: Material( // Hero needs Material context for text
                          color: Colors.transparent,
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Details Row
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            event.time,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    ).then((_) => setState(() {}));
  }
}
