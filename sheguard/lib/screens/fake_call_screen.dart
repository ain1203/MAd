import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'incoming_call_screen.dart';
import '../services/alert_service.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  String _selectedCaller = "Police (Emergency)";
  int _selectedTimer = 5; // seconds

  final List<String> _callers = ["Police (Emergency)", "Mom", "Dad", "Boss", "Friend"];
  final List<int> _timers = [5, 10, 30, 60, 300];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  void _requestNotificationPermissions() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> _triggerFakeCall() async {
    // Schedule notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'fake_call_channel',
        title: 'Incoming Call',
        body: 'From $_selectedCaller',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        backgroundColor: const Color(0xFF6A1B9A),
        payload: {'caller': _selectedCaller},
      ),
      actionButtons: [
        NotificationActionButton(key: 'ACCEPT', label: 'Accept', color: Colors.green, autoDismissible: true),
        NotificationActionButton(key: 'DECLINE', label: 'Decline', color: Colors.red, autoDismissible: true),
      ],
      schedule: NotificationInterval(
        interval: Duration(seconds: _selectedTimer),
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        preciseAlarm: true,
        repeats: false,
      ),
    );

    // Trigger the unified emergency alert for Fake Call
    AlertService.sendAlert("FAKE_CALL");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fake call from $_selectedCaller scheduled in $_selectedTimer seconds."),
          backgroundColor: const Color(0xFF6A1B9A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        title: const Text("Fake Call Setup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Schedule a fake call to exit uncomfortable situations safely.", 
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 32),
            _buildDropdown<String>("Select Caller Identity", _selectedCaller, _callers, (v) => setState(() => _selectedCaller = v!)),
            const SizedBox(height: 24),
            _buildDropdown<int>("Trigger After", _selectedTimer, _timers, (v) => setState(() => _selectedTimer = v!), 
              itemToString: (v) => v < 60 ? "$v seconds" : "${v ~/ 60} minutes"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _triggerFakeCall,
                icon: const Icon(Icons.phone_callback_rounded, color: Colors.white),
                label: const Text("Schedule Fake Call", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged, {String Function(T)? itemToString}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemToString?.call(e) ?? e.toString()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
