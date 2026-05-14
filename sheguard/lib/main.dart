import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
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
    
    // Attempt to load background services safely
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

    // Set up listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );
  } catch (e) {
    debugPrint("🚨 Initialization error: $e");
  }

  runApp(const SafeHerApp());
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    if (receivedNotification.channelKey == 'fake_call_channel') {
      final String callerName = receivedNotification.payload?['caller'] ?? 'Unknown';
      
      // Immediately show the full-screen UI when the notification is displayed
      SafeHerApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/incoming-call'),
          builder: (_) => IncomingCallScreen(callerName: callerName),
        ),
      );
    }
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == 'fake_call_channel') {
      // If we're already on the IncomingCallScreen, don't push it again
      bool isAlreadyOnCallScreen = false;
      SafeHerApp.navigatorKey.currentState?.popUntil((route) {
        if (route.settings.name == '/incoming-call') {
          isAlreadyOnCallScreen = true;
        }
        return true; 
      });

      if (!isAlreadyOnCallScreen) {
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
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SafeHer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.purple[700],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.purple[700]!,
          secondary: const Color(0xFFF3E5F5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: Colors.purple.withOpacity(0.4),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple[700]!, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/safety-tips': (context) => const SafetyTipsScreen(),
        '/circle': (context) => const CircleScreen(),
        '/alerts-history': (context) => AlertsHistoryScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/fake-call': (context) => const FakeCallScreen(),
      },
    );
  }
}