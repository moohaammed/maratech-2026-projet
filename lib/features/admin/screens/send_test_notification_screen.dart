import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/app_colors.dart';

class SendTestNotificationScreen extends StatefulWidget {
  const SendTestNotificationScreen({super.key});

  @override
  State<SendTestNotificationScreen> createState() => _SendTestNotificationScreenState();
}

class _SendTestNotificationScreenState extends State<SendTestNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Test Push Notification 🔔');
  final _bodyController = TextEditingController(text: 'Cette notification arrive même si l\'app est fermée!');
  
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendTestNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Appeler la Cloud Function pour envoyer une VRAIE notification push
      final callable = FirebaseFunctions.instance.httpsCallable('sendTestNotification');
      
      final result = await callable.call<Map<String, dynamic>>({
        'title': _titleController.text,
        'body': _bodyController.text,
      });

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Notification Push envoyée avec succès!\n\n'
            'La notification a été envoyée à TOUS les utilisateurs '
            'via Firebase Cloud Messaging.\n\n'
            'Pour tester avec l\'app fermée:\n'
            '1. Fermez COMPLÈTEMENT l\'application\n'
            '2. Cliquez à nouveau sur "Envoyer" (depuis un autre appareil)\n'
            '3. La notification devrait apparaître sur votre téléphone!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification envoyée à tous les utilisateurs!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      String errorMessage = '❌ Erreur: $e\n\n';
      
      if (e.toString().contains('unauthenticated')) {
        errorMessage += 'Vous devez être connecté pour envoyer une notification de test.';
      } else if (e.toString().contains('not-found') || e.toString().contains('UNAVAILABLE')) {
        errorMessage += '⚠️ La Cloud Function n\'est pas encore déployée.\n\n'
            'Pour déployer les Cloud Functions:\n\n'
            '1. Ouvrez un terminal dans le dossier du projet\n'
            '2. Exécutez: firebase deploy --only functions\n'
            '3. Attendez la fin du déploiement (quelques minutes)\n\n'
            'Voir le fichier GUIDE_NOTIFICATIONS_AUTOMATIQUES.md '
            'pour les instructions complètes.';
      } else {
        errorMessage += 'Vérifiez que:\n'
            '- Les Cloud Functions sont déployées\n'
            '- Vous êtes connecté\n'
            '- Firebase est bien configuré';
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Envoyer notification Push', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildFormCard(),
              const SizedBox(height: 20),
              if (_statusMessage != null) _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.info.withOpacity(0.1),
              AppColors.info.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Notification Push Automatique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette fonction utilise Firebase Cloud Functions '
              'pour envoyer une vraie notification PUSH.\n\n'
              '✅ Arrive sur TOUS les téléphones\n'
              '✅ Même si l\'app est fermée\n'
              '✅ Notification système Android/iOS\n\n'
              'Les Cloud Functions doivent être déployées d\'abord!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contenu de la notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'Message',
                prefixIcon: const Icon(Icons.message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un message';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer à tous les utilisateurs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isSuccess = _statusMessage!.startsWith('✅');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSuccess 
              ? Colors.green[50] 
              : Colors.orange[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning,
                  color: isSuccess ? AppColors.success : AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Succès' : 'Attention',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
