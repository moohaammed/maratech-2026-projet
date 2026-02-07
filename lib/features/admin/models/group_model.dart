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
    try {
      final data = doc.data() as Map<String, dynamic>;
      print('DEBUG: Parsing group doc.id=${doc.id}');
      
      // Handle Level (String or Int)
      GroupLevel parsedLevel = GroupLevel.beginner;
      final rawLevel = data['level'];
      print('DEBUG: rawLevel=$rawLevel (type: ${rawLevel.runtimeType})');
      
      if (rawLevel is String) {
        // Try matching full enum string first (e.g., "GroupLevel.advanced")
        parsedLevel = GroupLevel.values.firstWhere(
          (e) => e.toString() == rawLevel,
          orElse: () {
            // Try matching just the name (e.g., "advanced", "beginner", "intermediate")
            return GroupLevel.values.firstWhere(
              (e) => e.name == rawLevel || e.toString().split('.').last == rawLevel,
              orElse: () => GroupLevel.beginner,
            );
          },
        );
      } else if (rawLevel is int) {
        // Map 1->Beginner, 2->Intermediate, 3->Advanced (Assumption based on user data)
        if (rawLevel == 1) parsedLevel = GroupLevel.beginner;
        else if (rawLevel == 2) parsedLevel = GroupLevel.intermediate;
        else if (rawLevel >= 3) parsedLevel = GroupLevel.advanced;
      }
      
      print('DEBUG: parsedLevel=$parsedLevel for doc.id=${doc.id}');

      // Handle memberIds - could be missing or different field name
      List<String> memberIds = [];
      if (data['memberIds'] != null) {
        memberIds = List<String>.from(data['memberIds']);
      }

      return GroupModel(
        id: doc.id,
        name: data['name'] ?? '',
        level: parsedLevel,
        adminId: data['adminId'],
        memberIds: memberIds, 
        createdAt: data['createdAt'] is Timestamp 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('ERROR: Failed to parse group ${doc.id}: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
