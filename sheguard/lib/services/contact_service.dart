import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ContactService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current user's UID or throws if not logged in
  static String get _uid => _auth.currentUser?.uid ?? (throw Exception("User not logged in"));

  /// ─── UNIFIED CONTACTS COLLECTION ───
  /// Requirements: users/{uid}/contacts/{contactId}
  static CollectionReference get _contactsRef => 
      _db.collection('users').doc(_uid).collection('contacts');

  /// Adds a new contact to the unified Firestore collection
  static Future<void> addContact(String name, String phone) async {
    try {
      await _contactsRef.add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Contact added successfully to Firestore");
    } catch (e) {
      debugPrint("Error adding contact: $e");
      rethrow;
    }
  }

  /// Deletes a contact from the unified Firestore collection
  static Future<void> deleteContact(String contactId) async {
    try {
      await _contactsRef.doc(contactId).delete();
      debugPrint("Contact deleted: $contactId");
    } catch (e) {
      debugPrint("Error deleting contact: $e");
      rethrow;
    }
  }

  /// Returns a real-time stream of all contacts for the current user
  /// Both HomeScreen and CircleScreen should use this for synchronized data.
  static Stream<QuerySnapshot> getContactsStream() {
    return _contactsRef.orderBy('createdAt', descending: true).snapshots();
  }
}
