import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'create_group_dialog.dart';
import 'group_management_screen.dart'; // We can still reuse AddMemberDialog or custom components

class GroupAdminDashboard extends StatefulWidget {
  final UserModel currentUser;

  const GroupAdminDashboard({super.key, required this.currentUser});

  @override
  State<GroupAdminDashboard> createState() => _GroupAdminDashboardState();
}

class _GroupAdminDashboardState extends State<GroupAdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responsable de Groupe', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Gestion des entraînements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'Mes Groupes', icon: Icon(Icons.group_work)),
            Tab(text: 'Affecter Membres', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildMembersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Groupe'),
      ),
    );
  }

  Widget _buildGroupsTab() {
    return StreamBuilder<List<GroupModel>>(
      stream: _groupService.getGroupsByAdmin(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildEmptyState('Aucun groupe', 'Commencez par créer un groupe pour votre niveau.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) => _buildGroupCard(groups[index]),
        );
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getLevelColor(group.level),
                  child: const Icon(Icons.groups, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      _buildLevelBadge(group.level),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteGroup(group),
                ),
              ],
            ),
          ),
          StreamBuilder<List<UserModel>>(
            stream: _groupService.getGroupMembers(group.id),
            builder: (context, snapshot) {
              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucun membre dans ce groupe', style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: [
                  ...members.map((m) => ListTile(
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.info.withOpacity(0.1),
                      child: Text(m.fullName[0], style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(m.fullName, style: const TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined, size: 20, color: Colors.orange),
                      onPressed: () => _groupService.removeMemberFromGroup(group.id, m.id),
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.info.withOpacity(0.1),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voici la liste des adhérents sans groupe ou en attente d\'affectation.',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _userService.getAllUsersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final members = snapshot.data!.where((u) => 
                u.role == UserRole.member && u.assignedGroupId == null
              ).toList();

              if (members.isEmpty) {
                return _buildEmptyState('Tous affectés !', 'Tous les adhérents ont déjà un groupe.');
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final user = members[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(user.fullName[0])),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _showAssignDialog(user),
                        child: const Text('Affecter'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignDialog(UserModel user) async {
    final groups = await _groupService.getGroupsByAdmin(widget.currentUser.id).first;
    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez d\'abord créer un groupe.'))
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Affecter ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: groups.map((g) => ListTile(
              title: Text(g.name),
              subtitle: Text(_getLevelLabel(g.level)),
              onTap: () {
                _groupService.addMemberToGroup(g.id, user.id);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(GroupLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getLevelLabel(level),
        style: TextStyle(color: _getLevelColor(level), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getLevelColor(GroupLevel level) {
    switch (level) {
      case GroupLevel.beginner: return Colors.green;
      case GroupLevel.intermediate: return Colors.orange;
      case GroupLevel.advanced: return Colors.red;
    }
  }

  String _getLevelLabel(GroupLevel level) {
    switch (level) {
      case GroupLevel.beginner: return 'Débutant';
      case GroupLevel.intermediate: return 'Intermédiaire';
      case GroupLevel.advanced: return 'Avancé';
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const CreateGroupDialog());
  }

  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe ?'),
        content: Text('Voulez-vous vraiment supprimer "${group.name}" ?'),
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
