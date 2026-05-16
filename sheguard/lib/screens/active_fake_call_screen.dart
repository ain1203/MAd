import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class ActiveFakeCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String callerAudio;

  const ActiveFakeCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.callerAudio,
  });

  @override
  State<ActiveFakeCallScreen> createState() => _ActiveFakeCallScreenState();
}

class _ActiveFakeCallScreenState extends State<ActiveFakeCallScreen> {
  int _secondsElapsed = 0;
  late Timer _timer;
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Start the call timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    // Start voice playback with a slight delay for realism
    _playVoice();
  }

  Future<void> _playVoice() async {
    try {
      // AudioPlayer expects asset path without 'assets/' prefix when using AssetSource
      final cleanPath = widget.callerAudio.replaceFirst('assets/', '');
      debugPrint("Attempting to play: $cleanPath");
      
      // Explicitly set source and wait
      await _audioPlayer.setSource(AssetSource(cleanPath));
      
      // Delay to allow Android MediaPlayer to prepare the asset
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        await _audioPlayer.resume();
        debugPrint("Playback resume called");
      }
    } catch (e) {
      debugPrint("Error playing voice audio: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      // Caller Info
                      Text(
                        widget.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.callerNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _formatDuration(_secondsElapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  
                  // Voice Wave Animation Removed as requested
                  const SizedBox(height: 100),
                  
                  // Call Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlBtn(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              label: "Mute",
                              isActive: _isMuted,
                              onTap: () => setState(() => _isMuted = !_isMuted),
                            ),
                            _buildControlBtn(
                              icon: Icons.grid_view_rounded,
                              label: "Keypad",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildControlBtn(
                              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                              label: "Speaker",
                              isActive: _isSpeakerOn,
                              onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlBtn(
                              icon: Icons.add,
                              label: "Add Call",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildControlBtn(
                              icon: Icons.videocam_off,
                              label: "Video",
                              isActive: false,
                              onTap: () {},
                            ),
                            _buildControlBtn(
                              icon: Icons.person,
                              label: "Contacts",
                              isActive: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // End Call Button
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _audioPlayer.stop();
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: Container(
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "End Call",
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
