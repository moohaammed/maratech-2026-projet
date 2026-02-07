import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityProfile {
  final String userId;

  // Visual
  final String visualNeeds; // 'normal', 'low_vision', 'blind', 'colorblind'
  final double textSize; // 1.0 to 2.0 (100% to 200%)
  final bool highContrast;
  final bool boldText;
  final bool dyslexicMode;

  // Audio
  final String audioNeeds; // 'normal', 'hearing_loss', 'deaf'
  final bool vibrationEnabled;
  final bool visualNotifications; // Flash screen instead of sound

  // Motor
  final String motorNeeds; // 'normal', 'limited_dexterity'
  final bool simplifiedGestures; // No complex swipes
  final double touchDuration; // For "long press" adjustments

  // Language
  final String languageCode; // 'fr', 'ar', 'en'

  // Constructor with defaults (WCAG Standard)
  AccessibilityProfile({
    required this.userId,
    this.visualNeeds = 'normal',
    this.textSize = 1.0,
    this.highContrast = false,
    this.boldText = false,
    this.dyslexicMode = false,
    this.audioNeeds = 'normal',
    this.vibrationEnabled = true,
    this.visualNotifications = false,
    this.motorNeeds = 'normal',
    this.simplifiedGestures = false,
    this.touchDuration = 0.5,
    this.languageCode = 'fr',
  });

  // Factory to create from Firebase
  factory AccessibilityProfile.fromMap(Map<String, dynamic> data, String id) {
    final visual = data['visual'] ?? {};
    final audio = data['audio'] ?? {};
    final motor = data['motor'] ?? {};

    // Parse contrast mode - check for both 'high' and 'high_contrast' (wizard saves 'high_contrast')
    final contrastMode = visual['contrastMode']?.toString() ?? 'standard';
    final isHighContrast = contrastMode == 'high' || contrastMode == 'high_contrast';
    
    // Parse text size - handle both int (150) and double (1.5) formats
    double textSize = 1.0;
    final rawTextSize = visual['textSize'];
    if (rawTextSize != null) {
      if (rawTextSize is num) {
        // If > 10, treat as percentage (e.g., 150 = 1.5)
        textSize = rawTextSize > 10 ? rawTextSize / 100.0 : rawTextSize.toDouble();
      }
    }
    
    return AccessibilityProfile(
      userId: id,
      visualNeeds: visual['needsCategory'] ?? 'normal',
      textSize: textSize,
      highContrast: isHighContrast,
      boldText: visual['boldText'] ?? false,
      dyslexicMode: visual['dyslexicMode'] ?? false,
      audioNeeds: audio['needsCategory'] ?? 'normal',
      vibrationEnabled: audio['vibrationEnabled'] ?? true,
      visualNotifications:
          audio['notificationStyle'] == 'visual_only' ||
          audio['notificationStyle'] == 'visual_haptic',
      motorNeeds: motor['needsCategory'] ?? 'normal',
      simplifiedGestures: motor['simplifiedGestures'] ?? false,
      touchDuration: (motor['touchHoldDuration'] ?? 500) / 1000.0,
      languageCode: data['languageCode'] ?? 'fr',
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'visual': {
        'needsCategory': visualNeeds,
        'textSize': (textSize * 100).toInt(),
        'contrastMode': highContrast ? 'high' : 'standard',
        'boldText': boldText,
        'dyslexicMode': dyslexicMode,
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
      'languageCode': languageCode,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  AccessibilityProfile copyWith({
    String? userId,
    String? visualNeeds,
    double? textSize,
    bool? highContrast,
    bool? boldText,
    bool? dyslexicMode,
    String? audioNeeds,
    bool? vibrationEnabled,
    bool? visualNotifications,
    String? motorNeeds,
    bool? simplifiedGestures,
    double? touchDuration,
    String? languageCode,
  }) {
    return AccessibilityProfile(
      userId: userId ?? this.userId,
      visualNeeds: visualNeeds ?? this.visualNeeds,
      textSize: textSize ?? this.textSize,
      highContrast: highContrast ?? this.highContrast,
      boldText: boldText ?? this.boldText,
      dyslexicMode: dyslexicMode ?? this.dyslexicMode,
      audioNeeds: audioNeeds ?? this.audioNeeds,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      visualNotifications: visualNotifications ?? this.visualNotifications,
      motorNeeds: motorNeeds ?? this.motorNeeds,
      simplifiedGestures: simplifiedGestures ?? this.simplifiedGestures,
      touchDuration: touchDuration ?? this.touchDuration,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
