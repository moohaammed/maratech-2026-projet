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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erreur: Utilisateur non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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

    // Default view for Main Admin (using the user's provided "correct" version)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(),
          
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

  Widget _buildStatisticsHeader() {
    return StreamBuilder<Map<String, int>>(
      stream: _userService.getUserStatisticsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'active': 0};
        
        return Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              _buildStatCard('Total', stats['total']?.toString() ?? '0', Icons.group),
              const SizedBox(width: 16),
              _buildStatCard('Actifs', stats['active']?.toString() ?? '0', Icons.check_circle),
              const SizedBox(width: 16),
              _buildStatCard('Admins', ((stats['mainAdmins'] ?? 0) + (stats['coachAdmins'] ?? 0) + (stats['groupAdmins'] ?? 0)).toString(), Icons.security),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}