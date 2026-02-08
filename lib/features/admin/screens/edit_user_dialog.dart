import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final bool isAdminMode;

  const EditUserDialog({super.key, required this.user, this.isAdminMode = false});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late UserRole _selectedRole;
  RunningGroup? _selectedGroup;
  late Map<String, bool> _permissions;
  bool _isLoading = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedRole = widget.user.role;
    _selectedGroup = widget.user.assignedGroup;
    _permissions = Map<String, bool>.from(widget.user.permissions);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1E1E2C);
    
    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Text(
              'Modifier l\'utilisateur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Infos'),
                Tab(text: 'Rôle'),
                Tab(text: 'Permissions'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildRoleTab(),
                  _buildPermissionsTab(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    const inputColor = Color(0xFF2A2A35);
    const textColor = Colors.white;
    const hintColor = Colors.grey;
    
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Nom complet', 
              labelStyle: const TextStyle(color: hintColor),
              prefixIcon: const Icon(Icons.person, color: hintColor),
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Email', 
              labelStyle: const TextStyle(color: hintColor),
              prefixIcon: const Icon(Icons.email, color: hintColor),
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            validator: (v) => v!.contains('@') ? null : 'Invalide',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Téléphone', 
              labelStyle: const TextStyle(color: hintColor),
              prefixIcon: const Icon(Icons.phone, color: hintColor),
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab() {
    const inputColor = Color(0xFF2A2A35);
    const textColor = Colors.white;
    const hintColor = Colors.grey;

    return ListView(
      children: [
        DropdownButtonFormField<UserRole>(
          value: _selectedRole,
          dropdownColor: inputColor,
          style: const TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Rôle',
            labelStyle: const TextStyle(color: hintColor),
            filled: true,
            fillColor: inputColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          items: widget.isAdminMode 
            ? [
                const DropdownMenuItem(value: UserRole.mainAdmin, child: Text('Admin Principal', style: TextStyle(color: textColor))),
                const DropdownMenuItem(value: UserRole.coachAdmin, child: Text('Admin Coach', style: TextStyle(color: textColor))),
                const DropdownMenuItem(value: UserRole.groupAdmin, child: Text('Admin Groupe', style: TextStyle(color: textColor))),
              ]
            : [
                const DropdownMenuItem(value: UserRole.member, child: Text('Adhérent', style: TextStyle(color: textColor))),
                const DropdownMenuItem(value: UserRole.visitor, child: Text('Visiteur', style: TextStyle(color: textColor))),
              ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
              _permissions = UserModel.getDefaultPermissions(_selectedRole);
            });
          },
        ),
        const SizedBox(height: 16),
        if (!widget.isAdminMode)
          DropdownButtonFormField<RunningGroup>(
            value: _selectedGroup,
            dropdownColor: inputColor,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Groupe',
              labelStyle: const TextStyle(color: hintColor),
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            items: RunningGroup.values.map((g) => DropdownMenuItem(
              value: g, 
              child: Text('Groupe ${g.toString().split('.').last.replaceAll('group', '')}', style: const TextStyle(color: textColor))
            )).toList(),
            onChanged: (val) => setState(() => _selectedGroup = val),
          ),
      ],
    );
  }

  Widget _buildPermissionsTab() {
    const textColor = Colors.white;
    
    return ListView(
      children: _permissions.keys.map((key) {
        return CheckboxListTile(
          title: Text(_getPermissionLabel(key), style: const TextStyle(color: textColor)),
          value: _permissions[key],
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          onChanged: (val) => setState(() => _permissions[key] = val!),
        );
      }).toList(),
    );
  }

  String _getPermissionLabel(String key) {
    switch (key) {
      case 'manageUsers': return 'Gérer les utilisateurs';
      case 'manageAdmins': return 'Gérer les admins';
      case 'managePermissions': return 'Gérer les permissions';
      case 'createEvents': return 'Créer des événements';
      case 'deleteEvents': return 'Supprimer des événements';
      case 'viewHistory': return 'Voir l\'historique';
      case 'sendNotifications': return 'Envoyer des notifications';
      case 'manageGroups': return 'Gérer les groupes';
      case 'viewStatistics': return 'Voir les statistiques';
      default: return key;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        assignedGroup: _selectedGroup,
        permissions: _permissions,
      );

      await _userService.updateUser(widget.user.id, updatedUser);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
