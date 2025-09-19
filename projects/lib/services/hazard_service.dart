import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class HazardService {
  final FlutterTts _flutterTts = FlutterTts();
  final List<String> safetyHazard = [
    "scissors",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "stop sign",
    "parking meter",
  ];

  bool _isSpeaking = false;
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastVibrationTime = DateTime.fromMillisecondsSinceEpoch(0);


  final Duration speakThrottle = const Duration(seconds: 3);

  final Duration vibrationThrottle = const Duration(seconds: 1);

  HazardService() {
    _initTts();
  }

  void _initTts() async {
    // Configure your TTS engine once
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    // When speech completes, allow next alert
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  Future<void> handleRecognitions(List<dynamic>? recognitions) async {
    // 1) Extract all detecte{dClass strings that match our hazard list
    if (recognitions == null){
      return;
    }
    final detectedHazards = recognitions
        .map((o) => o['detectedClass'] as String)
        .where((c) => safetyHazard.contains(c))
        .toSet();

    if (detectedHazards.isEmpty) {
      // No hazards → do nothing
      return;
    }

    final now = DateTime.now();

    // 2) Check if we are allowed to speak again
    if (now.difference(_lastSpokenTime) > speakThrottle) {
      _lastSpokenTime = now;
      _speakHazards(detectedHazards);
    }

    // 3) Check if we are allowed to vibrate again
    if (now.difference(_lastVibrationTime) > vibrationThrottle) {
      _lastVibrationTime = now;
      _vibrateOnce();
    }
  }
  Future<void> _speakHazards(Set<String> hazards) async {
    if (_isSpeaking) return;
    _isSpeaking = true;

    String message;
    if (hazards.length == 1) {
      message = "Warning, ${hazards.first} detected.";
    } else {
      // e.g. “Warning, car, bicycle, and truck detected.”
      final list = hazards.toList();
      final last = list.removeLast();
      message = "Warning, ${list.join(", ")}, and $last detected.";
    }

    await _flutterTts.speak(message);
    // When speech finishes, _isSpeaking will be set to false by the completion handler
  }

   Future<void> _vibrateOnce() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  /// Call this in dispose() of your widget to clean up TTS
  void dispose() {
    _flutterTts.stop();
  }
}