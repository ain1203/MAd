import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _currentUid => _auth.currentUser!.uid;

  /// Generate a consistent Chat ID between two users
  static String getChatId(String otherUid) {
    List<String> ids = [_currentUid, otherUid];
    ids.sort();
    return ids.join('_');
  }

  /// ─── CHAT CONTEXT ───
  static Future<void> createChatIfNotExists(String otherUid, String otherName) async {
    final chatId = getChatId(otherUid);
    final chatRef = _db.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'participants': [_currentUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ─── SENDING MESSAGES (Text Only) ───
  static Future<void> sendMessage({
    required String otherUid,
    required String text,
  }) async {
    final chatId = getChatId(otherUid);
    
    final messageData = {
      'chatId': chatId,
      'senderId': _currentUid,
      'receiverId': otherUid,
      'type': 'text',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _db.collection('messages').add(messageData);

    // Update last message in chat document
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// ─── STREAMS ───
  static Stream<QuerySnapshot> getMessagesStream(String otherUid) {
    final chatId = getChatId(otherUid);
    return _db.collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots();
  }

  static Stream<QuerySnapshot> getCircleContactsStream() {
    return _db.collection('circles').doc(_currentUid).collection('contacts')
        .snapshots();
  }
}
