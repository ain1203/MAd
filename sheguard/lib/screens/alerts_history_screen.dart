import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AlertsHistoryScreen (Firebase Management Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDark => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  static const Color _activeRed     = Color(0xFFE53935);
  static const Color _resolvedGreen = Color(0xFF43A047);

  /// Resolves an alert in Firestore
  Future<void> _resolveAlert(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(docId).update({
        'status': 'resolved',
      });
    } catch (e) {
      debugPrint("Error resolving alert: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('userId', isEqualTo: UserSession.uid) // Filter by current user
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          // Sort client-side to avoid index requirement
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTs = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

          return _buildDashboard(sortedDocs);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: const Text(
        'Alert Management',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(18),
        child: Container(
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(List<QueryDocumentSnapshot> docs) {
    // Calculate stats
    int total = docs.length;
    int active = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'active').length;
    int resolved = total - active;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: docs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildStatsRow(total, active, resolved);
        
        final doc = docs[index - 1];
        final data = doc.data() as Map<String, dynamic>;
        return _buildAlertCard(doc.id, data);
      },
    );
  }

  Widget _buildStatsRow(int total, int active, int resolved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatChip('Active', active, _activeRed, _activeRed.withOpacity(0.1))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatChip('Resolved', resolved, _resolvedGreen, _resolvedGreen.withOpacity(0.1))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatChip('Total', total, Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.1))),
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

  Widget _buildAlertCard(String id, Map<String, dynamic> data) {
    final String type = data['type'] ?? 'SOS';
    final String name = data['userName'] ?? 'Unknown User';
    final String status = data['status'] ?? 'active';
    final double lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    final double lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    
    final String timeStr = ts != null 
        ? DateFormat('MMM d, h:mm a').format(ts.toDate()) 
        : 'Recently';

    final bool isActive = status == 'active';
    final meta = _getMeta(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22, 
                  backgroundColor: meta.iconBg, 
                  child: Icon(meta.icon, color: meta.iconColor, size: 22)
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
                          _buildStatusBadge(isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(meta.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: meta.iconColor)),
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time_rounded, timeStr),
                      const SizedBox(height: 4),
                      _infoRow(Icons.location_on_outlined, "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isActive ? () => _resolveAlert(id) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? _primary : Colors.grey.shade100,
                  foregroundColor: isActive ? Colors.white : _textMuted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isActive ? "Mark as Resolved" : "Alert Resolved",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textMuted),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: _textMuted)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _activeRed.withOpacity(0.1) : _resolvedGreen.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'RESOLVED', 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? _activeRed : _resolvedGreen)
      ),
    );
  }

  _AlertMeta _getMeta(String type) {
    if (type == 'FAKE_CALL') {
      return const _AlertMeta(
        icon: Icons.phone_callback_rounded,
        iconColor: Color(0xFF1565C0),
        iconBg: Color(0xFFE3F2FD),
        title: 'Fake Call Triggered',
      );
    }
    return const _AlertMeta(
      icon: Icons.warning_amber_rounded,
      iconColor: _activeRed,
      iconBg: Color(0xFFFFEBEE),
      title: 'Emergency SOS Triggered',
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: _primary),
          const SizedBox(height: 16),
          const Text('No alerts found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Real-time alerts will appear here.', style: TextStyle(color: _textMuted)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text("Error loading alerts. Check permissions."));
  }
}

class _AlertMeta {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  const _AlertMeta({required this.icon, required this.iconColor, required this.iconBg, required this.title});
}