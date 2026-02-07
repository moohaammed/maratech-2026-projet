import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    
    try {
      // 1. Find User by Name/Email
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docName = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
        final docEmail = (data['email'] ?? '').toString().toLowerCase();
        final input = name.toLowerCase();

        if (docName == input || docEmail == input) {
          userDoc = doc;
          break;
        }
      }

      if (userDoc == null) {
        throw Exception('Utilisateur non trouvé.');
      }

      final email = userDoc.data()['email'];
      final password = "000$pin"; // Pad PIN to 6 chars

      // 2. Auth with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // 3. Redirect based on Role
        final role = (userDoc.data()['role'] ?? '').toString();
        // Support legacy & new format
        final isLegacyAdmin = role.contains('_admin');
        final isNewAdmin = role.contains('UserRole.') && role.contains('Admin');
        
        if (isLegacyAdmin || isNewAdmin) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Erreur de connexion.';
        if (e.code == 'wrong-password') message = 'Code PIN incorrect.';
        if (e.code == 'user-not-found') message = 'Utilisateur non trouvé.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // --- Debug Admin Creation ---
  Future<void> _showAdminCreationMenu() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer Admin (Debug)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdminOption('Main Admin', 'UserRole.mainAdmin', '111'),
            _buildAdminOption('Coach Admin', 'UserRole.coachAdmin', '222'),
            _buildAdminOption('Group Admin', 'UserRole.groupAdmin', '333'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption(String label, String role, String pin) {
    return ListTile(
      title: Text(label),
      subtitle: Text('PIN: $pin'),
      leading: const Icon(Icons.security, color: AppColors.primary),
      onTap: () {
        Navigator.pop(context);
        _createAdminUser(label, role, pin);
      },
    );
  }

  Future<void> _createAdminUser(String label, String role, String pin) async {
    setState(() => _isLoading = true);
    try {
      final email = '${role.replaceAll(".", "").replaceAll("UserRole", "")}@test.com';
      final password = '000$pin';
      final name = 'Test $label';
      
      // Create Auth
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      } catch (_) {} // Ignore if exists
      
      // Create Firestore Doc
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'id': uid,
          'fullName': name,
          'email': email,
          'phone': '+216 00 000 000',
          'cinLastDigits': pin,
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'permissions': _getPermissionsForRole(role),
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ $label créé! Login: $name / $pin'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Map<String, bool> _getPermissionsForRole(String role) {
    // Simplified mapping for debug creation
    if (role.contains('mainAdmin')) {
      return {'manageUsers': true, 'manageAdmins': true};
    }
    return {'manageUsers': false};
  }
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connexion', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: kDebugMode ? FloatingActionButton(
        onPressed: _showAdminCreationMenu,
        backgroundColor: AppColors.error,
        child: const Icon(Icons.add_moderator),
      ) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Running Club Tunis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Espace Membre & Admin', style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 48),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pinController,
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      decoration: InputDecoration(
                        labelText: 'PIN (3 chiffres)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        counterText: '',
                      ),
                      validator: (v) => v!.length != 3 ? '3 chiffres requis' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
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
}
