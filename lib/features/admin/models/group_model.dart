import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupLevel {
  beginner,
  intermediate,
  advanced
}

class GroupModel {
  final String id;
  final String name;
  final GroupLevel level;
  final String? adminId;
  final List<String> memberIds;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.level,
    this.adminId,
    this.memberIds = const [],
    required this.createdAt,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle Level (String or Int)
    GroupLevel parsedLevel = GroupLevel.beginner;
    final rawLevel = data['level'];
    if (rawLevel is String) {
      parsedLevel = GroupLevel.values.firstWhere(
        (e) => e.toString() == rawLevel,
        orElse: () => GroupLevel.beginner,
      );
    } else if (rawLevel is int) {
      // Map 1->Beginner, 2->Intermediate, 3->Advanced (Assumption based on user data)
      if (rawLevel == 1) parsedLevel = GroupLevel.beginner;
      else if (rawLevel == 2) parsedLevel = GroupLevel.intermediate;
      else if (rawLevel >= 3) parsedLevel = GroupLevel.advanced;
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      level: parsedLevel,
      adminId: data['adminId'],
      memberIds: List<String>.from(data['memberIds'] ?? []), 
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'level': level.toString(),
      'adminId': adminId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
