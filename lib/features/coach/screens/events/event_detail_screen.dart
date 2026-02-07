import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de l\'événement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<EventModel?>(
        future: EventService().getEventById(eventId),
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
                    snapshot.hasError ? 'Erreur: ${snapshot.error}' : 'Événement introuvable',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final event = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, event),
                const SizedBox(height: 20),
                _buildSection('Informations', [
                  _infoRow(Icons.calendar_today, 'Date', _formatDate(event.date)),
                  _infoRow(Icons.access_time, 'Heure', event.time),
                  _infoRow(Icons.location_on, 'Lieu', event.location),
                  if (event.distanceKm != null)
                    _infoRow(Icons.straighten, 'Distance', '${event.distanceKm} km'),
                  _infoRow(Icons.category, 'Type', event.typeDisplayName),
                  if (event.weeklySubType != null)
                    _infoRow(Icons.directions_run, 'Sous-type', event.weeklySubTypeDisplayName),
                  _infoRow(Icons.group, 'Groupe', event.groupDisplayName),
                ]),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSection('Description', [
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
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
