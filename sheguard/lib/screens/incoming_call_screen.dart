import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'active_fake_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String callerAudio;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.callerAudio,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isVibrating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playRingtone();
    _startVibration();
  }

  void _playRingtone() {
    try {
      FlutterRingtonePlayer().playRingtone(
        looping: true,
        asAlarm: false,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint("Error playing ringtone: $e");
    }
  }

  Future<void> _startVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      _isVibrating = true;
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    }
  }

  void _stopEffects() {
    FlutterRingtonePlayer().stop();
    if (_isVibrating) {
      Vibration.cancel();
    }
  }

  @override
  void dispose() {
    _stopEffects();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Colors.blueGrey.withOpacity(0.2),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Caller Name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Phone Number
                Text(
                  widget.callerNumber,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 30),
                // Incoming Call Text
                const Text(
                  "Incoming Call",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4.0,
                  ),
                ),
                
                const Spacer(),
                
                // Call Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline Button
                      _buildCallAction(
                        icon: Icons.call_end,
                        label: "Decline",
                        color: Colors.redAccent,
                        onTap: () {
                          _stopEffects();
                          Navigator.pop(context);
                        },
                      ),
                      
                      // Accept Button with Pulse Animation
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: _buildCallAction(
                          icon: Icons.call,
                          label: "Accept",
                          color: Colors.greenAccent.shade700,
                          onTap: () {
                            _stopEffects();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveFakeCallScreen(
                                  callerName: widget.callerName,
                                  callerNumber: widget.callerNumber,
                                  callerAudio: widget.callerAudio,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
