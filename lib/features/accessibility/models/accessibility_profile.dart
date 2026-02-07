import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityProfile {
  final String userId;

  // Visual
  final String visualNeeds; // 'normal', 'low_vision', 'blind', 'colorblind'
  final double textSize; // 1.0 to 2.0 (100% to 200%)
  final bool highContrast;
  final bool boldText;

  // Audio
  final String audioNeeds; // 'normal', 'hearing_loss', 'deaf'
  final bool vibrationEnabled;
  final bool visualNotifications; // Flash screen instead of sound

  // Motor
  final String motorNeeds; // 'normal', 'limited_dexterity'
  final bool simplifiedGestures; // No complex swipes
  final double touchDuration; // For "long press" adjustments

  // Constructor with defaults (WCAG Standard)
  AccessibilityProfile({
    required this.userId,
    this.visualNeeds = 'normal',
    this.textSize = 1.0,
    this.highContrast = false,
    this.boldText = false,
    this.audioNeeds = 'normal',
    this.vibrationEnabled = true,
    this.visualNotifications = false,
    this.motorNeeds = 'normal',
    this.simplifiedGestures = false,
    this.touchDuration = 0.5,
  });

  // Factory to create from Firebase
  factory AccessibilityProfile.fromMap(Map<String, dynamic> data, String id) {
    final visual = data['visual'] ?? {};
    final audio = data['audio'] ?? {};
    final motor = data['motor'] ?? {};

    return AccessibilityProfile(
      userId: id,
      visualNeeds: visual['needsCategory'] ?? 'normal',
      textSize: (visual['textSize'] ?? 100) / 100.0,
      highContrast: visual['contrastMode'] == 'high',
      boldText: visual['boldText'] ?? false,
      audioNeeds: audio['needsCategory'] ?? 'normal',
      vibrationEnabled: audio['vibrationEnabled'] ?? true,
      visualNotifications:
          audio['notificationStyle'] == 'visual_only' ||
          audio['notificationStyle'] == 'visual_haptic',
      motorNeeds: motor['needsCategory'] ?? 'normal',
      simplifiedGestures: motor['simplifiedGestures'] ?? false,
      touchDuration: (motor['touchHoldDuration'] ?? 500) / 1000.0,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'visual': {
        'needsCategory': visualNeeds,
        'textSize': (textSize * 100).toInt(),
        'contrastMode': highContrast ? 'high' : 'standard',
        'boldText': boldText,
      },
      'audio': {
        'needsCategory': audioNeeds,
        'vibrationEnabled': vibrationEnabled,
        'notificationStyle': visualNotifications
            ? 'visual_only'
            : 'sound_visual',
      },
      'motor': {
        'needsCategory': motorNeeds,
        'simplifiedGestures': simplifiedGestures,
        'touchHoldDuration': (touchDuration * 1000).toInt(),
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
