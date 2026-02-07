import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import 'events/event_list_screen.dart';

/// Coach dashboard: Premium UI with glassmorphism and gradient background
class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: !highContrast,
      appBar: AppBar(
        title: Text('Espace Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22 * textScale, color: textColor)),
        centerTitle: false,
        backgroundColor: highContrast ? AppColors.highContrastSurface : Colors.transparent,
        flexibleSpace: highContrast ? null : ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: bgColor.withOpacity(0.5),
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => _confirmLogout(context),
              tooltip: 'Déconnexion',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Background Gradient (only in normal mode)
          if (!highContrast)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.background,
                      AppColors.primary.withOpacity(0.05),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
          // Decorative Circles (only in normal mode)
          if (!highContrast)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          
          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 20 * textScale, 20, 10 * textScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bonjour, Coach 👋",
                        style: TextStyle(
                          fontSize: 28 * textScale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4 * textScale),
                      Text(
                        "Gérez vos événements et entraînements.",
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          color: highContrast ? Colors.white70 : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: EventListScreen(
                    canCreate: true, 
                    hideAppBar: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
