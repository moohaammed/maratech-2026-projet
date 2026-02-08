import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'user_management_screen.dart';
import 'admin_management_screen.dart';
import 'group_admin_dashboard.dart';
import '../../coach/screens/coach_dashboard_screen.dart';
import 'dart:ui'; // For glassmorphism

/// Premium Admin Dashboard with modern UI, animations, and dark theme
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  TabController? _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : const Color(0xFF0A0A0F);
    final textColor = highContrast ? Colors.white : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_currentUser == null) {
      return _buildErrorState(textScale, primaryColor, bgColor, textColor, highContrast);
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
      body: Stack(
        children: [
          // Background Elements
          if (!highContrast) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
             Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      // Increased height to prevent overflow and reduce clumsiness
                      expandedHeight: 280 * textScale.clamp(1.0, 1.1),
                      pinned: true,
                      backgroundColor: highContrast ? Colors.black : Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeaderContent(textScale, primaryColor, highContrast),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(70),
                        child: _tabController != null 
                          ? _buildTabBar(highContrast, primaryColor, textScale)
                          : const SizedBox(),
                      ),
                      actions: [
      
                       const SizedBox(width: 8),
                       _buildAppBarAction(Icons.logout_rounded, () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            await Provider.of<AccessibilityProvider>(context, listen: false).logoutAndRestoreLocalProfile();
                            if (mounted) Navigator.pushReplacementNamed(context, '/login');
                          }
                       }, AppColors.error, isLogout: true),
                       const SizedBox(width: 16),
                      ],
                    ),
                  ];
                },
                body: _tabController != null 
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        const UserManagementScreen(),
                        const AdminManagementScreen(),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool highContrast, Color primaryColor, double textScale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highContrast ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.7)]),
          boxShadow: [
            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * textScale),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(2),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 20),
                SizedBox(width: 8),
                Text('Utilisateurs'),
              ],
            ),
          ),
          Tab(
             child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 20),
                SizedBox(width: 8),
                Text('Admins'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, Color color, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogout ? AppColors.error.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isLogout ? AppColors.error.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: isLogout ? AppColors.error : Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHeaderContent(double textScale, Color primaryColor, bool highContrast) {
    return Padding(
      // Moved Top padding down to account for StatusBar + safe area clearly
      padding: EdgeInsets.fromLTRB(20, 60 * textScale.clamp(1.0, 1.2), 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              // Added Expanded to prevent text overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de Bord Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22 * textScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Gérez votre communauté',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13 * textScale,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Adjust spacing
          SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),
          _buildStatisticsHeader(highContrast, primaryColor, textScale),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(bool highContrast, Color primaryColor, double textScale) {
    return StreamBuilder<Map<String, int>>(
      stream: _userService.getUserStatisticsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'active': 0};
        
        return SizedBox(
          height: 110 * textScale.clamp(1.0, 1.2), // Fixed height for stats row
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard('Total', stats['total']?.toString() ?? '0', Icons.group_rounded, AppColors.secondary, textScale),
              const SizedBox(width: 12),
              _buildStatCard('Actifs', stats['active']?.toString() ?? '0', Icons.check_circle_rounded, AppColors.success, textScale),
              const SizedBox(width: 12),
              _buildStatCard('Admins', ((stats['mainAdmins'] ?? 0) + (stats['coachAdmins'] ?? 0) + (stats['groupAdmins'] ?? 0)).toString(), Icons.security_rounded, AppColors.elite, textScale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, double textScale) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 8,
               offset: const Offset(0, 4),
             )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            // FittedBox ensures large numbers don't break layout
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * textScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11 * textScale,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double textScale, Color primaryColor, Color bgColor, Color textColor, bool highContrast) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
             SizedBox(height: 16 * textScale),
             Text('Utilisateur non trouvé', style: TextStyle(color: textColor, fontSize: 18 * textScale, fontWeight: FontWeight.bold)),
             const SizedBox(height: 32),
             ElevatedButton.icon(
               onPressed: () => Navigator.pushReplacementNamed(context, '/'),
               icon: const Icon(Icons.login),
               label: const Text('Retour Connexion'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: primaryColor,
                 foregroundColor: Colors.white,
                 padding: EdgeInsets.symmetric(horizontal: 24 * textScale, vertical: 12 * textScale),
               ),
             )
          ],
        ),
      ),
    );
  }
}
