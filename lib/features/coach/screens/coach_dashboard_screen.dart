import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import 'events/event_list_screen.dart';
import 'events/create_event_screen.dart';

/// Coach Dashboard: Hackathon-winning Premium UI with stunning visuals
class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedTabIndex = 0;
  int _totalEvents = 0;
  int _upcomingEvents = 0;
  int _totalParticipants = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStats();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadStats() async {
    try {
      final now = DateTime.now();
      final eventsSnap = await FirebaseFirestore.instance.collection('events').get();
      int upcoming = 0;
      int participants = 0;
      
      for (var doc in eventsSnap.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp?)?.toDate();
        if (date != null && date.isAfter(now)) {
          upcoming++;
        }
        final parts = data['participants'] as List?;
        if (parts != null) {
          participants += parts.length;
        }
      }
      
      if (mounted) {
        setState(() {
          _totalEvents = eventsSnap.docs.length;
          _upcomingEvents = upcoming;
          _totalParticipants = participants;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de votre session coach?',
          style: TextStyle(color: Colors.grey[300], fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final surfaceColor = highContrast ? AppColors.highContrastSurface : const Color(0xFF16161F);
    final textColor = highContrast ? Colors.white : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Animated Gradient Background
          if (!highContrast) ..._buildAnimatedBackground(primaryColor),
          
          // Main Content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _slideController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium App Bar
                    SliverToBoxAdapter(
                      child: _buildPremiumHeader(textScale, primaryColor, textColor, highContrast),
                    ),
                    
                    // Stats Cards
                    SliverToBoxAdapter(
                      child: _buildStatsSection(textScale, primaryColor, surfaceColor, textColor),
                    ),
                    
                    // Quick Actions
                    SliverToBoxAdapter(
                      child: _buildQuickActions(textScale, primaryColor, surfaceColor, textColor),
                    ),
                    
                    // Tab Section
                    SliverToBoxAdapter(
                      child: _buildTabSection(textScale, primaryColor, surfaceColor, textColor),
                    ),
                    
                    // Events List
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: _buildEventsSection(textScale, highContrast, surfaceColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const CreateEventScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            ).then((_) => _loadStats()),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Créer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15 * textScale,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedBackground(Color primaryColor) {
    return [
      // Gradient Orbs
      Positioned(
        top: -120,
        right: -80,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.3 * _pulseAnimation.value),
                  primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.2 * _pulseAnimation.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      // Noise Overlay for depth
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildPremiumHeader(double textScale, Color primaryColor, Color textColor, bool highContrast) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _getGreeting();
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16 * textScale, 20, 8),
      child: Row(
        children: [
          // Logo & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sports_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13 * textScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Espace Coach',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22 * textScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            children: [
              const SizedBox(width: 8),
              _buildHeaderAction(
                icon: Icons.logout_rounded,
                onTap: () => _confirmLogout(context),
                primaryColor: AppColors.error,
                isLogout: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLogout 
                ? Colors.red.withOpacity(0.1) 
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLogout 
                  ? Colors.red.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Icon(
            icon,
            color: isLogout ? AppColors.error : Colors.white70,
            size: 22,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour 👋';
    if (hour < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
  }

  Widget _buildStatsSection(double textScale, Color primaryColor, Color surfaceColor, Color textColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20 * textScale, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.event_rounded,
              value: _totalEvents.toString(),
              label: 'Total',
              color: primaryColor,
              surfaceColor: surfaceColor,
              textScale: textScale,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.upcoming_rounded,
              value: _upcomingEvents.toString(),
              label: 'À venir',
              color: AppColors.warning,
              surfaceColor: surfaceColor,
              textScale: textScale,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_rounded,
              value: _totalParticipants.toString(),
              label: 'Inscrits',
              color: AppColors.success,
              surfaceColor: surfaceColor,
              textScale: textScale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color surfaceColor,
    required double textScale,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 12 * textScale.clamp(1.0, 1.1)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4 * textScale.clamp(1.0, 1.1)),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12 * textScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(double textScale, Color primaryColor, Color surfaceColor, Color textColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20 * textScale, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16 * textScale),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Nouvel événement',
                  color: primaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                  ).then((_) => _loadStats()),
                  textScale: textScale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_view_week_rounded,
                  label: 'Voir calendrier',
                  color: AppColors.secondary,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  textScale: textScale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double textScale,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16 * textScale.clamp(1.0, 1.1)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * textScale,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection(double textScale, Color primaryColor, Color surfaceColor, Color textColor) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20 * textScale, 20, 12),
      child: Row(
        children: [
          _buildTab(
            label: 'Événements',
            isSelected: _selectedTabIndex == 0,
            onTap: () => setState(() => _selectedTabIndex = 0),
            primaryColor: primaryColor,
            textScale: textScale,
          ),
          const SizedBox(width: 8),
          _buildTab(
            label: 'Passés',
            isSelected: _selectedTabIndex == 1,
            onTap: () => setState(() => _selectedTabIndex = 1),
            primaryColor: primaryColor,
            textScale: textScale,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 20 * textScale.clamp(1.0, 1.1),
          vertical: 10 * textScale.clamp(1.0, 1.1),
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14 * textScale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsSection(double textScale, bool highContrast, Color surfaceColor) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        decoration: BoxDecoration(
          color: highContrast ? Colors.black : surfaceColor.withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: EventListScreen(
          canCreate: true,
          hideAppBar: true,
          showPastOnly: _selectedTabIndex == 1,
        ),
      ),
    );
  }
}


