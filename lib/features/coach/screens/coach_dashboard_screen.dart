import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'events/event_list_screen.dart';

/// Coach dashboard: event list with create permission + logout.
class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const EventListScreen(canCreate: true),
      appBar: AppBar(
        title: const Text('Espace Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }
}
