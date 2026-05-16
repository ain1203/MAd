import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Tab 1 Logic ────────────────────────────────────────────────────────────

  Future<void> _handleSearch() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    final user = await ContactService.searchUserByEmail(email);

    setState(() {
      _isSearching = false;
      _foundUser = user;
    });

    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found or not registered")),
      );
    }
  }

  Future<void> _addMember() async {
    if (_foundUser == null) return;
    try {
      await ContactService.addCircleMember(_foundUser!);
      setState(() {
        _foundUser = null;
        _searchController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member added to your circle!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // ── Tab 2 Logic ────────────────────────────────────────────────────────────

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: const Text(
            "Safety Circle",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: "My Contacts", icon: Icon(Icons.people_alt_rounded)),
              Tab(text: "SOS Alerts", icon: Icon(Icons.warning_amber_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContactsTab(),
            _buildAlertsTab(),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: My Contacts ─────────────────────────────────────────────────────
  Widget _buildContactsTab() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ContactService.getCircleStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyState(
                  Icons.person_add_disabled_rounded,
                  "No contacts added.\nSearch above to add registered users.",
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildContactCard(data, docs[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Enter user email...",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                onPressed: _isSearching ? null : _handleSearch,
                child: _isSearching
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Search", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_foundUser != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(_foundUser!['fullName'][0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_foundUser!['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_foundUser!['email'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Add"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> data, String docId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: data['photoURL'] != null ? NetworkImage(data['photoURL']) : null,
          child: data['photoURL'] == null ? Text(data['name'][0].toUpperCase()) : null,
        ),
        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['email'] ?? data['phone'] ?? ""),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => ContactService.deleteCircleMember(docId),
        ),
      ),
    );
  }

  // ── Tab 2: SOS Alerts (Filtered by Circle) ────────────────────────────────
  Widget _buildAlertsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: ContactService.getCircleStream(),
      builder: (context, contactSnapshot) {
        if (contactSnapshot.hasError) return _buildErrorState(contactSnapshot.error!);
        if (contactSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contactDocs = contactSnapshot.data?.docs ?? [];
        if (contactDocs.isEmpty) {
          return _buildEmptyState(
            Icons.people_outline,
            "Your circle is empty.\nAdd contacts to see their alerts.",
          );
        }

        // Extract UIDs of circle members (Firestore whereIn limited to 10)
        final List<String> contactUids = contactDocs
            .map((doc) => (doc.data() as Map<String, dynamic>)['uid'] as String)
            .take(10)
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('alerts')
              .where('userId', whereIn: contactUids)
              .snapshots(),
          builder: (context, alertSnapshot) {
            if (alertSnapshot.hasError) {
              debugPrint("❌ Alert Stream Error: ${alertSnapshot.error}");
              return _buildErrorState(alertSnapshot.error!);
            }
            if (alertSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = alertSnapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _buildEmptyState(
                Icons.notifications_off_rounded,
                "No emergency alerts from your circle.",
              );
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final data = sortedDocs[index].data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final dateStr = timestamp != null
                    ? DateFormat('hh:mm a, dd MMM').format(timestamp.toDate())
                    : 'Now';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.warning_rounded, color: Colors.red),
                        ),
                        title: Text(
                          data['userName'] ?? "Unknown User",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Alert Type: ${data['type'] ?? 'SOS'}"),
                            Text("Time: $dateStr", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "ACTIVE",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openMap(data['lat'], data['lng']),
                              icon: const Icon(Icons.location_on, color: Colors.blue),
                              label: const Text("View Location", style: TextStyle(color: Colors.blue)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text("Stream Error", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}