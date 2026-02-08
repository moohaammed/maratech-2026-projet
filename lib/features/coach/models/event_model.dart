import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/models/user_model.dart';

/// Type d'événement
enum EventType {
  daily,   // Entraînement quotidien par groupe
  weekly,  // Sortie longue ou course officielle
}

/// Sous-type pour événement hebdomadaire
enum WeeklyEventSubType {
  longRun,       // Sortie longue
  specialEvent,  // Course officielle / Événement spécial
}

/// Modèle d'événement
class EventModel {
  final String id;
  final String title;
  final String? description;
  final EventType type;
  final WeeklyEventSubType? weeklySubType;
  final RunningGroup? group;           // Pour daily; null pour weekly
  final DateTime date;
  final String time;                   // Format "HH:mm"
  final String location;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final DateTime createdAt;
  final String? createdBy;
  final List<String> participants;     // IDs des participants inscrits

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
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.createdAt,
    this.createdBy,
    this.participants = const [],
  });

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      type: _parseEventType(data['type']),
      weeklySubType: _parseWeeklySubType(data['weeklySubType']),
      group: _parseRunningGroup(data['group']),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '09:00',
      location: data['location'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'weeklySubType': weeklySubType?.name,
      'group': group?.name,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'participants': participants,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    WeeklyEventSubType? weeklySubType,
    RunningGroup? group,
    DateTime? date,
    String? time,
    String? location,
    double? latitude,
    double? longitude,
    double? distanceKm,
    DateTime? createdAt,
    String? createdBy,
    List<String>? participants,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      weeklySubType: weeklySubType ?? this.weeklySubType,
      group: group ?? this.group,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
    );
  }

  /// Helper getter for displaying event type
  String get typeDisplayName {
    if (type == EventType.weekly) {
      if (weeklySubType == WeeklyEventSubType.specialEvent) {
        return 'Course Officielle';
      }
      return 'Sortie Longue';
    }
    return 'Entraînement Quotidien';
  }

  /// Helper getter for displaying group name
  String get groupDisplayName {
    if (group == null) return 'Tous les groupes';
    switch (group!) {
      case RunningGroup.group1: return 'Groupe 1';
      case RunningGroup.group2: return 'Groupe 2';
      case RunningGroup.group3: return 'Groupe 3';
      case RunningGroup.group4: return 'Groupe 4';
      case RunningGroup.group5: return 'Groupe 5';
    }
  }

  /// Helper getter for formatted date
  String get formattedDate {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 
                   'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Helper getter for displaying weekly sub-type
  String get weeklySubTypeDisplayName {
    if (weeklySubType == null) return '';
    switch (weeklySubType!) {
      case WeeklyEventSubType.longRun: return 'Sortie Longue';
      case WeeklyEventSubType.specialEvent: return 'Course Officielle';
    }
  }

  static EventType _parseEventType(String? value) {
    if (value == 'weekly') return EventType.weekly;
    return EventType.daily;
  }

  static WeeklyEventSubType? _parseWeeklySubType(String? value) {
    if (value == null) return null;
    if (value == 'specialEvent') return WeeklyEventSubType.specialEvent;
    return WeeklyEventSubType.longRun;
  }

  static RunningGroup? _parseRunningGroup(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'group1': return RunningGroup.group1;
      case 'group2': return RunningGroup.group2;
      case 'group3': return RunningGroup.group3;
      case 'group4': return RunningGroup.group4;
      case 'group5': return RunningGroup.group5;
      default: return null;
    }
  }
}
