import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ContactService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current user's UID or throws if not logged in
  static String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("🚨 CONTACT SERVICE ERROR: No user logged in!");
      throw Exception("User not logged in");
    }
    return uid;
  }

  /// ─── EMERGENCY CONTACTS COLLECTION ───
  /// Path: users/{uid}/emergency_contacts
  static CollectionReference get _emergencyRef =>
      _db.collection('users').doc(_uid).collection('emergency_contacts');

  /// ─── CREATE ───
  static Future<void> addEmergencyContact(String name, String phone) async {
    try {
      final uid = _uid;
      final docRef = await _emergencyRef.add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // LOG EVERYTHING FOR THE USER TO SEE IN DEBUG CONSOLE
      debugPrint("✅ SUCCESS: DATA WRITTEN TO BACKEND");
      debugPrint("📍 Project: safeher-95681");
      debugPrint("📍 Collection: users");
      debugPrint("📍 Document (UID): $uid");
      debugPrint("📍 Sub-Collection: emergency_contacts");
      debugPrint("📍 Document ID: ${docRef.id}");
      debugPrint("------------------------------------------");
    } catch (e) {
      debugPrint("❌ FIREBASE WRITE ERROR: $e");
      rethrow;
    }
  }

  /// ─── READ (Real-time Stream) ───
  static Stream<QuerySnapshot> getEmergencyStream() {
    return _emergencyRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// ─── UPDATE ───
  static Future<void> updateEmergencyContact(String docId, String name, String phone) async {
    try {
      await _emergencyRef.doc(docId).update({
        'name': name,
        'phone': phone,
      });
      debugPrint("📝 Contact Updated in Backend: $docId");
    } catch (e) {
      debugPrint("❌ FIREBASE UPDATE ERROR: $e");
      rethrow;
    }
  }

  /// ─── DELETE ───
  static Future<void> deleteEmergencyContact(String docId) async {
    try {
      await _emergencyRef.doc(docId).delete();
      debugPrint("🗑️ Contact Deleted from Backend: $docId");
    } catch (e) {
      debugPrint("❌ FIREBASE DELETE ERROR: $e");
      rethrow;
    }
  }

  /// ─── CIRCLE CONTACTS (Legacy Support) ───
  static CollectionReference get _circleRef =>
      _db.collection('users').doc(_uid).collection('circle_contacts');

  static Stream<QuerySnapshot> getCircleStream() {
    return _circleRef.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> addCircleContact(String name, String phone) async {
    try {
      final uid = _uid;
      final docRef = await _circleRef.add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ SUCCESS: CIRCLE CONTACT WRITTEN TO BACKEND");
      debugPrint("📍 Project: safeher-95681");
      debugPrint("📍 Firestore Path: users/$uid/circle_contacts/${docRef.id}");
    } catch (e) {
      debugPrint("❌ FIREBASE CIRCLE WRITE ERROR: $e");
      rethrow;
    }
  }
  
  static Future<void> deleteCircleContact(String docId) async {
    try {
      await _circleRef.doc(docId).delete();
      debugPrint("🗑️ Circle contact deleted from Backend: $docId");
    } catch (e) {
      debugPrint("❌ FIREBASE DELETE ERROR: $e");
      rethrow;
    }
  }

  /// ─── UPDATE CIRCLE ───
  static Future<void> updateCircleContact(String docId, String name, String phone) async {
    try {
      await _circleRef.doc(docId).update({
        'name': name,
        'phone': phone,
      });
      debugPrint("📝 Circle contact updated in Backend: $docId");
    } catch (e) {
      debugPrint("❌ FIREBASE UPDATE ERROR: $e");
      rethrow;
    }
  }
}
