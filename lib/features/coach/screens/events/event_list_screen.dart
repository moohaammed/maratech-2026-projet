import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

/// Event list with filters by date and group. All users can consult; FAB for create only when [canCreate] (coach/admin).
class EventListScreen extends StatefulWidget {
  final bool canCreate;

  const EventListScreen({super.key, this.canCreate = false});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventService _eventService = EventService();
  DateTime? _filterFrom;
  DateTime? _filterTo;
  RunningGroup? _filterGroup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Événements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToCreate(context),
              tooltip: 'Créer un événement',
            ),
          if (widget.canCreate)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: Column(
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
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun événement',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
      ),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton(
              onPressed: () => _navigateToCreate(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _filterFrom == null && _filterTo == null
                    ? 'Date'
                    : _formatDateRange(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<RunningGroup?>(
              value: _filterGroup,
              decoration: const InputDecoration(
                labelText: 'Groupe',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                ...RunningGroup.values.map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(_groupLabel(g)),
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
    if (_filterFrom != null) return 'À partir du ${_formatDate(_filterFrom!)}';
    if (_filterTo != null) return 'Jusqu\'au ${_formatDate(_filterTo!)}';
    return 'Date';
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _groupLabel(RunningGroup g) {
    switch (g) {
      case RunningGroup.group1: return 'Groupe 1';
      case RunningGroup.group2: return 'Groupe 2';
      case RunningGroup.group3: return 'Groupe 3';
      case RunningGroup.group4: return 'Groupe 4';
      case RunningGroup.group5: return 'Groupe 5';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: event.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: groupColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: groupColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      event.groupDisplayName,
                      style: TextStyle(
                        color: groupColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (event.weeklySubType != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      event.weeklySubTypeDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(event.date)} · ${event.time}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (event.distanceKm != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${event.distanceKm} km',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
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
