import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Créer un Nouveau Groupe',
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
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GroupLevel>(
                value: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau',
                  prefixIcon: Icon(Icons.signal_cellular_alt),
                ),
                items: const [
                  DropdownMenuItem(value: GroupLevel.beginner, child: Text('Débutant / Beginner')),
                  DropdownMenuItem(value: GroupLevel.intermediate, child: Text('Intermédiaire / Intermediate')),
                  DropdownMenuItem(value: GroupLevel.advanced, child: Text('Avancé / Advanced')),
                ],
                onChanged: (val) => setState(() => _selectedLevel = val!),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      await _groupService.createGroup(
        _nameController.text.trim(),
        _selectedLevel,
        adminId,
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
