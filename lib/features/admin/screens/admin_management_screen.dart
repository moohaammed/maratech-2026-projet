import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'create_user_dialog.dart';
import 'edit_user_dialog.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final UserService _userService = UserService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAdminDialog(context),
        backgroundColor: AppColors.error, // Red for Admin
        child: const Icon(Icons.add_moderator),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _userService.getAllUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          
          final users = snapshot.data ?? [];
          final admins = users.where((user) => 
            user.role == UserRole.mainAdmin || 
            user.role == UserRole.coachAdmin ||
            user.role == UserRole.groupAdmin
          ).toList();
          
          if (admins.isEmpty) {
            return const Center(child: Text('Aucun administrateur'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(admin.role).withOpacity(0.1),
                    child: Icon(Icons.security, color: _getRoleColor(admin.role)),
                  ),
                  title: Text(admin.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_getRoleLabel(admin.role)),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') _showEditAdminDialog(context, admin);
                      if (value == 'delete') _deleteUser(context, admin);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.mainAdmin: return AppColors.error;
      case UserRole.coachAdmin: return AppColors.primary;
      case UserRole.groupAdmin: return AppColors.info;
      default: return Colors.grey;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.mainAdmin: return 'Admin Principal';
      case UserRole.coachAdmin: return 'Admin Coach';
      case UserRole.groupAdmin: return 'Admin Groupe';
      default: return 'Admin';
    }
  }

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateUserDialog(isAdminMode: true),
    );
  }

  void _showEditAdminDialog(BuildContext context, UserModel admin) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: admin, isAdminMode: true),
    );
  }

  void _deleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'admin ${user.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              _userService.deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
