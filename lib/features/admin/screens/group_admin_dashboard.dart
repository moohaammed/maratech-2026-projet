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
import 'dart:ui'; // For glassmorphism

/// Premium Group Admin Dashboard with stunning visuals
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
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final cardColor = highContrast ? AppColors.highContrastSurface : const Color(0xFF16161F);

    return StreamBuilder<List<GroupModel>>(
      stream: _groupService.getGroupsStream(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        final hasGroup = groups.isNotEmpty;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Background Accents
              if (!highContrast) ...[
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [primaryColor.withOpacity(0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.secondary.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],

              // Content
              SafeArea(
                child: NestedScrollView(
                  physics: const BouncingScrollPhysics(),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 220 * textScale.clamp(1.0, 1.1),
                        pinned: true,
                        backgroundColor: highContrast ? Colors.black : Colors.transparent,
                        elevation: 0,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildHeader(primaryColor, textScale),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(70),
                          child: _buildTabBar(primaryColor, textScale, highContrast),
                        ),
                        actions: [
                          _buildAppBarAction(Icons.logout_rounded, () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                await Provider.of<AccessibilityProvider>(context, listen: false).logoutAndRestoreLocalProfile();
                                if (mounted) Navigator.pushReplacementNamed(context, '/login');
                              }
                          }, AppColors.error, isLogout: true),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupsTab(groups, textScale, highContrast, primaryColor, cardColor),
                      _buildMembersTab(groups, textScale, highContrast, primaryColor, cardColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: hasGroup 
            ? null 
            : ScaleTransition(
                scale: _pulseAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () => showDialog(context: context, builder: (context) => const CreateGroupDialog()),
                  backgroundColor: primaryColor,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text('Créer Groupe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                  elevation: 4,
                ),
              ),
        );
      }
    );
  }

  Widget _buildTabBar(Color primaryColor, double textScale, bool highContrast) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highContrast ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)]),
          boxShadow: [
            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * textScale),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
           Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_work_rounded, size: 20),
                SizedBox(width: 8),
                Text('Mes Groupes'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_rounded, size: 20),
                SizedBox(width: 8),
                Text('Affectation'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, double textScale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 60 * textScale.clamp(1.0, 1.2), 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espace Gestion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22 * textScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Administrez vos groupes',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13 * textScale,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, Color color, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogout ? AppColors.error.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isLogout ? AppColors.error.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: isLogout ? AppColors.error : Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGroupsTab(List<GroupModel> groups, double textScale, bool highContrast, Color primaryColor, Color cardColor) {
    if (groups.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildGroupCard(groups[index], textScale, highContrast, primaryColor, cardColor),
      );
    }

    // Empty state logic (claiming groups) remains similar but styled better
    return FutureBuilder<List<GroupModel>>(
      future: _groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Filter for legacy IDs: 'beginner', 'intermediate', 'advanced' AND '1', '2', '3', '4'
        final claimable = snapshot.data!.where((g) {
          final id = g.id.toLowerCase();
          return ['beginner', 'intermediate', 'advanced', '1', '2', '3', '4'].contains(id);
        }).toList();

        if (claimable.isEmpty) return _buildEmptyState('Aucun groupe disponible', Icons.group_off_rounded);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.assignment_ind_rounded, size: 60, color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  "Choisissez votre groupe",
                  style: TextStyle(fontSize: 22 * textScale, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ...claimable.map((g) => _buildClaimGroupCard(g, primaryColor, textScale)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimGroupCard(GroupModel g, Color primaryColor, double textScale) {
    // Custom mapping for legacy numeric names to friendly names
    String displayName = g.name;
    if (['1', '2'].contains(g.id)) displayName = "Groupe Débutant (${g.id})";
    if (['3'].contains(g.id)) displayName = "Groupe Intermédiaire (${g.id})";
    if (['4'].contains(g.id)) displayName = "Groupe Avancé (${g.id})";
    // Also map if the name itself is just a number
    if (g.name == '1' || g.name == '2') displayName = "Débutant";
    if (g.name == '3') displayName = "Intermédiaire";
    if (g.name == '4') displayName = "Avancé";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _confirmClaimGroup(g),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16161F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getLevelColor(g.level).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: _getLevelColor(g.level).withOpacity(0.1), blurRadius: 12),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLevelColor(g.level).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_rounded, color: _getLevelColor(g.level), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: TextStyle(color: Colors.white, fontSize: 16 * textScale, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_getLevelLabel(g.level), style: TextStyle(color: Colors.grey[500], fontSize: 12 * textScale), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClaimGroup(GroupModel group) {
      // (Keep existing logic, just update dialog style if needed)
      // For brevity, using standard dialog but could be customized
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: Text("Gérer ${group.name} ?", style: const TextStyle(color: Colors.white)),
          content: const Text("Vous deviendrez le responsable de ce groupe.", style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(context);
                await _groupService.assignGroupToAdmin(group.id, widget.currentUser.id);
              },
              child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
  }

  Widget _buildGroupCard(GroupModel group, double textScale, bool highContrast, Color primaryColor, Color cardColor) {
    Color levelColor = _getLevelColor(group.level);
    
    // Determine friendly name for display if it's one of the legacy groups
    String displayName = group.name;
    if (['1', '2'].contains(group.id) || group.name == '1' || group.name == '2') displayName = "Groupe Débutant";
    if (['3'].contains(group.id) || group.name == '3') displayName = "Groupe Intermédiaire";
    if (['4'].contains(group.id) || group.name == '4') displayName = "Groupe Avancé";

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelColor.withOpacity(0.15), levelColor.withOpacity(0.02)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: levelColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(color: Colors.white, fontSize: 18 * textScale, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getLevelLabel(group.level).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                  onPressed: () => _showDeleteConfirmDialog(group),
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
                  padding: const EdgeInsets.all(24),
                  child: Text('Aucun membre inscrit', style: TextStyle(color: Colors.grey[600])),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: members.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final m = members[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: levelColor.withOpacity(0.1),
                      child: Text(m.fullName.isNotEmpty ? m.fullName[0] : '?', style: TextStyle(color: levelColor)),
                    ),
                    title: Text(m.fullName, style: TextStyle(color: Colors.grey[200], fontSize: 14 * textScale), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                       icon: const Icon(Icons.remove_circle_outline, color: AppColors.warning, size: 20),
                       onPressed: () => _groupService.removeMemberFromGroup(group.id, m.id),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmDialog(GroupModel group) {
      // Implementation of delete confirmation
      showDialog(context: context, builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Supprimer ce groupe ?', style: TextStyle(color: Colors.white)),
          content: Text('Cette action est irréversible. Les membres seront désassignés.', style: TextStyle(color: Colors.grey[400])),
          actions: [
             TextButton(child: const Text('Annuler'), onPressed: () => Navigator.pop(context)),
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
               child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
               onPressed: () {
                 _groupService.deleteGroup(group.id, group.memberIds);
                 Navigator.pop(context);
               }
             )
          ]
      ));
  }

  Widget _buildMembersTab(List<GroupModel> groups, double textScale, bool highContrast, Color primaryColor, Color cardColor) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Adhérents en attente d\'affectation',
                  style: TextStyle(color: Colors.grey[300], fontSize: 13 * textScale),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _userService.getAllUsersStream(),
            builder: (context, snapshot) {
              final members = (snapshot.data ?? []).where((u) => u.role == UserRole.member && u.assignedGroupId == null).toList();
              
              if (members.isEmpty) return _buildEmptyState('Tous les membres ont un groupe', Icons.check_circle_outline_rounded);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: members.length,
                itemBuilder: (context, index) {
                   final user = members[index];
                   return Container(
                     margin: const EdgeInsets.only(bottom: 12),
                     decoration: BoxDecoration(
                       color: cardColor,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.white.withOpacity(0.05)),
                     ),
                     child: ListTile(
                       contentPadding: const EdgeInsets.all(12),
                       leading: CircleAvatar(
                         backgroundColor: primaryColor.withOpacity(0.1),
                         child: Icon(Icons.person_outline_rounded, color: primaryColor),
                       ),
                       title: Text(user.fullName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15 * textScale), maxLines: 1, overflow: TextOverflow.ellipsis),
                       subtitle: Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 12 * textScale), maxLines: 1, overflow: TextOverflow.ellipsis),
                       trailing: IconButton(
                         icon: const Icon(Icons.group_add_rounded, color: AppColors.success),
                         onPressed: () {
                           // Show assign dialog
                            if (groups.isNotEmpty) {
                              _showAssignMemberDialog(user, groups);
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun groupe disponible')));
                            }
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
    );
  }

  void _showAssignMemberDialog(UserModel user, List<GroupModel> groups) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text('Affecter ${user.fullName}', style: const TextStyle(color: Colors.white)),
        children: groups.map((g) => SimpleDialogOption(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Text(g.name, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          onPressed: () {
            _groupService.addMemberToGroup(g.id, user.id);
            Navigator.pop(context);
          },
        )).toList(),
      )
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Color _getLevelColor(GroupLevel level) {
    switch (level) {
      case GroupLevel.beginner: return AppColors.beginner;
      case GroupLevel.intermediate: return AppColors.intermediate;
      case GroupLevel.advanced: return AppColors.advanced;
    }
  }

  String _getLevelLabel(GroupLevel level) {
    switch (level) {
      case GroupLevel.beginner: return 'Débutant';
      case GroupLevel.intermediate: return 'Intermédiaire';
      case GroupLevel.advanced: return 'Avancé';
    }
  }
}
