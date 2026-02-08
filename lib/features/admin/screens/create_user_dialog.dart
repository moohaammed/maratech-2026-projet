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
  @override
  Widget build(BuildContext context) {
    // Fixed dark theme colors
    const bgColor = Color(0xFF1E1E2C);
    const inputColor = Color(0xFF2A2A35);
    const textColor = Colors.white;
    const hintColor = Colors.grey;

    return Dialog(
      backgroundColor: bgColor,
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
                const SizedBox(height: 12),
                
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
                const SizedBox(height: 12),
                
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
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _pinController,
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'PIN (3 chiffres)', 
                    labelStyle: const TextStyle(color: hintColor),
                    prefixIcon: const Icon(Icons.lock, color: hintColor),
                    filled: true,
                    fillColor: inputColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  maxLength: 3,
                  validator: (v) => v!.length == 3 ? null : '3 chiffres',
                ),
                const SizedBox(height: 24),
                
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
                  items: _getRoleItems(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                
                if (!widget.isAdminMode) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RunningGroup>(
                    dropdownColor: inputColor,
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Groupe (Classique)',
                      labelStyle: const TextStyle(color: hintColor),
                      prefixIcon: const Icon(Icons.group, color: hintColor),
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
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler', style: TextStyle(color: hintColor)),
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
    const textColor = Colors.white;
    if (widget.isAdminMode) {
      return [
        const DropdownMenuItem(value: UserRole.mainAdmin, child: Text('Admin Principal', style: TextStyle(color: textColor))),
        const DropdownMenuItem(value: UserRole.coachAdmin, child: Text('Admin Coach', style: TextStyle(color: textColor))),
        const DropdownMenuItem(value: UserRole.groupAdmin, child: Text('Admin Groupe', style: TextStyle(color: textColor))),
      ];
    } else {
      return [
        const DropdownMenuItem(value: UserRole.member, child: Text('Adhérent', style: TextStyle(color: textColor))),
        const DropdownMenuItem(value: UserRole.visitor, child: Text('Visiteur', style: TextStyle(color: textColor))),
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
