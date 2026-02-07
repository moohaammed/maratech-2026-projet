import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create a new group
  Future<String> createGroup(String name, GroupLevel level, String? adminId) async {
    final docRef = await _groupsCollection.add({
      'name': name,
      'level': level.toString(),
      'adminId': adminId,
      'memberIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Stream all groups (for Main Admin)
  Stream<List<GroupModel>> getGroupsStream() {
    return _groupsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  // Stream groups for a specific admin (for Group Admin)
  Stream<List<GroupModel>> getGroupsByAdmin(String adminId) {
    return _groupsCollection
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  // Add a member to a group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    final batch = _firestore.batch();

    // 1. Update group members list
    batch.update(_groupsCollection.doc(groupId), {
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // 2. Update user's assigned group ID
    batch.update(_usersCollection.doc(userId), {
      'assignedGroupId': groupId,
    });

    await batch.commit();
  }

  // Remove a member from a group
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final batch = _firestore.batch();

    // 1. Update group members list
    batch.update(_groupsCollection.doc(groupId), {
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    // 2. Clear user's assigned group ID
    batch.update(_usersCollection.doc(userId), {
      'assignedGroupId': null,
    });

    await batch.commit();
  }

  // Get members of a specific group
  Stream<List<UserModel>> getGroupMembers(String groupId) {
    return _usersCollection
        .where('assignedGroupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Delete a group
  Future<void> deleteGroup(String groupId, List<String> memberIds) async {
    final batch = _firestore.batch();

    // 1. Reset assignedGroupId for all members
    for (var userId in memberIds) {
      batch.update(_usersCollection.doc(userId), {'assignedGroupId': null});
    }

    // 2. Delete the group document
    batch.delete(_groupsCollection.doc(groupId));

    await batch.commit();
  }
  // Update Group Admin
  Future<void> updateGroupAdmin(String groupId, String newAdminId) async {
    await _groupsCollection.doc(groupId).update({'adminId': newAdminId});
  }

  // Check if group exists
  Future<bool> checkGroupExists(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    return doc.exists;
  }

  // Stream a single group by ID
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc);
    });
  }

  // Get all groups (Future)
  Future<List<GroupModel>> getAllGroups() async {
    final snapshot = await _groupsCollection.get();
    return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
  }

  // Assign group to admin (claim)
  Future<void> assignGroupToAdmin(String groupId, String adminId) async {
    final batch = _firestore.batch();
    
    // 1. Update group adminId
    batch.update(_groupsCollection.doc(groupId), {'adminId': adminId});
    
    // 2. Update user assignedGroupId
    batch.update(_firestore.collection('users').doc(adminId), {'assignedGroupId': groupId});
    
    await batch.commit();
  }
}
