import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Providers & Services
import 'features/accessibility/providers/accessibility_provider.dart';
import 'core/services/accessibility_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ai_coach_service.dart';

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
import 'features/announcements/screens/announcements_screen.dart';
import 'features/profile/screens/history_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  
  // Initialize Notification Service (FCM + Local)
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.startListeningToEvents();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProxyProvider<AccessibilityProvider, AccessibilityService>(
          create: (_) => AccessibilityService(),
          update: (context, provider, service) {
            final accessibilityService = service ?? AccessibilityService();
            accessibilityService.syncWithProfile(
              ttsEnabled: provider.profile.ttsEnabled,
              vibrationEnabled: provider.profile.vibrationEnabled,
              audioNeeds: provider.profile.audioNeeds,
              visualNeeds: provider.profile.visualNeeds,
              motorNeeds: provider.profile.motorNeeds,
              languageCode: provider.profile.languageCode,
            );
            return accessibilityService;
          },
        ),
        ChangeNotifierProvider(create: (_) => AICoachService()),
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
        '/announcements': (context) => const AnnouncementsScreen(),
        '/history': (context) => const HistoryScreen(),
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
