import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/models/user_model.dart';

/// Event frequency: daily (per group) or weekly (long runs / special races).
enum EventType {
  daily,   // Quotidien - created per group, time/location/distance varies
  weekly,  // Hebdomadaire - long runs or special events
}

/// For weekly events: training long run or official race.
enum WeeklyEventSubType {
  longRun,     // Sortie longue - training
  specialEvent, // Course officielle - national/international race
}

class EventModel {
  final String id;
  final String title;
  final String? description;
  final EventType type;
  final WeeklyEventSubType? weeklySubType; // Only when type == weekly
  final RunningGroup? group;                // Required for daily; optional for weekly (all groups)
  final DateTime date;
  final String time;                        // e.g. "18:00"
  final String location;
  final double? distanceKm;
  final DateTime createdAt;
  final String? createdBy;                  // User ID of creator (coach/admin)

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.weeklySubType,
    this.group,
    required this.date,
    required this.time,
    required this.location,
    this.distanceKm,
    required this.createdAt,
    this.createdBy,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] as String?,
      type: EventType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => EventType.daily,
      ),
      weeklySubType: data['weeklySubType'] != null
          ? WeeklyEventSubType.values.firstWhere(
              (e) => e.toString() == data['weeklySubType'],
              orElse: () => WeeklyEventSubType.longRun,
            )
          : null,
      group: data['group'] != null
          ? RunningGroup.values.firstWhere(
              (e) => e.toString() == data['group'],
              orElse: () => RunningGroup.group1,
            )
          : null,
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date'].toString()))
          : DateTime.now(),
      time: data['time'] ?? '09:00',
      location: data['location'] ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.toString(),
      'weeklySubType': weeklySubType?.toString(),
      'group': group?.toString(),
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'distanceKm': distanceKm,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case EventType.daily:
        return 'Quotidien';
      case EventType.weekly:
        return 'Hebdomadaire';
    }
  }

  String get weeklySubTypeDisplayName {
    if (weeklySubType == null) return '';
    switch (weeklySubType!) {
      case WeeklyEventSubType.longRun:
        return 'Sortie longue';
      case WeeklyEventSubType.specialEvent:
        return 'Course officielle';
    }
  }

  String get groupDisplayName {
    if (group == null) return 'Tous les groupes';
    switch (group!) {
      case RunningGroup.group1:
        return 'Groupe 1';
      case RunningGroup.group2:
        return 'Groupe 2';
      case RunningGroup.group3:
        return 'Groupe 3';
      case RunningGroup.group4:
        return 'Groupe 4';
      case RunningGroup.group5:
        return 'Groupe 5';
    }
  }
}
