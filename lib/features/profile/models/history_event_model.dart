import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEventModel {
  final String id;
  final String titleFr;
  final String titleEn;
  final String titleAr;
  final String locationFr;
  final String locationEn;
  final String locationAr;
  final DateTime date;
  final String distance;
  final String pace;
  final int participants;
  final bool attended;

  HistoryEventModel({
    required this.id,
    required this.titleFr,
    required this.titleEn,
    required this.titleAr,
    required this.locationFr,
    required this.locationEn,
    required this.locationAr,
    required this.date,
    required this.distance,
    required this.pace,
    required this.participants,
    required this.attended,
  });

  factory HistoryEventModel.fromMap(Map<String, dynamic> data, String id) {
    return HistoryEventModel(
      id: id,
      titleFr: data['title_fr'] ?? '',
      titleEn: data['title_en'] ?? '',
      titleAr: data['title_ar'] ?? '',
      locationFr: data['location_fr'] ?? '',
      locationEn: data['location_en'] ?? '',
      locationAr: data['location_ar'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distance: data['distance'] ?? '',
      pace: data['pace'] ?? '',
      participants: (data['participants'] as num?)?.toInt() ?? 0,
      attended: data['attended'] ?? false,
    );
  }

  String getLocalizedTitle(String langCode) {
    switch (langCode) {
      case 'ar': return titleAr;
      case 'en': return titleEn;
      default: return titleFr;
    }
  }

  String getLocalizedLocation(String langCode) {
    switch (langCode) {
      case 'ar': return locationAr;
      case 'en': return locationEn;
      default: return locationFr;
    }
  }
}
