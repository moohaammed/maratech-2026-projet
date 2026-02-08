import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_colors.dart';
import '../accessibility/providers/accessibility_provider.dart';
import '../accessibility/models/accessibility_profile.dart'; // Added this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameFocus = FocusNode();
  final _pinFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePin = true;
  
  // Voice input
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isListeningForName = false;
  bool _isListeningForPin = false;
  bool _isContinuousListening = false;
  String _listeningField = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _T(String fr, String en, String ar) {
    final lang = Provider.of<AccessibilityProvider>(context, listen: false).languageCode;
    switch (lang) {
      case 'ar': return ar;
      case 'en': return en;
      default: return fr;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initVoiceInput();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
      _speakWelcome();
    });
  }
  
  Future<void> _initVoiceInput() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint("🎤 Status: $status");
          if (status == 'done' || status == 'notListening') {
            if (_isContinuousListening) {
              debugPrint("🎤 Status done, restarting continuous listen...");
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _isContinuousListening && !_speech.isListening) {
                   _listenForChoice();
                }
              });
            } else {
              setState(() {
                _isListeningForName = false;
                _isListeningForPin = false;
                _listeningField = '';
              });
            }
          }
        },
        onError: (error) {
          debugPrint("❌ Speech Error: ${error.errorMsg}");
          if (_isContinuousListening) {
             debugPrint("🎤 Error encountered using continuous listen, restarting...");
             Future.delayed(const Duration(milliseconds: 500), () {
               if (mounted && _isContinuousListening && !_speech.isListening) {
                 _listenForChoice();
               }
             });
          } else {
            setState(() {
              _isListeningForName = false;
              _isListeningForPin = false;
              _listeningField = '';
            });
          }
        },
      );
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      final langCode = accessibility.languageCode;
      String ttsCode = 'fr-FR';
      if (langCode == 'ar') ttsCode = 'ar-SA';
      if (langCode == 'en') ttsCode = 'en-US';
      
      await _tts.setLanguage(ttsCode);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true); // Critical for sequential flow
    } catch (e) {
      debugPrint('Voice init error: $e');
    }
  }
  
  Future<void> _speakWelcome() async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    // Only speak welcome if TTS is enabled AND user needs audio assistance
    final shouldSpeak = profile.ttsEnabled && 
                        (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision');
    
    if (shouldSpeak) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Welcome message with clear instructions
      final welcomeMsg = _T(
        "Bienvenue au Running Club Tunis! Dites se Connecter, ou, Continuer en invité.",
        "Welcome to Running Club Tunis! Say Login, or, Continue as Guest.",
        "مرحبًا بك في نادي الجري تونس! قل تسجيل الدخول، أو، متابعة كضيف."
      );
      
      await _tts.speak(welcomeMsg);
      
      // Small pause before listening starts
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _listenForChoice();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _nameFocus.dispose();
    _pinFocus.dispose();
    _animationController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
  
  Future<void> _speak(String text) async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    // Only speak if TTS is enabled AND user needs it (blind/low vision)
    // OR if user explicitly has TTS enabled
    final shouldSpeak = profile.ttsEnabled && 
                        (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision');
    
    if (shouldSpeak) {
      await _tts.speak(text);
    }
  }
  
  /// Fuzzy string matching using Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1].toLowerCase() == s2[j - 1].toLowerCase() ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[s1.length][s2.length];
  }
  
  /// Finds the best matching user name from the database
  Future<String?> _findBestMatchingName(String spokenName) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      
      String? bestMatch;
      int bestScore = 999;
      
      final spokenLower = spokenName.toLowerCase().trim();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fullName = (data['fullName'] ?? '').toString();
        final nameLower = fullName.toLowerCase();
        
        // Exact match
        if (nameLower == spokenLower) {
          return fullName;
        }
        
        // Check if spoken name is contained in full name or vice versa
        if (nameLower.contains(spokenLower) || spokenLower.contains(nameLower)) {
          return fullName;
        }
        
        // Fuzzy match using first name
        final firstName = nameLower.split(' ').first;
        final spokenFirst = spokenLower.split(' ').first;
        
        int distance = _levenshteinDistance(firstName, spokenFirst);
        
        // Allow up to 2 character differences for short names, 3 for longer
        int threshold = firstName.length <= 5 ? 2 : 3;
        
        if (distance < bestScore && distance <= threshold) {
          bestScore = distance;
          bestMatch = fullName;
        }
      }
      
      return bestMatch;
    } catch (e) {
      debugPrint("Error finding matching name: $e");
      return null;
    }
  }

  Future<void> _listenForChoice() async {
    if (!_speechAvailable || !mounted) return;
    
    // Ensure TTS is stopped
    await _tts.stop();
    if (_speech.isListening) {
      // Don't restart if already listening unless we want to refresh
    }
    
    // Set flag for auto-restart
    _isContinuousListening = true;
    
    debugPrint("🎤 Listening for choice (Login/Guest) - Continuous Mode...");
    
    try {
      await _speech.listen(
        onResult: (result) async {
          final words = result.recognizedWords.toLowerCase().trim();
          
          bool isLogin = words.contains('connecter') || words.contains('login') || 
                        words.contains('membre') || words.contains('connexion') ||
                        words.contains('تسجيل') || words.contains('دخول');
                        
          bool isGuest = words.contains('invité') || words.contains('guest') || 
                        words.contains('visiteur') || words.contains('visite') ||
                        words.contains('ضيف') || words.contains('متابعة') || words.contains('متابعه'); 

          if (isLogin || isGuest) {
            debugPrint("🎤 Command Detected: '$words'");
            _stopVoiceInput();
            
            if (isLogin) {
              await _speak(_T(
                "D'accord. Dites votre nom maintenant.",
                "Okay. Say your name now.",
                "حسنًا. قل اسمك الآن."
              ));
              if (mounted) _startGuidedVoiceLogin();
            } else {
              await _speak(_T("Mode invité.", "Guest mode.", "وضع الضيف."));
              _continueAsGuest();
            } 
          } else if (result.finalResult) {
            // Heard something but couldn't verify. Loop.
            debugPrint("🎤 Noise/Unknown: '$words'. Restarting...");
            // Restart immediately
            if (mounted) _listenForChoice();
          }
        },
        listenFor: const Duration(seconds: 30), // Listen for a long time
        pauseFor: const Duration(seconds: 5), // Allow pauses
        localeId: _T('fr-FR', 'en-US', 'ar-SA'),
        cancelOnError: false, // Don't stop on temporary errors
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint("❌ Voice Error (Choice): $e");
      _stopVoiceInput();
       // Retry after short delay
       Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _listenForChoice();
       });
    }
  }

  /// Sequential guided voice login flow
  Future<void> _startGuidedVoiceLogin() async {
    if (!_speechAvailable) {
      debugPrint("Speech not available");
      return;
    }
    
    await _tts.stop();
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    setState(() {
      _isListeningForName = true;
      _isListeningForPin = false;
      _listeningField = 'name';
    });
    
    debugPrint("🎤 Starting guided voice login - listening for name...");
    
    try {
      await _speech.listen(
        onResult: (result) async {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          
          debugPrint("🎤 Heard name: '$words'");
          
          // Check for guest command
          if (words.toLowerCase().contains('invité') || 
              words.toLowerCase().contains('guest') || 
              words.toLowerCase().contains('ضيف')) {
            _stopVoiceInput();
            await _speak(_T("Mode invité.", "Guest mode.", "وضع الضيف."));
            _continueAsGuest();
            return;
          }
          
          setState(() => _nameController.text = words);
          
          if (result.finalResult) {
            _stopVoiceInput();
            
            // Try to find matching name with fuzzy matching
            final matchedName = await _findBestMatchingName(words);
            
            if (matchedName != null && matchedName.toLowerCase() != words.toLowerCase()) {
              // We found a better match - use it
              setState(() => _nameController.text = matchedName);
              debugPrint("✨ Corrected name: '$words' → '$matchedName'");
              
              await _speak(_T(
                "J'ai compris $matchedName. Maintenant, dites les 3 chiffres de votre code.",
                "I understood $matchedName. Now, say your 3-digit code.",
                "فهمت $matchedName. الآن، قل أرقام الرمز الثلاثة."
              ));
            } else if (_nameController.text.isNotEmpty) {
              await _speak(_T(
                "Bonjour ${_nameController.text}. Maintenant, dites les 3 chiffres de votre code.",
                "Hello ${_nameController.text}. Now, say your 3-digit code.",
                "مرحبًا ${_nameController.text}. الآن، قل أرقام الرمز الثلاثة."
              ));
            }
            
            // Wait for TTS then listen for PIN
            await Future.delayed(const Duration(milliseconds: 4000));
            if (mounted) _listenForPin();
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        // Force Latin characters (French/English) for Name even if app is in Arabic
        localeId: _T('fr-FR', 'en-US', 'fr-FR'),
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint("❌ Voice Error (name): $e");
      _stopVoiceInput();
      await _speak(_T(
        "Je n'ai pas entendu. Dites votre nom.",
        "I didn't hear you. Say your name.",
        "لم أسمعك. قل اسمك."
      ));
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) _startGuidedVoiceLogin();
    }
  }
  
  Future<void> _listenForPin() async {
    if (!_speechAvailable || !mounted) return;
    
    await _tts.stop();
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    setState(() {
      _isListeningForName = false;
      _isListeningForPin = true;
      _listeningField = 'pin';
    });
    
    debugPrint("🎤 Listening for PIN...");
    
    try {
      await _speech.listen(
        onResult: (result) async {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          
          debugPrint("🎤 Heard PIN: '$words'");
          
          // Extract digits from speech
          final digits = words.replaceAll(RegExp(r'[^0-9]'), '');
          
          if (digits.isNotEmpty) {
            final pin = digits.length > 3 ? digits.substring(0, 3) : digits;
            setState(() => _pinController.text = pin);
          }
          
          if (result.finalResult) {
            _stopVoiceInput();
            
            if (_pinController.text.length == 3) {
              await _speak(_T(
                "Code reçu. Connexion en cours.",
                "Code received. Logging in.",
                "تم استلام الرمز. جارٍ تسجيل الدخول."
              ));
              await Future.delayed(const Duration(milliseconds: 1500));
              if (mounted) _login();
            } else {
              await _speak(_T(
                "Je n'ai pas compris le code. Répétez les 3 chiffres.",
                "I didn't understand the code. Repeat the 3 digits.",
                "لم أفهم الرمز. كرر الأرقام الثلاثة."
              ));
              await Future.delayed(const Duration(seconds: 3));
              if (mounted) _listenForPin();
            }
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        // Force Latin digits (French/English) for PIN even if app is in Arabic
        localeId: _T('fr-FR', 'en-US', 'fr-FR'),
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint("❌ Voice Error (pin): $e");
      _stopVoiceInput();
      await _speak(_T(
        "Erreur. Répétez le code.",
        "Error. Repeat the code.",
        "خطأ. كرر الرمز."
      ));
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _listenForPin();
    }
  }

  Future<void> _startVoiceInput(String field) async {
    if (field == 'name') {
      _startGuidedVoiceLogin();
    } else {
      _listenForPin();
    }
  }

  void _stopVoiceInput() {
    _speech.stop();
    setState(() {
      _isListeningForName = false;
      _isListeningForPin = false;
      _isContinuousListening = false;
      _listeningField = '';
    });
  }


  void _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final isConfigured = prefs.getBool('onboarding_wizard_completed') ?? false;
    
    if (isConfigured) {
      Navigator.pushReplacementNamed(context, '/guest-home');
    } else {
      Navigator.pushReplacementNamed(
        context, 
        '/accessibility-wizard',
        arguments: {'target': '/guest-home'}
      );
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final input = _nameController.text.trim();
    final pin = _pinController.text.trim();
    
    // Detect if input is email or name
    final bool isEmailInput = input.contains('@');
    
    debugPrint("🔐 Attempting login with ${isEmailInput ? 'EMAIL' : 'NAME'}: '$input' with PIN '***'");
    
    try {
      QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
      
      if (isEmailInput) {
        // ==================== EMAIL LOGIN ====================
        // Direct lookup by email (fast)
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: input)
            .limit(1)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          userDoc = snapshot.docs.first;
          debugPrint("✅ Found user by email: ${userDoc.id}");
        } else {
          // Try case-insensitive email search
          final lowerEmail = input.toLowerCase();
          final fullSnapshot = await FirebaseFirestore.instance.collection('users').get();
          
          for (var doc in fullSnapshot.docs) {
            final docEmail = (doc.data()['email'] ?? '').toString().toLowerCase();
            if (docEmail == lowerEmail) {
              userDoc = doc;
              debugPrint("✅ Found user by email (case-insensitive): ${doc.id}");
              break;
            }
          }
        }
      } else {
        // ==================== NAME LOGIN ====================
        // 1. FAST LOOKUP: Try Exact Match first (Case Sensitive)
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('fullName', isEqualTo: input)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          userDoc = snapshot.docs.first;
          debugPrint("✅ Found exact name match: ${userDoc.id}");
        } else {
          // 2. FALLBACK: Slow Scan (Case Insensitive + partial match)
          debugPrint("⚠️ Exact match failed, trying case-insensitive scan...");
          final fullSnapshot = await FirebaseFirestore.instance.collection('users').get();
          final lowerInput = input.toLowerCase();
          
          for (var doc in fullSnapshot.docs) {
            final data = doc.data();
            final docName = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
            
            if (docName == lowerInput || docName.contains(lowerInput)) { 
              userDoc = doc;
              debugPrint("✅ Found fuzzy match: ${doc.id} ($docName)");
              break; 
            }
          }
        }
      }

      if (userDoc == null) {
        final errorMsg = isEmailInput 
            ? 'Email "$input" non trouvé.'
            : 'Utilisateur "$input" non trouvé.';
        _showErrorSnackBar(errorMsg);
        _speak(isEmailInput 
            ? "Je ne trouve pas cet email." 
            : "Je ne trouve pas d'utilisateur au nom de $input.");
        setState(() => _isLoading = false);
        return;
      }

      final email = userDoc.data()['email'];
      if (email == null) throw Exception("Email manquant pour cet utilisateur");

      // Reconstruct Password from PIN (format: "000" + pin)
      final password = "000$pin";

      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      if (mounted) {
        // Load Accessibility Profile
        final authProvider = Provider.of<AccessibilityProvider>(context, listen: false);
        await authProvider.loadProfile();
        debugPrint("✅ Loaded accessibility profile for user: ${userDoc.id}");

        setState(() => _isLoading = false);
        
        // Check updated profile for TTS
        final currentProfile = authProvider.profile;
        if (currentProfile.visualNeeds == 'blind') {
          await _tts.speak('Connexion réussie! Bienvenue.');
        }
        
        
        final role = (userDoc.data()['role'] ?? '').toString().toLowerCase();
        
        if (role == 'main_admin' || role == 'sub_admin' || role == 'group_admin' || role == 'groupadmin' || role == 'coach_admin' || role == 'coachadmin') {
           // Force standard UI for admins
           debugPrint("ℹ️ Admin login: Resetting accessibility to Normal Mode.");
           final defaultProfile = AccessibilityProfile(userId: userDoc.id);
           await authProvider.updateProfile(defaultProfile);
        }

        if (role == 'main_admin' || role == 'sub_admin' || role == 'group_admin' || role == 'groupadmin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else if (role == 'coach_admin' || role == 'coachadmin') {
          Navigator.pushReplacementNamed(context, '/coach-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Erreur de connexion.';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') message = 'Code PIN incorrect.';
        if (e.code == 'user-not-found') message = 'Utilisateur non trouvé.';
        
        debugPrint("❌ Auth Error: ${e.code}");
        _showErrorSnackBar(message);
        _speak(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("❌ Generic Error: $e");
        _showErrorSnackBar('Erreur technique');
        _speak('Une erreur est survenue.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final boldText = profile.boldText;
    final isBlind = profile.visualNeeds == 'blind';
    
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isLargeScreen = size.width >= 600;
    
    final logoSize = (isSmallScreen ? 80.0 : (isLargeScreen ? 120.0 : 100.0)) * textScale.clamp(1.0, 1.3);
    final horizontalPadding = isLargeScreen ? 48.0 : 24.0;
    final maxWidth = isLargeScreen ? 450.0 : double.infinity;
    
    final bgColor = highContrast ? AppColors.highContrastBackground : AppColors.background;
    final cardColor = highContrast ? AppColors.highContrastSurface : Colors.white;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = highContrast ? Colors.white70 : AppColors.textSecondary;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final borderColor = highContrast ? AppColors.highContrastPrimary.withOpacity(0.5) : AppColors.divider;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: highContrast ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.1), AppColors.background, AppColors.background],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(logoSize, highContrast, primaryColor),
                        SizedBox(height: (isSmallScreen ? 20 : 32) * textScale.clamp(1.0, 1.2)),
                        _buildHeader(isSmallScreen, textScale, boldText, highContrast, secondaryTextColor, primaryColor),
                        SizedBox(height: (isSmallScreen ? 32 : 48) * textScale.clamp(1.0, 1.2)),
                        _buildLoginCard(isSmallScreen, textScale, boldText, highContrast, cardColor, textColor, secondaryTextColor, primaryColor, borderColor, isBlind),
                        SizedBox(height: 24 * textScale.clamp(1.0, 1.2)),
                        _buildFooter(textScale, highContrast, secondaryTextColor, primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double size, bool highContrast, Color primaryColor) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: highContrast ? null : [
            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: highContrast ? primaryColor : Colors.white, width: highContrast ? 3 : 4),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: highContrast ? AppColors.highContrastSurface : primaryColor,
                child: Icon(Icons.directions_run, size: size * 0.5, color: highContrast ? primaryColor : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall, double textScale, bool boldText, bool highContrast, Color secondaryTextColor, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Running Club Tunis',
            style: TextStyle(
              fontSize: (isSmall ? 24 : 28) * textScale,
              fontWeight: FontWeight.bold,
              color: highContrast ? primaryColor : AppColors.primary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible, // Start wrapping if needed
          ),
        ),
        SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * textScale.clamp(1.0, 1.2), 
            vertical: 6 * textScale.clamp(1.0, 1.2)
          ),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(highContrast ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: highContrast ? Border.all(color: primaryColor) : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200), // Prevent super wide pill
            child: Text(
              _T('Espace Membre', 'Member Area', 'فضاء الأعضاء'),
              style: TextStyle(
                color: highContrast ? Colors.white : secondaryTextColor,
                fontSize: (isSmall ? 12 : 14) * textScale,
                fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isSmall, double textScale, bool boldText, bool highContrast, Color cardColor, Color textColor, Color secondaryTextColor, Color primaryColor, Color borderColor, bool isBlind) {
    return Container(
      padding: EdgeInsets.all((isSmall ? 20 : 28) * textScale.clamp(1.0, 1.2)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: highContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: highContrast ? null : [
          BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10 * textScale.clamp(1.0, 1.2)),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(highContrast ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.login_rounded, color: primaryColor, size: 24 * textScale.clamp(1.0, 1.3)),
                ),
                SizedBox(width: 12 * textScale.clamp(1.0, 1.2)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_T('Connexion', 'Login', 'تسجيل الدخول'), style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold, color: textColor)),
                      Text(_T('Accédez à votre espace', 'Access your space', 'الولوج إلى فضائك'), style: TextStyle(fontSize: 13 * textScale, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 28 * textScale.clamp(1.0, 1.2)),
            _buildVoiceTextField(controller: _nameController, focusNode: _nameFocus, label: _T('Nom ou Email', 'Name or Email', 'الاسم أو البريد'), hint: _T('Entrez votre nom ou email', 'Enter your name or email', 'أدخل اسمك أو بريدك'), icon: Icons.person_outline_rounded, fieldName: 'name', isListening: _isListeningForName, textInputAction: TextInputAction.next, onSubmitted: (_) => _pinFocus.requestFocus(), validator: (v) => v!.isEmpty ? _T('Veuillez entrer votre nom ou email', 'Please enter your name or email', 'يرجى إدخال اسمك أو بريدك') : null, textScale: textScale, boldText: boldText, highContrast: highContrast, textColor: textColor, secondaryTextColor: secondaryTextColor, primaryColor: primaryColor, borderColor: borderColor),
            SizedBox(height: 20 * textScale.clamp(1.0, 1.2)),
            _buildVoiceTextField(controller: _pinController, focusNode: _pinFocus, label: _T('Code PIN (3 chiffres CIN)', 'PIN Code (3 digits)', 'الرمز السري (3 أرقام)'), hint: '• • •', icon: Icons.lock_outline_rounded, fieldName: 'pin', isListening: _isListeningForPin, obscureText: _obscurePin, keyboardType: TextInputType.number, maxLength: 3, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(), suffixIcon: IconButton(icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: secondaryTextColor), onPressed: () => setState(() => _obscurePin = !_obscurePin)), validator: (v) => v!.length != 3 ? _T('3 chiffres requis', '3 digits required', '3 أرقام مطلوبة') : null, textScale: textScale, boldText: boldText, highContrast: highContrast, textColor: textColor, secondaryTextColor: secondaryTextColor, primaryColor: primaryColor, borderColor: borderColor),
            SizedBox(height: 32 * textScale.clamp(1.0, 1.2)),
            _buildLoginButton(textScale, highContrast, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String fieldName,
    required bool isListening,
    required double textScale,
    required bool boldText,
    required bool highContrast,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
    required Color borderColor,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final bgColor = highContrast ? Colors.black : AppColors.background;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * textScale,
            fontWeight: boldText ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
        
        // Input Field with integrated Voice Button
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          inputFormatters: keyboardType == TextInputType.number 
              ? [FilteringTextInputFormatter.digitsOnly] 
              : null,
          style: TextStyle(
            fontSize: 16 * textScale,
            fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: secondaryTextColor.withOpacity(0.5),
              fontSize: 16 * textScale,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                icon,
                color: isListening ? AppColors.error : primaryColor,
                size: 22 * textScale.clamp(1.0, 1.3),
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 48 * textScale.clamp(1.0, 1.2),
            ),
            // Integrated Suffix: Mic + (Optional) Custom Suffix
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice Input Button
                Semantics(
                  button: true,
                  label: isListening 
                      ? _T('Arrêter l\'écoute', 'Stop listening', 'إيقاف الاستماع') 
                      : _T('Dicter vocalement', 'Dictate', 'إملاء صوتي'),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                        key: ValueKey(isListening),
                        color: isListening ? AppColors.error : primaryColor,
                        size: 24 * textScale.clamp(1.0, 1.3),
                      ),
                    ),
                    onPressed: () => isListening 
                        ? _stopVoiceInput() 
                        : _startVoiceInput(fieldName),
                    tooltip: _T('Dicter', 'Dictate', 'إملاء'),
                  ),
                ),
                // Existing suffix (e.g., eye icon for PIN)
                if (suffixIcon != null) 
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: suffixIcon,
                  ),
              ],
            ),
            counterText: '',
            filled: true,
            fillColor: isListening 
                ? AppColors.error.withOpacity(0.05) 
                : bgColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * textScale.clamp(1.0, 1.2),
              vertical: 18 * textScale.clamp(1.0, 1.2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isListening 
                    ? AppColors.error.withOpacity(0.5)
                    : (highContrast ? Colors.white : borderColor.withOpacity(0.5)),
                width: highContrast ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isListening ? AppColors.error : primaryColor,
                width: highContrast ? 3 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: TextStyle(fontSize: 12 * textScale),
          ),
          validator: validator,
        ),

        // Listening Status Indicator (Below field)
        if (isListening)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 12 * textScale, 
                  height: 12 * textScale, 
                  child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                ),
                SizedBox(width: 8 * textScale),
                Flexible(
                  child: Text(
                    _T('Je vous écoute...', 'I\'m listening...', 'أنا أستمع...'),
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoginButton(double textScale, bool highContrast, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 56 * textScale.clamp(1.0, 1.3),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: highContrast ? Colors.black : Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          elevation: highContrast ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: highContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none),
        ),
        child: _isLoading
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: highContrast ? Colors.black : Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _T('SE CONNECTER', 'LOGIN', 'تسجيل الدخول'), 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8 * textScale.clamp(1.0, 1.2)),
                  Container(
                    padding: EdgeInsets.all(4 * textScale.clamp(1.0, 1.2)),
                    decoration: BoxDecoration(color: (highContrast ? Colors.black : Colors.white).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.arrow_forward_rounded, size: 18 * textScale.clamp(1.0, 1.2)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter(double textScale, bool highContrast, Color secondaryTextColor, Color primaryColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: highContrast ? 2 : 1, 
                color: highContrast ? Colors.white54 : AppColors.divider,
                margin: const EdgeInsets.only(right: 16),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                _T('Première fois?', 'First time?', 'أول مرة؟'), 
                style: TextStyle(
                  color: secondaryTextColor, 
                  fontSize: 13 * textScale,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                height: highContrast ? 2 : 1, 
                color: highContrast ? Colors.white54 : AppColors.divider,
                margin: const EdgeInsets.only(left: 16),
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * textScale.clamp(1.0, 1.2)),
        OutlinedButton.icon(
          onPressed: _continueAsGuest,
          icon: Icon(Icons.person_outline, size: 18 * textScale.clamp(1.0, 1.2)),
          label: Text(
            _T('Continuer en tant qu\'invité', 'Continue as Guest', 'متابعة كضيف'),
            style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor, width: highContrast ? 2 : 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
