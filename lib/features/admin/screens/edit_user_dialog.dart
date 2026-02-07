import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final bool isAdminMode;

  const EditUserDialog({super.key, required this.user, required this.isAdminMode});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final UserService _userService = UserService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late UserRole _selectedRole;
  late Map<String, bool> _permissions;
  bool _isLoading = false;

  final List<String> _allPermissionKeys = [
    'manageUsers', 'manageAdmins', 'managePermissions',
    'createEvents', 'deleteEvents', 'viewHistory',
    'sendNotifications', 'manageGroups', 'viewStatistics'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role;
    
    // Initialize permissions with all keys, defaulting to false if ensuring they exist
    _permissions = {};
    for (var key in _allPermissionKeys) {
      _permissions[key] = widget.user.permissions[key] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DefaultTabController(
        length: 2,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isAdminMode ? AppColors.error : AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Modifier ${widget.user.fullName}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const TabBar(
                labelColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Infos & Rôle'),
                  Tab(text: 'Permissions'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(),
                    _buildPermissionsTab(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isAdminMode ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom complet')),
          const SizedBox(height: 12),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Rôle'),
            items: UserRole.values.map((role) {
              return DropdownMenuItem(value: role, child: Text(role.toString().split('.').last));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedRole = val!;
                _permissions = UserModel.getDefaultPermissions(val);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _permissions.entries.map((entry) {
        return SwitchListTile(
          title: Text(entry.key),
          value: entry.value,
          onChanged: (val) => setState(() => _permissions[entry.key] = val),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = widget.user.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        permissions: _permissions,
      );
      await _userService.updateUser(widget.user.id, updatedUser);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
