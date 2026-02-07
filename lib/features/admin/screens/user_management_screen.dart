import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'create_user_dialog.dart';
import 'edit_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  final String? filterGroupId;
  final RunningGroup? filterGroup;
  final bool readOnly;

  const UserManagementScreen({
    super.key, 
    this.filterGroupId,
    this.filterGroup,
    this.readOnly = false,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.readOnly ? null : FloatingActionButton(
        onPressed: () => _showCreateUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                
                final users = snapshot.data ?? [];
                final filteredUsers = users.where((user) {
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = (user.fullName.toLowerCase().contains(query) ||
                          user.email.toLowerCase().contains(query));
                  
                  bool matchesGroup = true;
                  if (widget.filterGroupId != null) {
                    matchesGroup = user.assignedGroupId == widget.filterGroupId;
                  } else if (widget.filterGroup != null) {
                    matchesGroup = user.assignedGroup == widget.filterGroup;
                  }

                  final isMemberOrVisitor = (user.role == UserRole.member || user.role == UserRole.visitor);
                  
                  return matchesSearch && matchesGroup && isMemberOrVisitor;
                }).toList();
                
                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('Aucun utilisateur trouvé', 
                      style: TextStyle(color: AppColors.textSecondary)
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildRoleBadge(user.role),
                                const SizedBox(width: 8),
                                _buildGroupBadge(user),
                                const SizedBox(width: 8),
                                if (!user.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Inactif', 
                                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: widget.readOnly ? null : PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(
                              value: 'toggle', 
                              child: Text(user.isActive ? 'Désactiver' : 'Activer')
                            ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Text('Supprimer', style: TextStyle(color: Colors.red))
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') _showEditUserDialog(user);
                            if (value == 'toggle') _userService.toggleUserStatus(user.id, !user.isActive);
                            if (value == 'delete') _deleteUser(user);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    String label;
    
    switch (role) {
      case UserRole.member:
        color = AppColors.info;
        label = 'Adhérent';
        break;
      case UserRole.visitor:
      default:
        color = Colors.grey;
        label = 'Visiteur';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGroupBadge(UserModel user) {
    if (user.assignedGroupId == null && user.assignedGroup == null) return const SizedBox.shrink();
    
    final label = user.getGroupDisplayName();
    final isDynamic = user.assignedGroupId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isDynamic ? Colors.purple : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (isDynamic ? Colors.purple : Colors.orange).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDynamic ? Colors.purple : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateUserDialog(isAdminMode: false),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: user, isAdminMode: false),
    );
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${user.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
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
