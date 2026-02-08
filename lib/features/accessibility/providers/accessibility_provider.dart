import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/accessibility_profile.dart';
import '../../../core/theme/app_colors.dart';

class AccessibilityProvider with ChangeNotifier {
  // Default to standard profile initially
  AccessibilityProfile _profile = AccessibilityProfile(userId: 'guest');
  String _languageCode = 'fr'; // Default language
  bool _isLoading = true;

  AccessibilityProfile get profile => _profile;
  String get languageCode => _languageCode;
  bool get isLoading => _isLoading;
  
  // Quick accessors for common settings
  bool get ttsEnabled => _profile.ttsEnabled && _profile.audioNeeds != 'deaf';
  bool get vibrationEnabled => _profile.vibrationEnabled;
  double get textScale => _profile.textSize;
  bool get highContrast => _profile.highContrast;


  // 🎨 DYNAMIC THEME GENERATOR
  // This creates a Flutter Theme based on accessibility settings
  ThemeData getTheme() {
    // 1. Define Base Colors
    Color primary = AppColors.primary;
    Color background = AppColors.background;
    Color surface = AppColors.surface;
    Color text = AppColors.textPrimary;

    // 2. Apply High Contrast (WCAG 1.4.6)
    if (_profile.highContrast) {
      primary = AppColors.highContrastPrimary;
      background = AppColors.highContrastBackground;
      surface = AppColors.highContrastSurface;
      text = Colors.white;
    }

    // 3. Build the Theme
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: _profile.highContrast ? Brightness.dark : Brightness.light,
        surface: surface,
        onSurface: text,
      ),
      
      scaffoldBackgroundColor: background, 
      appBarTheme: AppBarTheme(
        backgroundColor: _profile.highContrast ? background : primary,
        foregroundColor: _profile.highContrast ? primary : Colors.white,
      ),

      // Text Scaling (WCAG 1.4.4)
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontSize: 16 * _profile.textSize, 
          fontWeight: _profile.boldText ? FontWeight.bold : FontWeight.normal,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 22 * _profile.textSize,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),

      // Button Sizing (Target Size WCAG 2.5.5)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _profile.highContrast ? Colors.black : Colors.white,
          padding: EdgeInsets.all(_profile.motorNeeds == 'limited_dexterity' ? 24 : 16), // Larger touch target
          minimumSize: Size(
            0, 
            _profile.motorNeeds == 'limited_dexterity' ? 60 : 48 // Min height 48px or 60px
          ),
          textStyle: TextStyle(
             fontSize: 16 * _profile.textSize,
             fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔄 LOAD SETTINGS
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 0. Load Language First
      _languageCode = prefs.getString('languageCode') ?? 'fr';

      // 1. Check Local Storage (from Wizard) first (Pre-Auth)
      final localJson = prefs.getString('accessibility_profile_json');
      
      if (localJson != null) {
        final Map<String, dynamic> data = jsonDecode(localJson);
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
        try {
             _profile = AccessibilityProfile.fromMap(data, userId);
             // Also check json for language override?
             if (data.containsKey('languageCode')) {
               _languageCode = data['languageCode'];
             }
             debugPrint("✅ Loaded Accessibility Profile from Local Storage");
        } catch(e) {
             debugPrint("⚠️ Error parsing local profile: $e");
        }
      }

      // 2. If User Logged In, Sync with Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('accessibilityProfiles')
            .doc(user.uid)
            .get();
  
        if (doc.exists) {
            _profile = AccessibilityProfile.fromMap(doc.data()!, user.uid);
            if (doc.data()!.containsKey('languageCode')) {
              _languageCode = doc.data()!['languageCode'];
              // Sync to prefs
              await prefs.setString('languageCode', _languageCode);
            }
            debugPrint("✅ Loaded Accessibility Profile from Firestore");
        } else if (localJson != null) {
            // Upload local wizard data to Firestore!
            await updateProfile(_profile);
            // Also upload language!
            await setLanguage(_languageCode);
            debugPrint("✅ Synced Local Profile to Firestore");
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading accessibility profile: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 💾 UPDATE SETTINGS (Used by the Wizard)
  Future<void> updateProfile(AccessibilityProfile newProfile) async {
    _profile = newProfile;
    notifyListeners(); // Immediate UI update

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('accessibilityProfiles')
          .doc(user.uid)
          .set(newProfile.toMap(), SetOptions(merge: true));
    }
  }
  
  // 🔊 TTS CONTROL
  Future<void> setTtsEnabled(bool enabled) async {
    _profile = _profile.copyWith(ttsEnabled: enabled);
    notifyListeners();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('accessibilityProfiles')
          .doc(user.uid)
          .set({'audio': {'ttsEnabled': enabled}}, SetOptions(merge: true));
    }
    
    // Also save to local prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ttsEnabled', enabled);
    
    debugPrint('📢 TTS ${enabled ? 'enabled' : 'disabled'}');
  }

  // 🌐 LANGUAGE MANAGEMENT
  Future<void> setLanguage(String langCode) async {
    _languageCode = langCode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('accessibilityProfiles')
          .doc(user.uid)
          .set({'languageCode': langCode}, SetOptions(merge: true));
    }
  }

  // 🔄 LOGOUT & RESTORE (Revert to Wizard/Local settings)
  Future<void> logoutAndRestoreLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('accessibility_profile_json');
    
    if (localJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(localJson);
        // Restore local settings as guest
        _profile = AccessibilityProfile.fromMap(data, 'guest');
        debugPrint("✅ Restored Wizard Profile after logout");
      } catch (e) {
        debugPrint("⚠️ Error restoring local profile: $e");
         _profile = AccessibilityProfile(userId: 'guest');
      }
    } else {
        // No local wizard data -> Default
        _profile = AccessibilityProfile(userId: 'guest');
    }
    notifyListeners();
  }
}