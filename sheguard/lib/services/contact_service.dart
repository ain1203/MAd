import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ContactService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current user's UID or throws if not logged in
  static String get _uid => _auth.currentUser?.uid ?? (throw Exception("User not logged in"));

  /// Collection reference for the user's contacts
  static CollectionReference get _contactsRef => 
      _db.collection('users').doc(_uid).collection('contacts');

  /// Adds a new emergency contact to Firestore
  static Future<void> addContact(String name, String phone) async {
    try {
      await _contactsRef.add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Contact added: $name");
    } catch (e) {
      debugPrint("Error adding contact: $e");
      rethrow;
    }
  }

  /// Deletes a contact from Firestore
  static Future<void> deleteContact(String contactId) async {
    try {
      await _contactsRef.doc(contactId).delete();
      debugPrint("Contact deleted: $contactId");
    } catch (e) {
      debugPrint("Error deleting contact: $e");
      rethrow;
    }
  }

  /// Returns a real-time stream of the user's emergency contacts
  static Stream<QuerySnapshot> getContactsStream() {
    return _contactsRef.orderBy('createdAt', descending: true).snapshots();
  }
}
