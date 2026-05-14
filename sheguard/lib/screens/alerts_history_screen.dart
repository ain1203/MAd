import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AlertModel
// ─────────────────────────────────────────────────────────────────────────────
class AlertModel {
  final String id;
  final String alertType;   // e.g. 'SOS', 'FAKE_CALL', 'LOCATION_SHARE'
  final String timestamp;
  final String location;
  final bool isActive;

  const AlertModel({
    required this.id,
    required this.alertType,
    required this.timestamp,
    required this.location,
    required this.isActive,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as String,
      alertType: map['alertType'] as String,
      timestamp: map['timestamp'] as String,
      location: map['location'] as String,
      isActive: map['isActive'] as bool,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AlertsHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  static const Color _primary       = Color(0xFF6A1B9A);
  static const Color _bgColor       = Color(0xFFF3E5F5);
  static const Color _textDark      = Color(0xFF212121);
  static const Color _textMuted     = Color(0xFF757575);
  static const Color _activeRed     = Color(0xFFE53935);
  static const Color _activeBg      = Color(0xFFFFEBEE);
  static const Color _resolvedGreen = Color(0xFF43A047);
  static const Color _resolvedBg    = Color(0xFFE8F5E9);

  final List<AlertModel> _alerts = const [
    AlertModel(
      id: 'alert_001',
      alertType: 'SOS',
      timestamp: 'Today, 11:42 PM',
      location: '23 Maple Street, Downtown',
      isActive: true,
    ),
    AlertModel(
      id: 'alert_002',
      alertType: 'SOS',
      timestamp: 'Yesterday, 08:15 AM',
      location: 'Central Park, North Entrance',
      isActive: false,
    ),
    AlertModel(
      id: 'alert_003',
      alertType: 'FAKE_CALL',
      timestamp: 'May 10, 2026 – 06:55 PM',
      location: 'Westfield Shopping Centre',
      isActive: false,
    ),
    AlertModel(
      id: 'alert_004',
      alertType: 'SOS',
      timestamp: 'May 8, 2026 – 02:30 AM',
      location: '7th Ave & W 34th St, Midtown',
      isActive: true,
    ),
  ];

  bool _isRefreshing = false;

  Future<void> _refreshAlerts() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isRefreshing = false);
  }

  _AlertMeta _metaFor(AlertModel alert) {
    switch (alert.alertType) {
      case 'FAKE_CALL':
        return const _AlertMeta(
          icon: Icons.phone_in_talk_rounded,
          iconColor: Color(0xFF1565C0),
          iconBg: Color(0xFFE3F2FD),
          title: 'Fake Call Triggered',
        );
      case 'LOCATION_SHARE':
        return const _AlertMeta(
          icon: Icons.location_on_rounded,
          iconColor: Color(0xFF2E7D32),
          iconBg: Color(0xFFE8F5E9),
          title: 'Location Shared',
        );
      case 'SOS':
      default:
        return const _AlertMeta(
          icon: Icons.warning_amber_rounded,
          iconColor: _activeRed,
          iconBg: Color(0xFFFFEBEE),
          title: 'Emergency SOS Triggered',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _refreshAlerts,
        child: _alerts.isEmpty ? _buildEmptyState() : _buildList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: const Text(
        'Alert History',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (_alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_alerts.length} total',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(18),
        child: Container(
          height: 18,
          decoration: const BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final activeCount   = _alerts.where((a) => a.isActive).length;
    final resolvedCount = _alerts.where((a) => !a.isActive).length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _alerts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildStatsRow(activeCount, resolvedCount);
        return _buildAlertCard(_alerts[index - 1]);
      },
    );
  }

  Widget _buildStatsRow(int active, int resolved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatChip('Active', active, _activeRed, _activeBg)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatChip('Resolved', resolved, _resolvedGreen, _resolvedBg)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatChip('Total', active + resolved, _primary, const Color(0xFFEDE7F6))),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    final meta = _metaFor(alert);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 24, backgroundColor: meta.iconBg, child: Icon(meta.icon, color: meta.iconColor, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(meta.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark, height: 1.3))),
                      const SizedBox(width: 8),
                      _buildStatusBadge(alert.isActive),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(alert.timestamp, style: const TextStyle(fontSize: 13, color: _textMuted)),
                  const SizedBox(height: 4),
                  Text(alert.location, style: const TextStyle(fontSize: 13, color: _textMuted), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: isActive ? _activeBg : _resolvedBg, borderRadius: BorderRadius.circular(8)),
      child: Text(isActive ? 'ACTIVE' : 'RESOLVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? _activeRed : _resolvedGreen)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: _primary),
          const SizedBox(height: 16),
          const Text('No alerts recorded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your activity will appear here.', style: TextStyle(color: _textMuted)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _refreshAlerts, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _AlertMeta {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  const _AlertMeta({required this.icon, required this.iconColor, required this.iconBg, required this.title});
}