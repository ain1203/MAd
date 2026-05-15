import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Themes & Providers
import 'theme/app_theme.dart';
import 'services/theme_provider.dart';

// Services
import 'services/firebase_auth_service.dart';
import 'services/user_session.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth_page.dart';
import 'screens/home_screen.dart';
import 'screens/safety_tips_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/circle_screen.dart';
import 'screens/alerts_history_screen.dart';
import 'screens/safety_bot_screen.dart';
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
          defaultColor: SafeHerColors.primary,
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
      create: (_) => ThemeProvider(),
      child: const SafeHerApp(),
    ),
  );
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SafeHer',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/auth-wrapper': (context) => const AuthWrapper(),
            '/home': (context) => const HomeScreen(),
            '/safety-tips': (context) => const SafetyTipsScreen(),
            '/circle': (context) => const CircleScreen(),
            '/alerts-history': (context) => const AlertsHistoryScreen(),
            '/fake-call': (context) => const FakeCallScreen(),
          },
        );
      },
    );
  }
}

/// ─── AUTH STATE LISTENER ───
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
            return const AuthPage();
          } else {
            _initializeSession(user);
            return const HomeScreen();
          }
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
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