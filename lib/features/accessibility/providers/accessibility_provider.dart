import 'package:flutter/material.dart';
import '../models/accessibility_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityProvider with ChangeNotifier {
  // Default to standard profile initially
  AccessibilityProfile _profile = AccessibilityProfile(userId: 'guest');
  bool _isLoading = true;

  AccessibilityProfile get profile => _profile;
  bool get isLoading => _isLoading;

  // 🎨 DYNAMIC THEME GENERATOR
  // This creates a Flutter Theme based on accessibility settings
  ThemeData getTheme() {
    // 1. Define Base Colors
    Color primary = const Color(0xFF2196F3); // Standard Blue
    Color background = Colors.white;
    Color text = Colors.black;

    // 2. Apply High Contrast (WCAG 1.4.6)
    if (_profile.highContrast) {
      primary = const Color(0xFF0000FF); // Pure Blue
      background = const Color(0xFF000000); // Pure Black
      text = const Color(0xFFFFFFFF); // Pure White
    }

    // 3. Build the Theme
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: _profile.highContrast ? Brightness.dark : Brightness.light,
        surface: background,
        onSurface: text,
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
          foregroundColor: _profile.highContrast ? Colors.white : null,
          padding: EdgeInsets.all(_profile.motorNeeds == 'limited_dexterity' ? 24 : 16), // Larger touch target
          minimumSize: Size(
            0, 
            _profile.motorNeeds == 'limited_dexterity' ? 60 : 48 // Min height 48px or 60px
          ),
        ),
      ),
    );
  }

  // 🔄 LOAD SETTINGS FROM FIREBASE
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('accessibilityProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _profile = AccessibilityProfile.fromMap(doc.data()!, user.uid);
      } else {
        // No profile yet? We will redirect to Wizard later
        print("⚠️ No accessibility profile found for user.");
      }
    } catch (e) {
      print("❌ Error loading accessibility profile: $e");
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
}