import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'alert_service.dart';

class PanicShakeService {
  static final PanicShakeService _instance = PanicShakeService._internal();
  factory PanicShakeService() => _instance;
  PanicShakeService._internal();

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  
  // Shake detection parameters
  static const double shakeThreshold = 30.0; // Higher intensity for better accuracy
  static const int cooldownSeconds = 15;
  
  DateTime? _lastTriggerTime;
  VoidCallback? _onShakeTriggered;

  /// Starts listening for shake gestures.
  /// [onShake] callback is optional and can be used to trigger UI changes or Fake Calls.
  void startListening({VoidCallback? onShake}) {
    _onShakeTriggered = onShake;
    
    if (_subscription != null) return;

    debugPrint('PanicShakeService: Started listening for shakes.');
    
    _subscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > shakeThreshold) {
        _handleShake();
      }
    });
  }

  /// Stops listening to save battery.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('PanicShakeService: Stopped listening.');
  }

  void _handleShake() {
    final now = DateTime.now();
    
    // Check cooldown
    if (_lastTriggerTime != null && 
        now.difference(_lastTriggerTime!).inSeconds < cooldownSeconds) {
      return;
    }

    _lastTriggerTime = now;
    debugPrint('PanicShakeService: Shake detected! Triggering SOS.');

    // 1. Trigger SOS Alert via Firebase
    AlertService.sendAlert("Panic Shake SOS");

    // 2. Notify the UI/App via callback
    if (_onShakeTriggered != null) {
      _onShakeTriggered!();
    }
  }
}
