import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Providers & Services
import 'features/accessibility/providers/accessibility_provider.dart';
import 'core/services/accessibility_service.dart';
import 'core/services/notification_service.dart';

// Screens
import 'features/splash/splash_screen.dart';
import 'features/onboarding/accessibility_wizard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/guest/screens/guest_home_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/coach/screens/events/event_detail_screen.dart';
import 'features/coach/screens/coach_dashboard_screen.dart';
import 'features/chat/screens/group_chat_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityService()),
      ],
      child: const RctApp(),
    ),
  );
}

class RctApp extends StatelessWidget {
  const RctApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch accessibility changes to update theme/locale
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    
    // Build dynamic theme based on accessibility settings
    ThemeData theme;
    if (profile.highContrast) {
      theme = AppTheme.highContrastTheme(
        textScale: profile.textSize,
        boldText: profile.boldText,
        isDyslexic: profile.dyslexicMode,
      );
    } else {
      theme = AppTheme.lightTheme(
        textScale: profile.textSize,
        boldText: profile.boldText,
        isDyslexic: profile.dyslexicMode,
      );
    }

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      locale: Locale(accessibility.languageCode),
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'RCT',
      debugShowCheckedModeBanner: false,
      theme: theme,
      
      // Start with splash screen which handles logic/routing
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/accessibility-wizard': (context) => const AccessibilityWizardScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/guest-home': (context) => const GuestHomeScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/coach-dashboard': (context) => const CoachDashboardScreen(),
        '/group-chat': (context) => const GroupChatScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/event-details') {
          final eventId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: eventId ?? ''),
          );
        }
        return null;
      },
    );
  }
}
