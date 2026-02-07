import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
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
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.info;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : Colors.white;

    return StreamBuilder<List<GroupModel>>(
      stream: _getEffectiveGroupsStream(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        final hasGroup = groups.isNotEmpty;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Responsable de Groupe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: (18 * textScale).toDouble())),
                Text('Gestion des entraînements - RCT', style: TextStyle(fontSize: (12 * textScale).toDouble(), fontWeight: FontWeight.normal)),
              ],
            ),
            backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
            foregroundColor: highContrast ? primaryColor : Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    await Provider.of<AccessibilityProvider>(context, listen: false).logoutAndRestoreLocalProfile();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: highContrast ? primaryColor : Colors.white,
              indicatorWeight: 4,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: (15 * textScale).toDouble()),
              tabs: const [
                Tab(text: 'Mes Groupes', icon: Icon(Icons.group_work)),
                Tab(text: 'Affecter Membres', icon: Icon(Icons.person_add)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGroupsTab(groups, textScale, highContrast, primaryColor),
              _buildMembersTab(groups, textScale, highContrast, primaryColor),
            ],
          ),
          floatingActionButton: hasGroup 
            ? null 
            : FloatingActionButton.extended(
                onPressed: () => _showCreateGroupDialog(context),
                backgroundColor: primaryColor,
                foregroundColor: highContrast ? Colors.black : Colors.white,
                icon: const Icon(Icons.add),
                label: Text('Nouveau Groupe', style: TextStyle(fontSize: (14 * textScale).toDouble())),
              ),
        );
      }
    );
  }

  Stream<List<GroupModel>> _getEffectiveGroupsStream() {
    // Return ALL groups so Group Admin can see and manage all of them
    return _groupService.getGroupsStream();
  }

  Widget _buildGroupsTab(List<GroupModel> groups, double textScale, bool highContrast, Color primaryColor) {
    if (groups.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) => _buildGroupCard(groups[index], textScale, highContrast, primaryColor),
      );
    }

    // Empty state: Fetch available legacy groups for claiming
    return FutureBuilder<List<GroupModel>>(
      future: _groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Check for errors
        if (snapshot.hasError) {
          print('ERROR in FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        
        final allGroups = snapshot.data ?? [];
        print('DEBUG: Dashboard - allGroups count: ${allGroups.length}');
        print('DEBUG: Dashboard - allGroups IDs: ${allGroups.map((g) => g.id).toList()}');
        // Filter for specific legacy IDs
        final claimable = allGroups.where((g) => 
          ['beginner', 'intermediate', 'advanced'].contains(g.id)
        ).toList();
        print('DEBUG: Dashboard - claimable count: ${claimable.length}');

        if (claimable.isEmpty) {
          return _buildEmptyState('Aucun groupe', 'Contactez l\'administrateur.');
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  "Sélectionnez votre groupe", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                ),
                const SizedBox(height: 8),
                const Text(
                  "Veuillez choisir le groupe que vous allez gérer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ...claimable.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: _getLevelColor(g.level).withOpacity(0.5), width: 2),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _confirmClaimGroup(g),
                      child: Row(
                        children: [
                          Icon(Icons.groups_rounded, color: _getLevelColor(g.level), size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(_getLevelLabel(g.level), style: TextStyle(color: _getLevelColor(g.level), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClaimGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Gérer le groupe ${group.name} ?"),
        content: const Text("Vous serez assigné comme responsable de ce groupe. Cette action est immédiate."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                // Assign to self
                await _groupService.assignGroupToAdmin(group.id, widget.currentUser.id);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vous gérez maintenant ${group.name} !")));
                }
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            },
            child: const Text("Avancé"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group, double textScale, bool highContrast, Color primaryColor) {
    Color levelColor = _getLevelColor(group.level);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: highContrast ? AppColors.highContrastSurface : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: highContrast ? null : [
          BoxShadow(
            color: levelColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: highContrast ? levelColor : Colors.white.withOpacity(0.1), width: highContrast ? 2 : 1),
      ),
      child: Column(
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: highContrast ? null : LinearGradient(
                colors: [levelColor.withOpacity(0.1), levelColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: highContrast ? Colors.black26 : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * textScale.clamp(1.0, 1.2)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.groups_rounded, color: levelColor, size: 28 * textScale.clamp(1.0, 1.2)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getLevelLabel(group.level).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _confirmDeleteGroup(group),
                  tooltip: "Supprimer le groupe",
                ),
              ],
            ),
          ),
          
          // Members List
          StreamBuilder<List<UserModel>>(
            stream: _groupService.getGroupMembers(group.id),
            builder: (context, snapshot) {
              final members = snapshot.data ?? [];
              
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.person_add_disabled_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      const Text(
                        'Aucun membre', 
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final m = members[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: levelColor.withOpacity(0.1),
                      child: Text(
                        m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                        style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined, size: 20, color: Colors.orange),
                      onPressed: () => _groupService.removeMemberFromGroup(group.id, m.id),
                      tooltip: "Retirer du groupe",
                    ),
                  );
                },
              );
            },
          ),
          
          // Footer / Divider
          if (group.memberIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text(
                "${group.memberIds.length} Membre(s)",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(List<GroupModel> groups, double textScale, bool highContrast, Color primaryColor) {
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.group_add_rounded, color: AppColors.primary),
                          onPressed: () => _showAssignDialog(user, groups),
                          tooltip: 'Affecter à un groupe',
                        ),
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

  void _showAssignDialog(UserModel user, List<GroupModel> groups) {
    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez d\'abord créer un groupe.'))
        );
      }
      return;
    }

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
