import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../features/accessibility/providers/accessibility_provider.dart';
import '../../features/accessibility/models/accessibility_profile.dart';
import '../../core/theme/app_colors.dart';

/// Splash Screen - First screen users see with images carousel
/// 
/// Features:
/// - Shows images from assets
/// - Auto-advances through images
/// - Speaks welcome for screen reader users
/// - Animated transitions
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final FlutterTts _tts = FlutterTts();
  
  // Current image index
  int _currentImageIndex = 0;
  
  // Images from assets
  final List<String> _images = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startImageCarousel();
    _initTtsAndNavigate();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  void _startImageCarousel() {
    // Change image every 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _currentImageIndex < _images.length - 1) {
        setState(() => _currentImageIndex++);
        _startImageCarousel();
      }
    });
  }

  Future<void> _initTtsAndNavigate() async {
    // Initialize TTS
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    
    // Check completion status
    final prefs = await SharedPreferences.getInstance();
    final isWizardComplete = prefs.getBool('onboarding_wizard_completed') ?? false;
    
    // Check for auto-login
    String? nextRoute; // Null implies standard flow
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && mounted) {
      try {
        // Load Accessibility Profile
        final authProvider = Provider.of<AccessibilityProvider>(context, listen: false);
        await authProvider.loadProfile();
        debugPrint("✅ Auto-login: Loaded profile for ${currentUser.uid}");
        
        // Fetch User Role
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
           final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
           debugPrint("✅ Auto-login user role: $role");
           
           // Admin logic (reset accessibility)
           if (role == 'main_admin' || role == 'sub_admin' || role == 'group_admin' || role == 'groupadmin' || role == 'coach_admin' || role == 'coachadmin') {
               final defaultProfile = AccessibilityProfile(userId: currentUser.uid);
               await authProvider.updateProfile(defaultProfile);
           }
           
           if (role == 'main_admin' || role == 'sub_admin' || role == 'group_admin' || role == 'groupadmin') {
             nextRoute = '/admin-dashboard';
           } else if (role == 'coach_admin' || role == 'coachadmin') {
             nextRoute = '/coach-dashboard';
           } else {
             nextRoute = '/home';
           }
        }
      } catch (e) {
        debugPrint("⚠️ Auto-login error: $e");
        // Fallback to login screen
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Speak welcome for blind users IF not already completed (or just welcome anyway)
      final isScreenReaderActive = MediaQuery.of(context).accessibleNavigation;
      if (isScreenReaderActive) {
        await _tts.speak("RCT. Bienvenue! Welcome! مرحبا!");
      }
      
      // Navigate after showing all images
      await Future.delayed(const Duration(milliseconds: 4500));
      if (mounted) {
        if (nextRoute != null) {
            Navigator.pushReplacementNamed(context, nextRoute!);
        } else {
            if (isWizardComplete) {
                Navigator.pushReplacementNamed(context, '/login');
            } else {
                Navigator.pushReplacementNamed(context, '/accessibility-wizard');
            }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Semantics(
        label: 'Écran de chargement. RCT. Welcome. مرحبا.',
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with fade animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                _images[_currentImageIndex],
                key: ValueKey(_currentImageIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dark overlay gradient for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.directions_run,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name
                    const Text(
                      'RCT',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'RCT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(flex: 1),

                    // Welcome messages in 3 languages
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                          Text(
                            '🇫🇷 Bienvenue!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '🇬🇧 Welcome!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 8),
                         // Assuming _T is a localization function or similar, otherwise this will cause an error.
                         // If _T is not defined, this line will need to be adjusted or removed.
                         // For now, I'm adding it as provided, assuming _T is accessible.
                         // If _T is not available, a placeholder like Text('🇹🇳 مرحبا!') would be used.
                         Text(
                            '🇹🇳 مرحبا!', // Original line
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                    const Spacer(flex: 1),

                    // Image indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_images.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chargement... Loading... جار التحميل...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
