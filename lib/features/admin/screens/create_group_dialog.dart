import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupLevel _selectedLevel = GroupLevel.beginner;
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  bool _isMainAdmin = false;
  List<UserModel> _groupAdmins = [];
  String? _selectedAdminId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserById(uid);
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _isMainAdmin = user.role == UserRole.mainAdmin;
        });

        if (_isMainAdmin) {
          _userService.getUsersByRole(UserRole.groupAdmin).listen((admins) {
            if (mounted) {
              setState(() {
                _groupAdmins = admins;
                // If there's only one, select it by default? Or keep null to force choice.
              });
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isMainAdmin ? 'Créer & Assigner un Groupe' : 'Créer mon Groupe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    prefixIcon: Icon(Icons.group_add),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<GroupLevel>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Niveau',
                    prefixIcon: Icon(Icons.signal_cellular_alt),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: GroupLevel.beginner, child: Text('Débutant')),
                    DropdownMenuItem(value: GroupLevel.intermediate, child: Text('Intermédiaire')),
                    DropdownMenuItem(value: GroupLevel.advanced, child: Text('Avancé')),
                  ],
                  onChanged: (val) => setState(() => _selectedLevel = val!),
                ),
                
                // If Main Admin, show Admin Selection Dropdown
                if (_isMainAdmin && _groupAdmins.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedAdminId,
                    decoration: const InputDecoration(
                      labelText: 'Admin du Groupe (Responsable)',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(),
                    ),
                    items: _groupAdmins.map((admin) => DropdownMenuItem(
                      value: admin.id,
                      child: Text(admin.fullName),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedAdminId = val),
                    validator: (v) => _isMainAdmin && v == null ? 'Veuillez assigner un admin' : null,
                  ),
                ] else if (_isMainAdmin && _groupAdmins.isEmpty) ...[
                   const SizedBox(height: 16),
                   const Text(
                     "Aucun 'Admin Groupe' trouvé. Créez d'abord un utilisateur avec le rôle 'Group Admin'.",
                     style: TextStyle(color: Colors.orange, fontSize: 12),
                   ),
                ],

                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (_isLoading || (_isMainAdmin && _groupAdmins.isEmpty)) 
                        ? null 
                        : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Determine the owner ID
    String? finalAdminId;
    if (_isMainAdmin) {
      finalAdminId = _selectedAdminId; // Selected Group Admin
    } else {
      finalAdminId = _currentUser?.id; // Current User (Group Admin themselves)
    }

    if (finalAdminId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Admin non identifié')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // Check for legacy groups (beginner, intermediate, advanced)
      final legacyId = _selectedLevel.name; // e.g., "beginner"
      final exists = await _groupService.checkGroupExists(legacyId);

      if (exists) {
        if (mounted) {
           // Ask to claim
           bool? claim = await showDialog<bool>(
             context: context,
             builder: (context) => AlertDialog(
               title: const Text("Groupe Existant"),
               content: Text("Un groupe '${legacyId.toUpperCase()}' existe déjà. Voulez-vous prendre le contrôle de ce groupe existant au lieu d'en créer un nouveau ?"),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context, false), // Create New
                   child: const Text("Créer Nouveau"),
                 ),
                 ElevatedButton(
                   onPressed: () => Navigator.pop(context, true), // Claim
                   style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                   child: const Text("Récupérer"),
                 ),
               ],
             ),
           );

           if (claim == true) {
             await _groupService.updateGroupAdmin(legacyId, finalAdminId);
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Groupe récupéré avec succès !')));
               Navigator.pop(context);
             }
             return;
           }
        }
      }

      await _groupService.createGroup(
        _nameController.text.trim(),
        _selectedLevel,
        finalAdminId,
      );
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
