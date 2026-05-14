import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  const IncomingCallScreen({super.key, required this.callerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                callerName,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Incoming Call...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCallButton(Icons.call_end, "Decline", Colors.red, () {
                      AwesomeNotifications().dismiss(10);
                      Navigator.pop(context);
                    }),
                    _buildCallButton(Icons.call, "Accept", Colors.green, () {
                      AwesomeNotifications().dismiss(10);
                      // Logic for accepting call (show active call UI)
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
