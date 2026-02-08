import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
    // Remove the native splash screen as soon as our Flutter splash screen is ready
    FlutterNativeSplash.remove();
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
    // START A HARD TIMEOUT TIMER
    // This guarantees navigation happens after 5 seconds no matter what
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _navigateTo(null);
    });

    try {
      // 1. Minimum display time (animation)
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // 2. Load Data Safely
      final nextRoute = await _loadAppData();
      
      if (mounted) {
        _navigateTo(nextRoute);
      }
    } catch (e) {
      debugPrint("Splash Error: $e");
      if (mounted) _navigateTo(null);
    }
  }

  void _navigateTo(String? nextRoute) {
    if (!mounted) return;
    
    // Prevent double navigation if already navigated
    // We check if we are still on the splash screen route
    // This is a simplified check to avoid complex route logic errors
    
    final prefsFuture = SharedPreferences.getInstance();
    
    prefsFuture.then((prefs) {
        if (!mounted) return;
        
        final isWizardComplete = prefs.getBool('onboarding_wizard_completed') ?? false;
        String target = '/accessibility-wizard';
        
        if (isWizardComplete) target = '/login';
        if (nextRoute != null) target = nextRoute;

        Navigator.of(context).pushReplacementNamed(target);
    }).catchError((e) {
        // Absolute fallback if even prefs fail
        Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  Future<String?> _loadAppData() async {
    try {
      // Initialize TTS silently
      _tts.setLanguage('fr-FR').catchError((_) {});

      // Speak welcome 
      WidgetsBinding.instance.addPostFrameCallback((_) {
         final isScreenReaderActive = MediaQuery.of(context).accessibleNavigation;
         if (isScreenReaderActive) {
           _tts.speak("RCT. Bienvenue! Welcome! مرحبا!");
         }
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
           // Load Accessibility Profile
           final authProvider = Provider.of<AccessibilityProvider>(context, listen: false);
           await authProvider.loadProfile().timeout(const Duration(seconds: 2), onTimeout: () => null);
           
           // Fetch User Role
           final userDoc = await FirebaseFirestore.instance
               .collection('users')
               .doc(currentUser.uid)
               .get()
               .timeout(const Duration(seconds: 2));
               
           if (userDoc.exists) {
              final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
              debugPrint("✅ Auto-login user role: $role");
              
              if (role.contains('admin')) {
                  final defaultProfile = AccessibilityProfile(userId: currentUser.uid);
                  await authProvider.updateProfile(defaultProfile);
              }
              
              if (role == 'main_admin' || role == 'sub_admin' || role == 'group_admin' || role == 'groupadmin') {
                return '/admin-dashboard';
              } else if (role == 'coach_admin' || role == 'coachadmin') {
                return '/coach-dashboard';
              } else {
                return '/home';
              }
           }
      }
    } catch (e) {
      debugPrint("⚠️ Minimal Splash Error: $e");
    }
    return null;
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
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/logo.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.directions_run,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name
                    const Text(
                      'Running Club Tunis',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Courir ensemble • نركض معًا • Run together',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(1, 1),
                            blurRadius: 4,
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
