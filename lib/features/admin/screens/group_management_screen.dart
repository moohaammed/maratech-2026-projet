import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import 'create_group_dialog.dart';

class GroupManagementScreen extends StatefulWidget {
  final String? adminId;
  const GroupManagementScreen({super.key, this.adminId});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.group_add),
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: widget.adminId != null 
          ? _groupService.getGroupsByAdmin(widget.adminId!)
          : _groupService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('Aucun groupe créé pour le moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(groups[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Row(
          children: [
            _buildLevelBadge(group.level),
            const SizedBox(width: 8),
            Text('${group.memberIds.length} membres', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        children: [
          StreamBuilder<List<UserModel>>(
            stream: _groupService.getGroupMembers(group.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final members = snapshot.data!;
              return Column(
                children: [
                  ...members.map((member) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(member.fullName.isNotEmpty ? member.fullName[0] : '?'),
                    ),
                    title: Text(member.fullName),
                    subtitle: Text(member.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _groupService.removeMemberFromGroup(group.id, member.id),
                    ),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddMemberDialog(context, group),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un membre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteGroup(group),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Supprimer le groupe', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(GroupLevel level) {
    Color color;
    String label;
    switch (level) {
      case GroupLevel.beginner: color = Colors.green; label = 'Débutant'; break;
      case GroupLevel.intermediate: color = Colors.orange; label = 'Intermédiaire'; break;
      case GroupLevel.advanced: color = Colors.red; label = 'Avancé'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const CreateGroupDialog());
  }

  void _showAddMemberDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(group: group, groupService: _groupService, userService: _userService),
    );
  }

  void _deleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe ?'),
        content: Text('Voulez-vous vraiment supprimer le groupe "${group.name}" ? Les membres seront retirés du groupe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              _groupService.deleteGroup(group.id, group.memberIds);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddMemberDialog extends StatefulWidget {
  final GroupModel group;
  final GroupService groupService;
  final UserService userService;
  const AddMemberDialog({super.key, required this.group, required this.groupService, required this.userService});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            const Text('Ajouter un Membre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Rechercher par nom ou email', prefixIcon: Icon(Icons.search)),
              onChanged: (val) => setState(() => _search = val.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: widget.userService.getAllUsersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final availableUsers = snapshot.data!.where((u) {
                    final matchesSearch = u.fullName.toLowerCase().contains(_search) || u.email.toLowerCase().contains(_search);
                    final notInGroup = u.assignedGroupId != widget.group.id;
                    final isMember = u.role == UserRole.member;
                    return matchesSearch && notInGroup && isMember;
                  }).toList();

                  if (availableUsers.isEmpty) return const Center(child: Text('Aucun adhérent trouvé.'));

                  return ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?'),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.assignedGroupId != null ? 'Déjà dans un autre groupe' : 'Sans groupe'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onPressed: () {
                            widget.groupService.addMemberToGroup(widget.group.id, user.id);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
