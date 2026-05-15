import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_session.dart';
import '../services/alert_service.dart';
import '../services/contact_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Import all screens
import 'circle_screen.dart';
import 'alerts_history_screen.dart';
import 'safety_tips_screen.dart';
import 'fake_call_screen.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SafeHer – Brand tokens
// ─────────────────────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────────────────────
//  Emergency Contact model
// ─────────────────────────────────────────────────────────────────────────────
class EmergencyContact {
  final String name;
  final String phone;
  final Color avatarColor;
  EmergencyContact({required this.name, required this.phone, required this.avatarColor});
}

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

  // List of tabs
  final List<Widget> _tabs = [
    const HomeTabContent(),
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedNavIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        backgroundColor: Colors.white,
        selectedItemColor: SafeHerColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded), label: 'Circle'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HomeTabContent (Extracted from old HomeScreen)
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

  // Replaced local list with Firestore stream

  static const List<Color> _palette = [
    Color(0xFF7B1FA2),
    Color(0xFFAD1457),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF00838F),
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

  // ── SOS ───────────────────────────────────────────────────────────────────
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
          // Trigger the unified emergency alert
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
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 SOS Activated',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Your location and status have been shared with your emergency contacts.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _sosActivated = false; _sosProgress = 0.0; });
            },
            child: const Text('Cancel Alert',
                style: TextStyle(color: SafeHerColors.emergencyRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SafeHerColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Add Contact ────────────────────────────────────────────────────────────
  void _showAddContactSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24, left: 24, right: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeHerColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      ContactService.addEmergencyContact(
                        nameCtrl.text.trim(),
                        phoneCtrl.text.trim(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageContactsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Manage Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ContactService.getEmergencyStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('No contacts to manage'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SafeHerColors.primary.withOpacity(0.1),
                          child: Text(data['name']?[0] ?? '?', style: const TextStyle(color: SafeHerColors.primary)),
                        ),
                        title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(data['phone'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showEditContactSheet(docId, data['name'], data['phone']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(docId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactSheet(String id, String initialName, String initialPhone) {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24, left: 24, right: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeHerColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      ContactService.updateEmergencyContact(id, nameCtrl.text.trim(), phoneCtrl.text.trim());
                      Navigator.pop(context); // Close edit sheet
                    }
                  },
                  child: const Text('Update Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ContactService.deleteEmergencyContact(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required TextInputType keyboard,
    required String? Function(String?) validator,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: SafeHerColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: Icon(icon, size: 20, color: SafeHerColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SafeHerColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
        backgroundColor: Theme.of(context).cardColor,
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
                  : null,
            ),
            const SizedBox(height: 16),
            Text(UserSession.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(UserSession.email, style: const TextStyle(fontSize: 13, color: SafeHerColors.textMuted)),
            const SizedBox(height: 24),
            
            // My Profile Button
            _profileAction(
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            
            // Theme Toggle
            _profileAction(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onTap: () {
                themeProvider.toggleTheme();
                Navigator.pop(context);
              },
            ),
            
            const Divider(height: 32),
            
            // Logout Button
            _profileAction(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: SafeHerColors.emergencyRed,
              onTap: () async {
                await FirebaseAuthService().signOut();
                UserSession.clearSession();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully'), backgroundColor: SafeHerColors.primary),
                );
              },
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSosSection(),
              _buildTapHint(),
              _buildQuickActions(),
              _buildSectionTitle(
                'Emergency Contacts', 
                trailingLabel: 'Edit',
                onTrailingTap: _showManageContactsSheet,
              ),
              _buildEmergencyContacts(),
              _buildDailyTip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SafeHer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SafeHerColors.primary)),
                Text('Welcome, ${UserSession.displayName}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SafeHerColors.textDark)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showProfileDialog,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: SafeHerColors.primaryLight,
              child: Text(UserSession.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
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
            builder: (_, child) => Transform.scale(
              scale: _sosHolding ? 1.0 : _pulseAnimation.value,
              child: child,
            ),
            child: SizedBox(
              width: 170, height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170, height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Theme.of(context).primaryColor.withOpacity(0.25),
                        Theme.of(context).primaryColor.withOpacity(0.0),
                      ]),
                    ),
                  ),
                  Container(
                    width: 145, height: 145,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColorDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.55), blurRadius: 30, spreadRadius: 4),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SOS', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
                        Text('HOLD 3 SEC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (_sosHolding)
                    SizedBox(
                      width: 145, height: 145,
                      child: CircularProgressIndicator(
                        value: _sosProgress,
                        strokeWidth: 4,
                        color: SafeHerColors.sosPink,
                        backgroundColor: Colors.white.withOpacity(0.2),
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

  Widget _buildTapHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'Tap and hold in case of emergency. Your location will be shared instantly.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickActionItem(Icons.phone_callback_rounded, 'Fake Call', Colors.blue, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const FakeCallScreen()));
          }),
          _quickActionItem(Icons.shield_outlined, 'Safety Tips', Colors.orange, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyTipsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? trailingLabel, VoidCallback? onTrailingTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(trailingLabel, style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600))
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return SizedBox(
      height: 94,
      child: StreamBuilder<QuerySnapshot>(
        stream: ContactService.getEmergencyStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("❌ Firestore Stream Error: ${snapshot.error}");
            return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 20));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
             return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [_buildAddContactButton()],
            );
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildAddContactButton(),
              ...docs.asMap().entries.map((entry) {
                final data = entry.value.data() as Map<String, dynamic>;
                return _buildContactAvatar(
                  data['name'] ?? 'User',
                  _palette[entry.key % _palette.length],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddContactButton() {
    return GestureDetector(
      onTap: _showAddContactSheet,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 2), 
                color: Theme.of(context).primaryColor.withOpacity(0.1)
              ),
              child: Icon(Icons.add, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 6),
            Text('Add', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white))),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
        ),
        child: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: Colors.amber),
            SizedBox(width: 14),
            Expanded(child: Text('Keep your phone charged and location services on while traveling.', style: TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}