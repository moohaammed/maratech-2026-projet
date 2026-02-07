import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Providers
import 'features/accessibility/providers/accessibility_provider.dart';

// Screens
import 'features/splash/splash_screen.dart';
import 'features/onboarding/accessibility_wizard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider()..loadProfile(),
        ),
      ],
      child: const RunningClubApp(),
    ),
  );
}

class RunningClubApp extends StatelessWidget {
  const RunningClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the accessibility provider for changes
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;

    // Build dynamic theme based on accessibility settings
    ThemeData theme;
    if (profile.highContrast) {
      theme = AppTheme.highContrastTheme(
        textScale: profile.textSize,
        boldText: profile.boldText,
      );
    } else {
      theme = AppTheme.lightTheme(
        textScale: profile.textSize,
        boldText: profile.boldText,
      );
    }

    return MaterialApp(
      title: 'Running Club Tunis',
      debugShowCheckedModeBanner: false,
      theme: theme,
      
      // Start with splash screen
      initialRoute: '/',
      
      // Define routes
      routes: {
        '/': (context) => const SplashScreen(),
        '/accessibility-wizard': (context) => const AccessibilityWizardScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
