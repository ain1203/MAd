import 'dart:async';
import 'package:flutter/material.dart';
import 'incoming_call_screen.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final List<Map<String, String>> _fakeCallers = [
    {"name": "Mom", "number": "+92 300 1234567", "audio": "assets/audio/mom_voice.mp3"},
    {"name": "Dad", "number": "+92 301 7654321", "audio": "assets/audio/dad_voice.mp3"},
    {"name": "Sister", "number": "+92 302 9876543", "audio": "assets/audio/sister_voice.mp3"},
    {"name": "Brother", "number": "+92 303 1112233", "audio": "assets/audio/brother_voice.mp3"},
  ];

  late Map<String, String> _selectedCaller;
  int _selectedTimer = 5; // seconds
  final List<int> _timers = [5, 10, 30, 60, 300];
  bool _isScheduling = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _selectedCaller = _fakeCallers[0];
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _triggerFakeCall() {
    setState(() {
      _isScheduling = true;
    });

    _countdownTimer = Timer(Duration(seconds: _selectedTimer), () {
      if (mounted) {
        setState(() {
          _isScheduling = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(
              callerName: _selectedCaller['name']!,
              callerNumber: _selectedCaller['number']!,
              callerAudio: _selectedCaller['audio']!,
            ),
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Fake call from ${_selectedCaller['name']} scheduled in $_selectedTimer seconds."),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Fake Call Setup",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blueGrey.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Exit Uncomfortable Situations",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Schedule a realistic fake call to help you leave safely and discreetly.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Caller Selection
              _buildSectionTitle("Select Caller Identity"),
              const SizedBox(height: 12),
              _buildCallerSelector(),
              
              const SizedBox(height: 32),
              
              // Timer Selection
              _buildSectionTitle("Trigger Delay"),
              const SizedBox(height: 12),
              _buildTimerSelector(),
              
              const Spacer(),
              
              // Schedule Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isScheduling ? null : _triggerFakeCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                  ),
                  child: _isScheduling
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Schedule Fake Call",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent.withOpacity(0.8),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCallerSelector() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fakeCallers.length,
        itemBuilder: (context, index) {
          final caller = _fakeCallers[index];
          final isSelected = _selectedCaller == caller;
          return GestureDetector(
            onTap: () => setState(() => _selectedCaller = caller),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caller['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timers.map((timer) {
        final isSelected = _selectedTimer == timer;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimer = timer),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              timer < 60 ? "$timer sec" : "${timer ~/ 60} min",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
