import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// AuthPage serves as a toggle between Login and Register screens
/// while remaining within the "Logged Out" state of the AuthWrapper.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  void toggleView() {
    setState(() => showLogin = !showLogin);
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return LoginScreen(onToggle: toggleView); 
    } else {
      return RegisterScreen(onToggle: toggleView);
    }
  }
}
