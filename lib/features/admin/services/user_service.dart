import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Stream all users
  Stream<List<UserModel>> getAllUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _usersCollection
        .where('role', isEqualTo: role.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get users by group
  Stream<List<UserModel>> getUsersByGroup(RunningGroup group) {
    return _usersCollection
        .where('assignedGroup', isEqualTo: group.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get single user
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // Create new user
  Future<String> createUser(UserModel user, String password) async {
    try {
      // Create authentication user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      await _usersCollection.doc(userId).set(user.toFirestore());

      return userId;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Update user
  Future<void> updateUser(String userId, UserModel updatedUser) async {
    try {
      await _usersCollection.doc(userId).update(updatedUser.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _usersCollection.doc(userId).delete();

      // Note: Deleting from Firebase Auth requires re-authentication
      // This should be done with Cloud Functions in production
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          role: newRole,
          permissions: UserModel.getDefaultPermissions(newRole),
        );
        await updateUser(userId, updatedUser);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  // Update user permissions
  Future<void> updateUserPermissions(
      String userId, Map<String, bool> permissions) async {
    try {
      await _usersCollection.doc(userId).update({'permissions': permissions});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des permissions: $e');
    }
  }

  // Assign user to group
  Future<void> assignUserToGroup(String userId, RunningGroup? group) async {
    try {
      await _usersCollection.doc(userId).update({
        'assignedGroup': group?.toString(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'affectation au groupe: $e');
    }
  }

  // Toggle user active status
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _usersCollection.doc(userId).update({'isActive': isActive});
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  // Get statistics
  // Get statistics (One-time)
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _usersCollection.get();
      return _calculateStats(snapshot.docs);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // Get statistics (Real-time Stream)
  Stream<Map<String, int>> getUserStatisticsStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return _calculateStats(snapshot.docs);
    });
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    final users = docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    return {
      'total': users.length,
      'mainAdmins': users.where((u) => u.role == UserRole.mainAdmin).length,
      'coachAdmins': users.where((u) => u.role == UserRole.coachAdmin).length,
      'groupAdmins': users.where((u) => u.role == UserRole.groupAdmin).length,
      'members': users.where((u) => u.role == UserRole.member).length,
      'visitors': users.where((u) => u.role == UserRole.visitor).length,
      'active': users.where((u) => u.isActive).length,
      'inactive': users.where((u) => !u.isActive).length,
    };
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _usersCollection.get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      final lowercaseQuery = query.toLowerCase();
      return users.where((user) {
        return user.fullName.toLowerCase().contains(lowercaseQuery) ||
            user.email.toLowerCase().contains(lowercaseQuery) ||
            user.phone.contains(query);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
