import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String titleFr;
  final String titleEn;
  final String titleAr;
  final String contentFr;
  final String contentEn;
  final String contentAr;
  final String author;
  final String priority;
  final bool isPinned;
  final String group;
  final String targetGroup;
  final bool read;
  final DateTime timestamp;

  AnnouncementModel({
    required this.id,
    required this.titleFr,
    required this.titleEn,
    required this.titleAr,
    required this.contentFr,
    required this.contentEn,
    required this.contentAr,
    required this.author,
    required this.priority,
    required this.isPinned,
    required this.group,
    required this.targetGroup,
    required this.read,
    required this.timestamp,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> data, String id) {
    return AnnouncementModel(
      id: id,
      titleFr: data['title_fr'] ?? '',
      titleEn: data['title_en'] ?? '',
      titleAr: data['title_ar'] ?? '',
      contentFr: data['content_fr'] ?? '',
      contentEn: data['content_en'] ?? '',
      contentAr: data['content_ar'] ?? '',
      author: data['author'] ?? '',
      priority: data['priority'] ?? 'normal',
      isPinned: data['isPinned'] ?? false,
      group: data['group'] ?? '',
      targetGroup: data['targetGroup'] ?? '',
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getLocalizedTitle(String langCode) {
    switch (langCode) {
      case 'ar': return titleAr;
      case 'en': return titleEn;
      default: return titleFr;
    }
  }

  String getLocalizedContent(String langCode) {
    switch (langCode) {
      case 'ar': return contentAr;
      case 'en': return contentEn;
      default: return contentFr;
    }
  }
}
