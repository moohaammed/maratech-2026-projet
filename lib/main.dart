import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Providers
import 'features/accessibility/providers/accessibility_provider.dart';
import 'core/services/notification_service.dart';

// Screens
import 'features/splash/splash_screen.dart';
import 'features/onboarding/accessibility_wizard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/fcm_test_screen.dart';
import 'features/guest/screens/guest_home_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/coach/screens/events/event_detail_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.startListeningToEvents();
  
  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      navigatorKey: NotificationService.navigatorKey,
      locale: Locale(accessibility.languageCode),
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        '/guest-home': (context) => const GuestHomeScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/fcm-test': (context) => const FcmTestScreen(),
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

