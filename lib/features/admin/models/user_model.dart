import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  visitor,        // Visiteur - accès limité
  member,         // Adhérent - utilisateur standard
  groupAdmin,     // Admin de groupe - responsable du groupe
  coachAdmin,     // Admin Coach - partage des programmes
  mainAdmin,      // Admin principal - membre comité directeur
}

enum RunningGroup {
  group1,
  group2,
  group3,
  group4,
  group5,
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String cinLastDigits; // 3 derniers chiffres du CIN
  final UserRole role;
  final RunningGroup? assignedGroup;
  final String? assignedGroupId; // ID of dynamic group
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final Map<String, bool> permissions;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.cinLastDigits,
    required this.role,
    this.assignedGroup,
    this.assignedGroupId,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    Map<String, bool>? permissions,
  }) : permissions = permissions ?? getDefaultPermissions(role);

  static Map<String, bool> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.mainAdmin:
        return {
          'manageUsers': true,
          'manageAdmins': true,
          'managePermissions': true,
          'createEvents': true,
          'deleteEvents': true,
          'viewHistory': true,
          'sendNotifications': true,
          'manageGroups': true,
          'viewStatistics': true,
        };
      case UserRole.coachAdmin:
        return {
          'manageUsers': false,
          'manageAdmins': false,
          'managePermissions': false,
          'createEvents': true,
          'deleteEvents': false,
          'viewHistory': true,
          'sendNotifications': true,
          'manageGroups': false,
          'viewStatistics': true,
        };
      case UserRole.groupAdmin:
        return {
          'manageUsers': false,
          'manageAdmins': false,
          'managePermissions': false,
          'createEvents': true,
          'deleteEvents': true,
          'viewHistory': true,
          'sendNotifications': true,
          'manageGroups': true,
          'viewStatistics': false,
        };
      case UserRole.member:
        return {
          'manageUsers': false,
          'manageAdmins': false,
          'managePermissions': false,
          'createEvents': false,
          'deleteEvents': false,
          'viewHistory': true,
          'sendNotifications': false,
          'manageGroups': false,
          'viewStatistics': false,
        };
      case UserRole.visitor:
        return {
          'manageUsers': false,
          'manageAdmins': false,
          'managePermissions': false,
          'createEvents': false,
          'deleteEvents': false,
          'viewHistory': true,
          'sendNotifications': false,
          'manageGroups': false,
          'viewStatistics': false,
        };
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      cinLastDigits: data['cinLastDigits'] ?? '',
      role: _parseUserRole(data['role']),
      assignedGroup: data['assignedGroup'] != null
          ? RunningGroup.values.firstWhere(
              (e) => e.toString() == data['assignedGroup'] || e.name == data['assignedGroup'],
              orElse: () => RunningGroup.group1,
            )
          : null,
      assignedGroupId: data['assignedGroupId']?.toString(),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
    );
  }

  static UserRole _parseUserRole(dynamic roleData) {
    if (roleData == null) return UserRole.visitor;
    
    final roleStr = roleData.toString().toLowerCase();
    
    if (roleStr == 'main_admin' || roleStr == 'mainadmin') return UserRole.mainAdmin;
    if (roleStr == 'coach_admin' || roleStr == 'coachadmin') return UserRole.coachAdmin;
    if (roleStr == 'group_admin' || roleStr == 'groupadmin') return UserRole.groupAdmin;
    if (roleStr == 'sub_admin' || roleStr == 'subadmin') return UserRole.groupAdmin; // sub_admin = Group Admin
    if (roleStr == 'member' || roleStr == 'user' || roleStr == 'adherent') return UserRole.member;
    if (roleStr == 'visitor' || roleStr == 'guest' || roleStr == 'invite') return UserRole.visitor;
    
    // Fallback to enum check
    try {
      return UserRole.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == roleStr || e.name.toLowerCase() == roleStr,
      );
    } catch (_) {
      return UserRole.visitor;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'cinLastDigits': cinLastDigits,
      'role': role.toString(),
      'assignedGroup': assignedGroup?.toString(),
      'assignedGroupId': assignedGroupId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? cinLastDigits,
    UserRole? role,
    RunningGroup? assignedGroup,
    String? assignedGroupId,
    DateTime? lastLogin,
    bool? isActive,
    Map<String, bool>? permissions,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cinLastDigits: cinLastDigits ?? this.cinLastDigits,
      role: role ?? this.role,
      assignedGroup: assignedGroup ?? this.assignedGroup,
      assignedGroupId: assignedGroupId ?? this.assignedGroupId,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  String getRoleDisplayName() {
    switch (role) {
      case UserRole.visitor:
        return 'Visiteur';
      case UserRole.member:
        return 'Adhérent';
      case UserRole.groupAdmin:
        return 'Admin de Groupe';
      case UserRole.coachAdmin:
        return 'Admin Coach';
      case UserRole.mainAdmin:
        return 'Admin Principal';
    }
  }

  String getGroupDisplayName() {
    // Check for legacy dynamic group IDs that map to levels
    if (assignedGroupId != null) {
      if (['1', '2'].contains(assignedGroupId)) return 'Groupe Débutant';
      if (assignedGroupId == '3') return 'Groupe Intermédiaire';
      if (['4', '5'].contains(assignedGroupId)) return 'Groupe Avancé';
      return 'Groupe Avancé'; // Fallback for other IDs
    }
    
    if (assignedGroup == null) return 'Aucun groupe';
    switch (assignedGroup!) {
      case RunningGroup.group1:
      case RunningGroup.group2:
        return 'Groupe Débutant';
      case RunningGroup.group3:
        return 'Groupe Intermédiaire';
      case RunningGroup.group4:
      case RunningGroup.group5:
        return 'Groupe Avancé';
    }
  }
}
