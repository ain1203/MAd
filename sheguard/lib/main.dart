import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Services
import 'services/firebase_auth_service.dart';
import 'services/user_session.dart';
import 'services/theme_service.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth_page.dart';
import 'screens/home_screen.dart';
import 'screens/safety_tips_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/circle_screen.dart';
import 'screens/alerts_history_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/incoming_call_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Background services
    await AndroidAlarmManager.initialize();
    
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'fake_call_channel',
          channelName: 'Fake Call Notifications',
          channelDescription: 'Notification channel for fake calls',
          defaultColor: const Color(0xFF6A1B9A),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          locked: true,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
        )
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );
  } catch (e) {
    debugPrint("🚨 Initialization error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const SafeHerApp(),
    ),
  );
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SafeHer',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,
      theme: ThemeData(
        primaryColor: const Color(0xFF6A1B9A),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A),
          secondary: const Color(0xFFF3E5F5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF9C27B0),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFFCE93D8),
          secondary: const Color(0xFF4A148C),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth-wrapper': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/safety-tips': (context) => const SafetyTipsScreen(),
        '/circle': (context) => const CircleScreen(),
        '/alerts-history': (context) => const AlertsHistoryScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/fake-call': (context) => const FakeCallScreen(),
      },
    );
  }
}

/// ─── AUTH STATE LISTENER ───
/// This widget automatically redirects users based on their Firebase login status.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            // Logged out -> Show AuthPage (Login/Signup toggle)
            return const AuthPage();
          } else {
            // Logged in -> Initialize session and show Home
            _initializeSession(user);
            return const HomeScreen();
          }
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
          ),
        );
      },
    );
  }

  void _initializeSession(User user) {
    UserSession.setFromEmail(user.email ?? 'user@example.com');
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      UserSession.setFromFullName(user.displayName!);
    }
    if (user.photoURL != null) {
      UserSession.setProfileImage(user.photoURL!);
    }
  }
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    if (receivedNotification.channelKey == 'fake_call_channel') {
      final String callerName = receivedNotification.payload?['caller'] ?? 'Unknown';
      SafeHerApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/incoming-call'),
          builder: (_) => IncomingCallScreen(callerName: callerName),
        ),
      );
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == 'fake_call_channel') {
      final String callerName = receivedAction.payload?['caller'] ?? 'Unknown';
      SafeHerApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/incoming-call'),
          builder: (_) => IncomingCallScreen(callerName: callerName),
        ),
      );
    }
  }
}