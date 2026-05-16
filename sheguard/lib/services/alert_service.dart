import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'user_session.dart';

class AlertService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sends an emergency alert to Firestore with location data.
  /// Does not throw errors to prevent UI freezes.
  static Future<void> sendAlert(String type) async {
    try {
      debugPrint('AlertService: Sending $type alert...');

      // 1. Get Location (Safe Permission Handling)
      Position? position = await _getCurrentLocation();
      
      // 2. Prepare Data
      final alertData = {
        'type': type,
        'userId': UserSession.uid,
        'userName': UserSession.displayName,
        'email': UserSession.email,
        'lat': position?.latitude ?? 0.0,
        'lng': position?.longitude ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // 3. Save to Firestore
      await _db.collection('alerts').add(alertData);
      
      debugPrint('AlertService: $type alert sent successfully.');
    } catch (e) {
      debugPrint('AlertService Error: $e');
      // Fail silently to the user to prevent app crashes during emergencies
    }
  }

  /// Internal helper to get location with strict permission checks
  static Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      // Fetch position with a timeout to avoid hanging indefinitely
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('AlertService Location Error: $e');
      return null;
    }
  }
}
