import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/theme/app_colors.dart';
import '../accessibility/providers/accessibility_provider.dart';
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
  String _listeningField = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListeningForName = false;
              _isListeningForPin = false;
              _listeningField = '';
            });
          }
        },
        onError: (error) {
          setState(() {
            _isListeningForName = false;
            _isListeningForPin = false;
            _listeningField = '';
          });
        },
      );
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      final langCode = accessibility.profile.languageCode;
      String ttsCode = 'fr-FR';
      if (langCode == 'ar') ttsCode = 'ar-SA';
      if (langCode == 'en') ttsCode = 'en-US';
      
      await _tts.setLanguage(ttsCode);
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('Voice init error: $e');
    }
  }
  
  Future<void> _speakWelcome() async {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    if (profile.visualNeeds == 'blind') {
      await Future.delayed(const Duration(milliseconds: 800));
      await _tts.speak(
        "Écran de connexion. Pour vous connecter, dictez votre nom. Pour continuer en tant qu'invité, dites Invité ou appuyez en bas de l'écran."
      );
      
      // Also register a global voice command if we have access to the service
      // Note: We'll add a listener for the word "invité" in our local speech if possible
      // or simply rely on the instructions.
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
    final profile = Provider.of<AccessibilityProvider>(context, listen: false).profile;
    if (profile.visualNeeds == 'blind') {
      await _tts.speak(text);
    }
  }

  Future<void> _startVoiceInput(String field) async {
    if (!_speechAvailable) {
      _showErrorSnackBar('Reconnaissance vocale non disponible');
      _speak("La reconnaissance vocale n'est pas disponible sur cet appareil.");
      return;
    }
    
    // 1. STOP TTS immediately to prevent echo
    await _tts.stop();
    
    setState(() {
      _listeningField = field;
      if (field == 'name') {
        _isListeningForName = true;
        _isListeningForPin = false;
      } else {
        _isListeningForPin = true;
        _isListeningForName = false;
      }
    });
    
    // 2. Short prompt then listen
    final prompt = field == 'name' ? 'Quel est votre nom ?' : 'Dites les 3 chiffres du code';
    await _tts.speak(prompt);
    
    // Wait for the prompt to finish (Reduced delay)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final profile = accessibility.profile;
    
    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          debugPrint("🎤 Heard: '$words'");
          
          // GUEST REDIRECT: Check for "invité" or "guest" or "arabe phonetic for guest"
          if (words.contains('invité') || words.contains('guest') || words.contains('ضيف')) {
            _stopVoiceInput();
            _speak(profile.languageCode == 'ar' ? "جارٍ تسجيل الدخول كضيف" : 
                   profile.languageCode == 'en' ? "Continuing as guest" : 
                   "Connexion en tant qu'invité");
            
            // Trigger the same logic as the guest button
            _continueAsGuest();
            return;
          }

          if (field == 'name') {
            setState(() => _nameController.text = words);
          } else {
            final digits = words.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.isNotEmpty) {
              setState(() {
                _pinController.text = digits.length > 3 ? digits.substring(0, 3) : digits;
              });
            }
          }
          
          if (result.finalResult) {
            setState(() {
              _isListeningForName = false;
              _isListeningForPin = false;
              _listeningField = '';
            });
            
            if (field == 'name' && _nameController.text.isNotEmpty) {
              _speak('Bonjour ${_nameController.text}. Maintenant, dites le code.');
              _startVoiceInput('pin'); 
            } else if (field == 'pin' && _pinController.text.length == 3) {
              _speak('Code reçu. Connexion en cours...');
              _login();
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2), // Shorter pause detection
        localeId: 'fr-FR',
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint("❌ Voice Error: $e");
      setState(() {
        _isListeningForName = false;
        _isListeningForPin = false;
        _listeningField = '';
      });
      _speak("Je n'ai pas compris. Veuillez réessayer.");
    }
  }

  void _stopVoiceInput() {
    _speech.stop();
    setState(() {
      _isListeningForName = false;
      _isListeningForPin = false;
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
    
    final nameInput = _nameController.text.trim();
    final pin = _pinController.text.trim();
    
    debugPrint("🔐 Attempting login for '$nameInput' with PIN '***'");
    
    try {
      // 1. FAST LOOKUP: Try Exact Match first (Case Sensitive)
      // This avoids downloading the entire collection in most cases
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fullName', isEqualTo: nameInput)
          .limit(1)
          .get();
          
      QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;
      
      if (snapshot.docs.isNotEmpty) {
        userDoc = snapshot.docs.first;
        debugPrint("✅ Found exact match: ${userDoc.id}");
      } else {
        // 2. FALLBACK: Slow Scan (Case Insensitive)
        // Only do this if exact match fails
        debugPrint("⚠️ Exact match failed, trying case-insensitive scan...");
        final fullSnapshot = await FirebaseFirestore.instance.collection('users').get();
        final lowerInput = nameInput.toLowerCase();
        
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

      if (userDoc == null) {
        _showErrorSnackBar('Utilisateur "$nameInput" non trouvé.');
        _speak("Je ne trouve pas d'utilisateur au nom de $nameInput.");
        setState(() => _isLoading = false);
        return;
      }

      final email = userDoc.data()['email'];
      if (email == null) throw Exception("Email manquant pour cet utilisateur");

      // 2. Reconstruct Password from PIN (Last 3 digits of CIN rule)
      // Note: We use the email found in the doc to authenticate with Auth
      // Assumption: You set password as CIN or last 6 digits? 
      // User Spec says: "Enter: Last 3 digits of CIN (as password)"
      // This implies the ACTUAL password check happens here.
      // But Firebase Auth needs the REAL password. 
      // If the real password is user's CIN, we need the full CIN. 
      // IF we only have 3 digits, we can't authenticate with Firebase Auth unless the password IS just 3 digits (too short).
      // HACK: I assume the "password" field in Firestore is a hash or we are "Simulating" auth with local check.
      // REALITY CHECK: Standard Firebase Auth requires the actual password.
      // If the User Spec says "3 digits", maybe the App signs in Anonymously and verifies the PIN?
      // OR, maybe the password IS "000" + digits? 
      // The previous code had `password = "000$pin"`. I will stick to that constraint.
      
      final password = "000$pin"; // Maintaining existing convention

      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      if (mounted) {
        // 3. Load Accessibility Profile (Prioritize Firestore, fallback to Wizard)
        final authProvider = Provider.of<AccessibilityProvider>(context, listen: false);
        
        // Ensure the provider knows who is logged in and fetches their specific data
        await authProvider.loadProfile();
        debugPrint("✅ Loaded accessibility profile for user: ${userDoc.id}");

        setState(() => _isLoading = false);
        
        // Check updated profile
        final currentProfile = authProvider.profile;
        if (currentProfile.visualNeeds == 'blind') {
          await _tts.speak('Connexion réussie! Bienvenue.');
        }
        
        final role = (userDoc.data()['role'] ?? '').toString();
        // Check for ANY admin role string
        final isAdmin = role.toLowerCase().contains('admin'); 
        
        Navigator.pushReplacementNamed(context, isAdmin ? '/admin-dashboard' : '/home');
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
    
    final bgColor = highContrast ? Colors.black : AppColors.background;
    final cardColor = highContrast ? AppColors.highContrastSurface : Colors.white;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = highContrast ? Colors.white70 : AppColors.textSecondary;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final borderColor = highContrast ? Colors.white : AppColors.divider;

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
              'Espace Membre',
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
                      Text('Connexion', style: TextStyle(fontSize: 20 * textScale, fontWeight: FontWeight.bold, color: textColor)),
                      Text('Accédez à votre espace', style: TextStyle(fontSize: 13 * textScale, color: secondaryTextColor)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 28 * textScale.clamp(1.0, 1.2)),
            _buildVoiceTextField(controller: _nameController, focusNode: _nameFocus, label: 'Nom complet', hint: 'Entrez votre nom', icon: Icons.person_outline_rounded, fieldName: 'name', isListening: _isListeningForName, textInputAction: TextInputAction.next, onSubmitted: (_) => _pinFocus.requestFocus(), validator: (v) => v!.isEmpty ? 'Veuillez entrer votre nom' : null, textScale: textScale, boldText: boldText, highContrast: highContrast, textColor: textColor, secondaryTextColor: secondaryTextColor, primaryColor: primaryColor, borderColor: borderColor),
            SizedBox(height: 20 * textScale.clamp(1.0, 1.2)),
            _buildVoiceTextField(controller: _pinController, focusNode: _pinFocus, label: 'Code PIN (3 chiffres CIN)', hint: '• • •', icon: Icons.lock_outline_rounded, fieldName: 'pin', isListening: _isListeningForPin, obscureText: _obscurePin, keyboardType: TextInputType.number, maxLength: 3, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(), suffixIcon: IconButton(icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: secondaryTextColor), onPressed: () => setState(() => _obscurePin = !_obscurePin)), validator: (v) => v!.length != 3 ? '3 chiffres requis' : null, textScale: textScale, boldText: boldText, highContrast: highContrast, textColor: textColor, secondaryTextColor: secondaryTextColor, primaryColor: primaryColor, borderColor: borderColor),
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
                  label: isListening ? 'Arrêter l\'écoute' : 'Dicter vocalement',
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
                    tooltip: 'Dicter',
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
                    'Je vous écoute...',
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
                      'SE CONNECTER', 
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
                'Première fois?', 
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
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Contactez l\'administrateur', 
                  style: TextStyle(fontSize: 14 * textScale)
                ), 
                backgroundColor: AppColors.info, 
                behavior: SnackBarBehavior.floating
              ),
            );
          },
          icon: Icon(Icons.help_outline_rounded, size: 18 * textScale.clamp(1.0, 1.2)),
          label: Flexible(
            child: Text(
              'Besoin d\'aide?', 
              style: TextStyle(fontSize: 14 * textScale),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        SizedBox(height: 8 * textScale.clamp(1.0, 1.2)),
        OutlinedButton.icon(
          onPressed: _continueAsGuest,
          icon: Icon(Icons.person_outline, size: 18 * textScale.clamp(1.0, 1.2)),
          label: Text(
            'Continuer en tant qu\'invité',
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
