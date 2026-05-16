import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ChatUsersScreen extends StatelessWidget {
  const ChatUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        iconTheme: IconThemeData(color: theme.brightness == Brightness.light ? SafeHerColors.primary : Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService.getCircleContactsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text('Error loading contacts', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(snapshot.error.toString(), style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          
          // Client-side sorting by name
          final contacts = docs.toList()..sort((a, b) {
            final aName = (a.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
            final bName = (b.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
            return aName.compareTo(bName);
          });

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('No Safety Circle contacts yet.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  Text('Add members to start chatting!', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contact = contacts[index].data() as Map<String, dynamic>;
              return _buildContactTile(context, contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, Map<String, dynamic> contact) {
    final theme = Theme.of(context);
    final String name = contact['name'] ?? 'Unknown';
    final String otherUid = contact['uid'] ?? '';
    final String? photoUrl = contact['photoURL'];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: SafeHerColors.primaryLight,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null 
            ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
            : null,
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.brightness == Brightness.light ? SafeHerColors.primary : Colors.white70),
        onTap: () {
          // Initialize chat and navigate
          ChatService.createChatIfNotExists(otherUid, name);
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUid: otherUid,
                otherName: name,
                otherPhoto: photoUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
