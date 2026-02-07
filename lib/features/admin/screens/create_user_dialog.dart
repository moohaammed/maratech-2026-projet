import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserDialog extends StatefulWidget {
  final bool isAdminMode;

  const CreateUserDialog({super.key, this.isAdminMode = false});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  UserRole _selectedRole = UserRole.member;
  RunningGroup? _selectedGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.isAdminMode ? UserRole.mainAdmin : UserRole.member;
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
                  widget.isAdminMode ? 'Créer un Admin' : 'Créer un Membre',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v!.contains('@') ? null : 'Invalide',
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(labelText: 'PIN (3 chiffres)', prefixIcon: Icon(Icons.lock)),
                  maxLength: 3,
                  validator: (v) => v!.length == 3 ? null : '3 chiffres',
                ),
                const SizedBox(height: 24),
                
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: _getRoleItems(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                
                if (!widget.isAdminMode) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RunningGroup>(
                    decoration: const InputDecoration(
                      labelText: 'Groupe (Classique)',
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: RunningGroup.values.map((g) => DropdownMenuItem(
                      value: g, 
                      child: Text('Groupe ${g.toString().split('.').last.replaceAll('group', '')}')
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedGroup = val),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isAdminMode ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Créer'),
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

  List<DropdownMenuItem<UserRole>> _getRoleItems() {
    if (widget.isAdminMode) {
      return [
        const DropdownMenuItem(value: UserRole.mainAdmin, child: Text('Admin Principal')),
        const DropdownMenuItem(value: UserRole.coachAdmin, child: Text('Admin Coach')),
        const DropdownMenuItem(value: UserRole.groupAdmin, child: Text('Admin Groupe')),
      ];
    } else {
      return [
        const DropdownMenuItem(value: UserRole.member, child: Text('Adhérent')),
        const DropdownMenuItem(value: UserRole.visitor, child: Text('Visiteur')),
      ];
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: "000${_pinController.text.trim()}",
      );
      
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = UserModel(
        id: uid,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        cinLastDigits: _pinController.text.trim(),
        role: _selectedRole,
        assignedGroup: _selectedGroup,
        createdAt: DateTime.now(),
        permissions: UserModel.getDefaultPermissions(_selectedRole),
      );
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set(user.toFirestore());
      
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
