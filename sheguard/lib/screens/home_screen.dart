import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_session.dart';
import '../services/alert_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Import all screens
import 'safety_bot_screen.dart';
import 'circle_screen.dart';
import 'alerts_history_screen.dart';
import 'safety_tips_screen.dart';
import 'fake_call_screen.dart';
import 'profile_screen.dart';
import 'chat_users_screen.dart';

import '../services/panic_shake_service.dart';
import 'incoming_call_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HomeScreen (Main Wrapper)
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize Panic Shake Detection
    PanicShakeService().startListening(
      onShake: _handleShakeTrigger,
    );
  }

  @override
  void dispose() {
    PanicShakeService().stopListening();
    super.dispose();
  }

  void _handleShakeTrigger() async {
    if (!mounted) return;
    await _triggerFakeCallDistraction();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted && _selectedNavIndex == 0) {
      _showShakeSosDialog();
    }
  }

  void _showShakeSosDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 SOS Triggered',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('We have sent your location to your contacts.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SafeHerColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerFakeCallDistraction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomingCallScreen(
          callerName: "Mom",
          callerNumber: "+92 300 1234567",
          callerAudio: "assets/audio/mom_voice.mp3",
        ),
      ),
    );
  }

  void _showProfileDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: UserSession.profileImageUrl != null
                    ? NetworkImage(UserSession.profileImageUrl!)
                    : null,
                child: UserSession.profileImageUrl == null
                    ? Text(UserSession.displayName[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 32, fontWeight: FontWeight.bold))
                    : null),
            const SizedBox(height: 16),
            Text(UserSession.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(UserSession.email, style: const TextStyle(fontSize: 13, color: SafeHerColors.textMuted)),
            const SizedBox(height: 24),
            _profileAction(
                icon: Icons.person_outline_rounded,
                label: 'My Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
            _profileAction(
                icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onTap: () {
                  themeProvider.toggleTheme();
                  Navigator.pop(context);
                }),
            const Divider(height: 32),
            _profileAction(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: SafeHerColors.emergencyRed,
                onTap: () async {
                  await FirebaseAuthService().signOut();
                  UserSession.clearSession();
                  if (!mounted) return;
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  Widget _profileAction({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return ListTile(
        leading: Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 22),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
  }

  final List<Widget> _tabs = [
    const HomeTabContent(),
    const ChatbotPage(),
    const CircleScreen(),
    const AlertsHistoryScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: SafeHerColors.primaryLight,
            child: Text(UserSession.displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          onPressed: _showProfileDialog,
        ),
        title: Text(
          'SafeHer',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor ?? Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.forum_rounded, color: theme.appBarTheme.foregroundColor ?? Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatUsersScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Circle'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HomeTabContent (Fixed Helplines Directory)
// ─────────────────────────────────────────────────────────────────────────────
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent>
    with SingleTickerProviderStateMixin {
  bool _sosActivated = false;
  bool _sosHolding = false;
  double _sosProgress = 0.0;
  Timer? _sosTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<Color> _palette = [
    Color(0xFF7B1FA2), Color(0xFFAD1457), Color(0xFF1565C0),
    Color(0xFF2E7D32), Color(0xFFE65100), Color(0xFF00838F),
  ];

  final List<Map<String, String>> _helplines = [
    {"name": "Ambulance", "number": "115"},
    {"name": "Police Emergency", "number": "15"},
    {"name": "Child Protection", "number": "1121"},
    {"name": "Rescue 1122", "number": "04299231701"},
    {"name": "Firefighting", "number": "16"},
    {"name": "PM Youth Loan", "number": "080077000"},
    {"name": "Zimmedar Shehri", "number": "080002345"},
    {"name": "Punjab Youth Line", "number": "080012145"},
    {"name": "PDMA", "number": "1129"},
    {"name": "Punjab Health Line", "number": "080099000"},
    {"name": "Livestock", "number": "080078686"},
    {"name": "Punjab Women Helpline", "number": "1043"},
    {"name": "Edhi Ambulance", "number": "04237847050"},
    {"name": "Halal-e-Ahmar", "number": "1030"},
    {"name": "Dastak Crisis Centre", "number": "04235763237"},
    {"name": "Madadgaar Helpline", "number": "1098"},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialer")),
        );
      }
    }
  }

  void _showHelplineDialog(String name, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contact_phone, size: 48, color: SafeHerColors.primary),
            const SizedBox(height: 16),
            Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _makeCall(number);
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onSosLongPressStart(LongPressStartDetails _) {
    setState(() { _sosHolding = true; _sosProgress = 0.0; });
    _sosTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _sosProgress += 50 / 3000;
        if (_sosProgress >= 1.0) {
          _sosProgress = 1.0;
          _sosActivated = true;
          _sosHolding = false;
          t.cancel();
          HapticFeedback.heavyImpact();
          AlertService.sendAlert("SOS");
          _showSosDialog();
        }
      });
    });
  }

  void _onSosLongPressEnd(LongPressEndDetails _) {
    _sosTimer?.cancel();
    if (!_sosActivated) setState(() { _sosHolding = false; _sosProgress = 0.0; });
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 SOS Triggered', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('We have sent your location to your contacts.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SafeHerColors.primary),
            onPressed: () {
              Navigator.pop(context);
              setState(() { _sosActivated = false; _sosProgress = 0.0; });
            },
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSosSection(),
          _buildTapHint(),
          _buildQuickActions(),
          _buildSectionTitle('Govt Helplines'),
          _buildHelplinesDirectory(),
          _buildDailyTip(),
        ],
      ),
    );
  }

  Widget _buildSosSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: GestureDetector(
          onLongPressStart: _onSosLongPressStart,
          onLongPressEnd: _onSosLongPressEnd,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(scale: _sosHolding ? 1.0 : _pulseAnimation.value, child: child),
            child: SizedBox(
              width: 170, height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170, height: 170,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.25), Theme.of(context).primaryColor.withOpacity(0.0)])),
                  ),
                  Container(
                    width: 145, height: 145,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).primaryColor, Theme.of(context).primaryColorDark]), boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.55), blurRadius: 30, spreadRadius: 4)]),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SOS', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)), Text('HOLD 3 SEC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]),
                  ),
                  if (_sosHolding) SizedBox(width: 145, height: 145, child: CircularProgressIndicator(value: _sosProgress, strokeWidth: 4, color: SafeHerColors.sosPink, backgroundColor: Colors.white.withOpacity(0.2))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text('Tap and hold in case of emergency. Your location will be shared instantly.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13, height: 1.5)),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickActionItem(Icons.phone_callback_rounded, 'Fake Call', Colors.blue, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const FakeCallScreen())); }),
          _quickActionItem(Icons.shield_outlined, 'Safety Tips', Colors.orange, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyTipsScreen())); }),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildHelplinesDirectory() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _helplines.length,
        itemBuilder: (context, index) {
          final helpline = _helplines[index];
          return _buildHelplineCard(helpline['name']!, helpline['number']!, _palette[index % _palette.length]);
        },
      ),
    );
  }

  Widget _buildHelplineCard(String name, String number, Color color) {
    return GestureDetector(
      onTap: () => _showHelplineDialog(name, number),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.emergency_outlined, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            Text(number, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTip() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)])), child: const Row(children: [Icon(Icons.lightbulb_rounded, color: Colors.amber), SizedBox(width: 14), Expanded(child: Text('Keep your phone charged and location services on while traveling.', style: TextStyle(color: Colors.white, fontSize: 13)))]),
    ),
    );
  }
}