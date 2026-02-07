import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../coach/screens/events/event_list_screen.dart';
import '../../accessibility/providers/accessibility_provider.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Voice welcome for blind users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      if (accessibility.profile.visualNeeds == 'blind') {
        _speakWelcome();
      }
    });
  }

  Future<void> _speakWelcome() async {
    await _tts.speak('Mode invité activé. Vous pouvez consulter l\'histoire du club, nos valeurs et la liste des événements. Utilisez les onglets en haut de l\'écran pour naviguer.');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Running Club Tunis - Invité', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Semantics(
                label: 'Onglet Histoire du Club',
                child: Text('Club'),
              ),
              icon: Icon(Icons.history),
            ),
            Tab(
              child: Semantics(
                label: 'Onglet Valeurs et Charte',
                child: Text('Valeurs'),
              ),
              icon: Icon(Icons.info_outline),
            ),
            Tab(
              child: Semantics(
                label: 'Onglet Liste des Événements',
                child: Text('Événements'),
              ),
              icon: Icon(Icons.event),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            tooltip: 'Se connecter',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildValuesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Notre Histoire'),
          const SizedBox(height: 16),
          _buildTextCard(
            'Le Running Club Tunis est né d\'une passion commune pour la course à pied et le dépassement de soi. Depuis sa création, le club a rassemblé des centaines de coureurs de tous niveaux, créant une communauté soudée et dynamique dans la capitale.',
            Icons.history_edu,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Parcours'),
          const SizedBox(height: 16),
          _buildTextCard(
            'Des entraînements quotidiens aux marathons internationaux, nos membres portent fièrement les couleurs du club. Nous organisons régulièrement des sorties collectives vers Carthage, Sidi Bou Saïd et le centre-ville.',
            Icons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildValuesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Valeurs et Objectifs'),
          const SizedBox(height: 16),
          _buildValueItem('Inclusivité', 'Accueillir tous les coureurs, du débutant à l\'athlète confirmé.', Icons.people),
          _buildValueItem('Dépassement', 'Encourager chacun à atteindre ses objectifs personnels.', Icons.trending_up),
          _buildValueItem('Solidarité', 'Courir ensemble, s\'entraider et ne laisser personne derrière.', Icons.favorite),
          const SizedBox(height: 24),
          _buildSectionTitle('Charte du Club'),
          const SizedBox(height: 16),
          _buildTextCard(
            '1. Respect des autres coureurs et des piétons.\n'
            '2. Ponctualité aux entraînements collectifs.\n'
            '3. Port des couleurs du club lors des compétitions officielles.\n'
            '4. Entraide technique et morale entre les membres.',
            Icons.verified_user,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Organisation des Groupes'),
          const SizedBox(height: 16),
          _buildTextCard(
            'L\'organisation s\'appuie sur des responsables de groupe (Group Admins) qui encadrent les séances selon les niveaux :\n\n'
            '• Groupe 1-2 : Débutants et reprise progressive\n'
            '• Groupe 3 : Intermédiaire (Endurance fondamentale)\n'
            '• Groupe 4-5 : Avancé (Performance et fractionné)',
            Icons.format_list_bulleted,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return const EventListScreen(canCreate: false);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextCard(String text, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
