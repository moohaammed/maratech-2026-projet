import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'user_management_screen.dart';
import 'admin_management_screen.dart';
import 'group_admin_dashboard.dart';
import '../../coach/screens/coach_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../accessibility/providers/accessibility_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  TabController? _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userModel = await _userService.getUserById(firebaseUser.uid);
        if (mounted) {
          setState(() {
            _currentUser = userModel;
            // Only initialize the 2-tab controller if it's a mainAdmin or other non-groupAdmin
            if (_currentUser != null && _currentUser!.role != UserRole.groupAdmin) {
              _tabController = TabController(length: 2, vsync: this);
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
    final surfaceColor = highContrast ? AppColors.highContrastSurface : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: Utilisateur non trouvé', style: TextStyle(color: textColor, fontSize: 16 * textScale)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Retour Connexion'),
              )
            ],
          ),
        ),
      );
    }

    // Branch to Role-Specific Dashboards
    if (_currentUser!.role == UserRole.groupAdmin) {
      return GroupAdminDashboard(currentUser: _currentUser!);
    }

    if (_currentUser!.role == UserRole.coachAdmin) {
      return const CoachDashboardScreen();
    }

    // Default view for Main Admin
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * textScale)),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: 0,
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          indicatorColor: highContrast ? primaryColor : Colors.white,
          indicatorWeight: 4,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale),
          tabs: const [
            Tab(text: 'Utilisateurs', icon: Icon(Icons.people)),
            Tab(text: 'Administrateurs', icon: Icon(Icons.security)),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test FCM Push',
            onPressed: () {
              Navigator.pushNamed(context, '/fcm-test');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                await Provider.of<AccessibilityProvider>(context, listen: false).logoutAndRestoreLocalProfile();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(highContrast, primaryColor, textScale),
          
          // Tab Content
          Expanded(
            child: _tabController != null 
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    const UserManagementScreen(),
                    const AdminManagementScreen(),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(bool highContrast, Color primaryColor, double textScale) {
    return StreamBuilder<Map<String, int>>(
      stream: _userService.getUserStatisticsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'active': 0};
        
        return Container(
          color: highContrast ? Colors.black : primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              _buildStatCard('Total', stats['total']?.toString() ?? '0', Icons.group, highContrast, textScale, primaryColor),
              const SizedBox(width: 12),
              _buildStatCard('Actifs', stats['active']?.toString() ?? '0', Icons.check_circle, highContrast, textScale, primaryColor),
              const SizedBox(width: 12),
              _buildStatCard('Admins', ((stats['mainAdmins'] ?? 0) + (stats['coachAdmins'] ?? 0) + (stats['groupAdmins'] ?? 0)).toString(), Icons.security, highContrast, textScale, primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool highContrast, double textScale, Color primaryColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highContrast ? AppColors.highContrastSurface : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highContrast ? primaryColor : Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: highContrast ? primaryColor : Colors.white, size: 20 * textScale),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: highContrast ? Colors.white : Colors.white,
                fontSize: 22 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: highContrast ? primaryColor : Colors.white.withOpacity(0.9),
                fontSize: 11 * textScale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
