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
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      level: GroupLevel.values.firstWhere(
        (e) => e.toString() == data['level'],
        orElse: () => GroupLevel.beginner,
      ),
      adminId: data['adminId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: data['createdAt'] != null 
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
