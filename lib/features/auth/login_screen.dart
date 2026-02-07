import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login Screen - Simple login with name + PIN
/// No signup - admin creates accounts
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
      debugPrint('🔍 Attempting login for: $name');

      // 1. Find the User's Email from Firestore by Name to get their Email
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      
      QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docName = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
        final docEmail = (data['email'] ?? '').toString().toLowerCase();
        
        final input = name.toLowerCase();

        // Check match (Name OR Email)
        if (docName == input || docEmail == input) {
          userDoc = doc;
          break;
        }
      }

      if (userDoc == null) {
        throw Exception('Nom d\'utilisateur non trouvé.');
      }

      final email = userDoc.data()['email'];
      debugPrint('✅ Found User: ${userDoc.id} ($email)');

      // 2. Try to Sign In with Firebase Auth
      // Strategy: Try padding the 3-digit PIN to 6 chars (000 + PIN)
      // This solves the "6 char password" requirement while keeping UI simple.
      final password = "000$pin"; 
      debugPrint('🔐 Authenticating with Email: $email...');

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, 
          password: password
        );
        debugPrint('✅ Firebase Auth Success!');
        
        // 3. Update Accessibility Profile with real User ID
        // The provider listens to Auth changes, or we can force a reload
        if (mounted) {
          // Optional: Force reload provider if context available
          // Provider.of<AccessibilityProvider>(context, listen: false).loadProfile();
          
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(context, '/home');
        }

      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
           throw Exception('Code PIN incorrect (Auth)');
        }
        throw e;
      }

    } catch (e) {
      debugPrint('❌ Login Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll("Exception:", "")}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showAdminCreationMenu() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Admin User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdminOption('Main Admin', 'main_admin', '111'),
            _buildAdminOption('Coach Admin', 'coach_admin', '222'),
            _buildAdminOption('Group Admin', 'group_admin', '333'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption(String label, String role, String pin) {
    return ListTile(
      title: Text(label),
      subtitle: Text('PIN: $pin'),
      leading: const Icon(Icons.person_add),
      onTap: () {
        Navigator.pop(context);
        _createAdminUser(label, role, pin);
      },
    );
  }

  Future<void> _createAdminUser(String label, String role, String pin) async {
    setState(() => _isLoading = true);
    try {
      final email = '${role.replaceAll("_", "")}@test.com';
      final password = '000$pin'; 
      final name = 'Test $label';
      
      // 1. Create Auth
      try {
         await FirebaseAuth.instance.createUserWithEmailAndPassword(
           email: email, 
           password: password
         );
      } on FirebaseAuthException catch (e) {
         if (e.code != 'email-already-in-use') rethrow;
         // If exists, we still update Firestore
      }
      
      // 2. Create Firestore User MATCHING SCHEMA
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'userId': uid,
          'fullName': name,
          'email': email,
          'phone': '+216 24 474 474',
          
          'cin': 'encrypted:demo$pin',
          'pin': pin,
          'pinHash': 'hash-$pin',
          
          'role': role, // <--- DYNAMIC ROLE
          'permissions': _getPermissionsForRole(role),
          
          'adminLevel': role == 'main_admin' ? 1 : 2,
          'groupId': role == 'group_admin' ? 'beginner' : null,
          
          'isActive': true,
          'accountStatus': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'accountCreatedBy': 'system_debug'
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('✅ $label Created! Login with PIN: $pin (Name: $name)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
       debugPrint('Error creating admin: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
       }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, bool> _getPermissionsForRole(String role) {
    if (role == 'main_admin') {
      return {
        'canCreateEvents': true, 'canEditUsers': true, 'canDeleteUsers': true,
        'canManageGroups': true, 'canPostAnnouncements': true, 'canViewAnalytics': true
      };
    } else if (role == 'coach_admin') {
      return {
        'canCreateEvents': true, 'canEditUsers': false, 'canDeleteUsers': false,
        'canManageGroups': false, 'canPostAnnouncements': true, 'canViewAnalytics': true
      };
    } else {
      // Group Admin
      return {
        'canCreateEvents': true, 'canEditUsers': true, 'canDeleteUsers': false,
        'canManageGroups': true, 'canPostAnnouncements': true, 'canViewAnalytics': false
      };
    }
  }

  void _continueAsVisitor() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    // Access dynamic theme data (High Contrast / Text Scale integrated)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Club'),
        centerTitle: true,
        backgroundColor: colorScheme.surface, // Or primary depending on theme
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      floatingActionButton: kDebugMode ? FloatingActionButton(
        onPressed: _showAdminCreationMenu,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_moderator),
        tooltip: 'Create Admin User',
      ) : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.directions_run,
                                    size: 60,
                                    color: colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Connexion',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accédez à votre espace',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            Text(
                              'Nom complet',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: textTheme.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Entrez votre nom',
                                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                                filled: true,
                                fillColor: colorScheme.surfaceVariant.withOpacity(0.3), // Dynamic surface
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // PIN Field
                            Text(
                              'Code PIN (3 derniers chiffres CIN)',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: _obscurePin,
                              maxLength: 3,
                              style: textTheme.bodyMedium,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: '• • •',
                                prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePin = !_obscurePin);
                                  },
                                ),
                                counterText: '',
                                filled: true,
                                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre PIN';
                                }
                                if (value.length != 3) {
                                  return 'Le PIN doit contenir 3 chiffres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Button
                            // Theme handles button size based on motor needs!
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                // Style is largely handled by Theme, but we can override specific shapes
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Votre compte est créé par un administrateur. Contactez RCT si vous n\'avez pas de compte.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
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
          },
        ),
      ),
    );
  }
}
