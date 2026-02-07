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
      final langCode = accessibility.languageCode;
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
    
    if (profile.visualNeeds == 'blind' || profile.visualNeeds == 'low_vision') {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final welcomeMsg = _T(
        "Bienvenue. Souhaitez-vous vous connecter ou continuer en tant qu'invité ?",
        "Welcome. Would you like to login or continue as a guest?",
        "مرحبًا. هل ترغب في تسجيل الدخول أو المتابعة كضيف؟"
      );
      
      await _tts.speak(welcomeMsg);
      
      // Wait for speech to finish before starting listener
      Future.delayed(const Duration(milliseconds: 4500), () {
        if (mounted) _listenForIntent();
      });
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

  Future<void> _listenForIntent() async {
    if (!_speechAvailable) {
      debugPrint("Speech not available for intent");
      return;
    }
    
    await _tts.stop();
    
    setState(() {
      _listeningField = 'intent';
      _isListeningForName = true; // Visual cue
    });

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          debugPrint("🎤 Choice: '$words'");
          
          if (result.finalResult) {
            bool isLogin = words.contains('connecter') || words.contains('login') || 
                          words.contains('membre') || words.contains('connexion') ||
                          words.contains('تسجيل') || words.contains('دخول');
                          
            bool isGuest = words.contains('invité') || words.contains('guest') || 
                          words.contains('ضيف') || words.contains('متابعة');

            if (isLogin) {
              _startVoiceInput('name');
            } else if (isGuest) {
              _speak(_T("D'accord, mode invité.", "Okay, guest mode.", "حسنًا، وضع الضيف."));
              _continueAsGuest();
            } else {
              _speak(_T("Je n'ai pas compris. Veuillez dire Se Connecter ou Invité.", 
                       "I didn't understand. Please say Login or Guest.", 
                       "لم أفهم. يرجى قول تسجيل الدخول أو ضيف."));
              Future.delayed(const Duration(seconds: 4), () {
                 if (mounted) _listenForIntent();
              });
            }
          }
        },
        listenFor: const Duration(seconds: 4),
        pauseFor: const Duration(seconds: 2),
        localeId: _T('fr-FR', 'en-US', 'ar-SA'),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("Intent Error: $e");
      _stopVoiceInput();
    }
  }

  Future<void> _startVoiceInput(String field) async {
    if (!_speechAvailable) {
      _showErrorSnackBar('Reconnaissance vocale non disponible');
      _speak("La reconnaissance vocale n'est pas disponible sur cet appareil.");
      return;
    }
    
    // 1. Force stop everything first
    await _tts.stop();
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    setState(() {
      _listeningField = field;
      if (field == 'name') {
        _isListeningForName = true;
        _isListeningForPin = false;
        _nameController.clear();
      } else {
        _isListeningForPin = true;
        _isListeningForName = false;
        _pinController.clear();
      }
    });
    
    final prompt = field == 'name' 
        ? _T('Quel est votre nom ?', 'What is your name?', 'ما هو اسمك؟') 
        : _T('Dites les 3 chiffres du code', 'Say the 3 digit code', 'قل أرقام الرمز الثلاثة');
    
    await _tts.speak(prompt);
    
    // Wait for the prompt to finish + safety margin
    // We wait 3 seconds to be absolutely sure the prompt is over
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;

    try {
      debugPrint("🎤 Starting mic for $field...");
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          
          debugPrint("🎤 Heard ($field): '$words'");
          
          if (words.toLowerCase().contains('invité') || 
              words.toLowerCase().contains('guest') || 
              words.toLowerCase().contains('ضيف')) {
            _stopVoiceInput();
            _speak(_T("Connexion en tant qu'invité", "Continuing as guest", "جارٍ تسجيل الدخول كضيف"));
            _continueAsGuest();
            return;
          }

          setState(() {
            if (field == 'name') {
              _nameController.text = words;
              // Set cursor to end
              _nameController.selection = TextSelection.fromPosition(
                TextPosition(offset: _nameController.text.length),
              );
            } else {
              final digits = words.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isNotEmpty) {
                _pinController.text = digits.length > 3 ? digits.substring(0, 3) : digits;
              }
            }
          });
          
          if (result.finalResult) {
            debugPrint("🎤 Final result for $field: '$words'");
            _stopVoiceInput();
            
            if (field == 'name' && _nameController.text.isNotEmpty) {
              final name = _nameController.text;
              _speak(_T('Bonjour $name. Maintenant, dites le code.', 
                         'Hello $name. Now, say the code.',
                         'مرحبًا $name. الآن، قل الرمز.'));
              
              // Delay before starting next field to let TTS finish
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) _startVoiceInput('pin');
              });
            } else if (field == 'pin' && _pinController.text.length == 3) {
              _speak(_T('Code reçu. Connexion en cours...', 
                         'Code received. Logging in...', 
                         'تم استلام الرمز. جارٍ تسجيل الدخول...'));
              _login();
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: _T('fr-FR', 'en-US', 'ar-SA'),
        cancelOnError: true,
        listenMode: ListenMode.confirmation, // Switching to confirmation for shorter inputs
      );
    } catch (e) {
      debugPrint("❌ Voice Error ($field): $e");
      _stopVoiceInput();
      _speak(_T("Je n'ai pas compris. Veuillez réessayer.", "I didn't understand. Please retry.", "لم أفهم. يرجى المحاولة مرة أخرى."));
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
        
        final role = (userDoc.data()['role'] ?? '').toString();
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
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _T('Contactez l\'administrateur', 'Contact admin', 'اتصل بالمسؤول'), 
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
              _T('Besoin d\'aide?', 'Need help?', 'تحتاج مساعدة؟'), 
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
        SizedBox(height: 24),
        // DEBUG BUTTON for Test Event
        TextButton(
          onPressed: _createTestEvent,
          child: Text(
            "🛠️ Créer Test Event (+30 min)",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        // DEBUG BUTTON for Demo Users
        TextButton(
          onPressed: _createDemoUsers,
          child: Text(
            "👥 Créer Utilisateurs Demo",
            style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        // DEBUG BUTTON for Real Events
        TextButton(
          onPressed: _createRealEvents,
          child: Text(
            "🏃 Créer 4 Événements Réels",
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _createRealEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // ESPRIT El Ghazala coordinates: 36°53'59.9"N 10°11'22.7"E
      // = 36.8999722, 10.1896389
      
      // Current date: Feb 7, 2026
      // Tomorrow: Feb 8, 2026
      final tomorrow = DateTime(2026, 2, 8);
      final dayAfter = DateTime(2026, 2, 9);
      final weekend = DateTime(2026, 2, 14); // Saturday
      final nextWeek = DateTime(2026, 2, 15); // Sunday
      
      final List<Map<String, dynamic>> events = [
        // EVENT 1: Tomorrow 11PM - 5km Night Run
        {
          "accessibility": {
            "audioGuidanceAvailable": true,
            "buddySystemAvailable": true,
            "signLanguageSupport": false,
            "visualGuidanceAvailable": true,
            "wheelchairAccessible": false,
          },
          "category": "endurance",
          "createdAt": FieldValue.serverTimestamp(),
          "createdBy": "system_debug",
          "creatorName": "Running Club Tunis",
          "creatorRole": "main_admin",
          "date": Timestamp.fromDate(DateTime(2026, 2, 8, 23, 0)), // Feb 8, 11PM
          "description": "Course nocturne de 5km autour du campus ESPRIT. Parcours plat, idéal pour les débutants. Lampes frontales recommandées.",
          "descriptionAr": "سباق ليلي 5 كم حول حرم إسبري. مسار مستو، مثالي للمبتدئين. يُنصح بالمصابيح الأمامية.",
          "duration": 45,
          "endTime": "23:45",
          "groupColor": "#4CAF50",
          "groupId": "beginner",
          "groupName": "Débutants",
          "intensity": "low",
          "isAllGroups": true,
          "isCancelled": false,
          "isFeatured": true,
          "isPinned": true,
          "maxParticipants": 50,
          "meetingPoint": {
            "address": "ESPRIT El Ghazala, Route de la Marsa, Ariana",
            "coordinates": {
              "latitude": 36.8999722,
              "longitude": 10.1896389,
            },
            "name": "ESPRIT - Entrée Principale",
            "nameAr": "إسبري - المدخل الرئيسي",
          },
          "parkingAvailable": true,
          "publicTransport": ["Bus 29", "Metro B - Ariana"],
          "participantCount": 0,
          "participants": [],
          "publishedAt": FieldValue.serverTimestamp(),
          "route": {
            "difficulty": "easy",
            "distance": 5,
            "elevation": 20,
            "routeDescription": "2 loops around ESPRIT campus and nearby streets",
            "routeDescriptionAr": "دورتان حول حرم إسبري والشوارع المجاورة",
            "terrain": "paved",
          },
          "startTime": "23:00",
          "status": "upcoming",
          "targetPace": "6:30",
          "title": "Course Nocturne 5K - ESPRIT",
          "titleAr": "سباق ليلي 5 كم - إسبري",
          "type": "special",
          "updatedAt": FieldValue.serverTimestamp(),
          "waitlist": [],
        },
        
        // EVENT 2: Day after tomorrow - 10km Morning Run
        {
          "accessibility": {
            "audioGuidanceAvailable": true,
            "buddySystemAvailable": true,
            "signLanguageSupport": false,
            "visualGuidanceAvailable": true,
            "wheelchairAccessible": false,
          },
          "category": "tempo",
          "createdAt": FieldValue.serverTimestamp(),
          "createdBy": "system_debug",
          "creatorName": "Running Club Tunis",
          "creatorRole": "coach_admin",
          "date": Timestamp.fromDate(DateTime(2026, 2, 9, 7, 0)), // Feb 9, 7AM
          "description": "Sortie matinale 10km vers le Lac de Tunis. Rythme modéré, retour par la route côtière. Apportez de l'eau.",
          "descriptionAr": "خروج صباحي 10 كم نحو بحيرة تونس. إيقاع معتدل، العودة عبر الطريق الساحلي. أحضر الماء.",
          "duration": 70,
          "endTime": "08:10",
          "groupColor": "#FFC107",
          "groupId": "intermediate",
          "groupName": "Intermédiaires",
          "intensity": "medium",
          "isAllGroups": false,
          "isCancelled": false,
          "isFeatured": true,
          "isPinned": false,
          "maxParticipants": 35,
          "meetingPoint": {
            "address": "Technopole El Ghazala, Ariana",
            "coordinates": {
              "latitude": 36.8985,
              "longitude": 10.1880,
            },
            "name": "Technopole El Ghazala - Parking",
            "nameAr": "تكنوبول الغزالة - موقف السيارات",
          },
          "parkingAvailable": true,
          "publicTransport": ["Bus 29", "TGM La Marsa"],
          "participantCount": 0,
          "participants": [],
          "publishedAt": FieldValue.serverTimestamp(),
          "route": {
            "difficulty": "moderate",
            "distance": 10,
            "elevation": 45,
            "routeDescription": "El Ghazala → Lac de Tunis → Retour côtier",
            "routeDescriptionAr": "الغزالة ← بحيرة تونس ← العودة الساحلية",
            "terrain": "mixed",
          },
          "startTime": "07:00",
          "status": "upcoming",
          "targetPace": "5:45",
          "title": "Sortie Matinale 10K - El Ghazala",
          "titleAr": "خروج صباحي 10 كم - الغزالة",
          "type": "daily",
          "updatedAt": FieldValue.serverTimestamp(),
          "waitlist": [],
        },
        
        // EVENT 3: Weekend Saturday - Trail Run 15km
        {
          "accessibility": {
            "audioGuidanceAvailable": true,
            "buddySystemAvailable": true,
            "signLanguageSupport": false,
            "visualGuidanceAvailable": false,
            "wheelchairAccessible": false,
          },
          "category": "trail",
          "createdAt": FieldValue.serverTimestamp(),
          "createdBy": "system_debug",
          "creatorName": "Running Club Tunis",
          "creatorRole": "coach_admin",
          "date": Timestamp.fromDate(DateTime(2026, 2, 14, 8, 30)), // Feb 14, 8:30AM
          "description": "Trail de la Saint-Valentin! Parcours nature vers Sidi Bou Saïd. Vues spectaculaires, terrain varié. Niveau avancé requis.",
          "descriptionAr": "تريل عيد الحب! مسار طبيعي نحو سيدي بوسعيد. مناظر خلابة، تضاريس متنوعة. مستوى متقدم مطلوب.",
          "duration": 120,
          "endTime": "10:30",
          "groupColor": "#E91E63",
          "groupId": "advanced",
          "groupName": "Avancés",
          "intensity": "high",
          "isAllGroups": false,
          "isCancelled": false,
          "isFeatured": true,
          "isPinned": true,
          "maxParticipants": 25,
          "meetingPoint": {
            "address": "ESPRIT El Ghazala, Ariana",
            "coordinates": {
              "latitude": 36.8999722,
              "longitude": 10.1896389,
            },
            "name": "ESPRIT - Portail Sud",
            "nameAr": "إسبري - البوابة الجنوبية",
          },
          "parkingAvailable": true,
          "publicTransport": ["Bus 29", "Metro B"],
          "participantCount": 0,
          "participants": [],
          "publishedAt": FieldValue.serverTimestamp(),
          "route": {
            "difficulty": "hard",
            "distance": 15,
            "elevation": 180,
            "routeDescription": "ESPRIT → Raoued → Sidi Bou Saïd → Retour La Marsa",
            "routeDescriptionAr": "إسبري ← رواد ← سيدي بوسعيد ← العودة المرسى",
            "terrain": "trail",
          },
          "startTime": "08:30",
          "status": "upcoming",
          "targetPace": "7:00",
          "title": "Trail Saint-Valentin 15K 💕",
          "titleAr": "تريل عيد الحب 15 كم 💕",
          "type": "special",
          "updatedAt": FieldValue.serverTimestamp(),
          "waitlist": [],
        },
        
        // EVENT 4: Sunday - Recovery Jog + Coffee
        {
          "accessibility": {
            "audioGuidanceAvailable": true,
            "buddySystemAvailable": true,
            "signLanguageSupport": true,
            "visualGuidanceAvailable": true,
            "wheelchairAccessible": true,
          },
          "category": "recovery",
          "createdAt": FieldValue.serverTimestamp(),
          "createdBy": "system_debug",
          "creatorName": "Running Club Tunis",
          "creatorRole": "main_admin",
          "date": Timestamp.fromDate(DateTime(2026, 2, 15, 9, 0)), // Feb 15, 9AM
          "description": "Footing léger suivi d'un petit-déjeuner convivial au café du coin. Ouvert à tous niveaux, ambiance détendue!",
          "descriptionAr": "جري خفيف يعقبه فطور ودي في المقهى المجاور. مفتوح لجميع المستويات، أجواء مريحة!",
          "duration": 90,
          "endTime": "10:30",
          "groupColor": "#9C27B0",
          "groupId": "all",
          "groupName": "Tous Niveaux",
          "intensity": "low",
          "isAllGroups": true,
          "isCancelled": false,
          "isFeatured": false,
          "isPinned": false,
          "maxParticipants": 60,
          "meetingPoint": {
            "address": "Café La Pause, Technopole El Ghazala",
            "coordinates": {
              "latitude": 36.8995,
              "longitude": 10.1905,
            },
            "name": "Café La Pause - Technopole",
            "nameAr": "مقهى لا بوز - التكنوبول",
          },
          "parkingAvailable": true,
          "publicTransport": ["Bus 29", "Metro B - Ariana"],
          "participantCount": 0,
          "participants": [],
          "publishedAt": FieldValue.serverTimestamp(),
          "route": {
            "difficulty": "easy",
            "distance": 3,
            "elevation": 10,
            "routeDescription": "Easy loop around the tech park, then coffee!",
            "routeDescriptionAr": "جولة سهلة حول الحديقة التقنية، ثم قهوة!",
            "terrain": "paved",
          },
          "startTime": "09:00",
          "status": "upcoming",
          "targetPace": "7:30",
          "title": "Footing + Café ☕ (Dimanche Chill)",
          "titleAr": "جري خفيف + قهوة ☕ (أحد مريح)",
          "type": "social",
          "updatedAt": FieldValue.serverTimestamp(),
          "waitlist": [],
        },
      ];
      
      int createdCount = 0;
      
      for (final eventData in events) {
        try {
          await firestore.collection('events').add(eventData);
          createdCount++;
          debugPrint("✅ Created event: ${eventData['title']}");
        } catch (e) {
          debugPrint("❌ Failed to create event: $e");
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("✅ $createdCount événements créés!"),
                const SizedBox(height: 4),
                const Text("📍 Lieu: ESPRIT El Ghazala", style: TextStyle(fontSize: 11)),
                const Text("📅 8 Fév 23h, 9 Fév 7h, 14 Fév 8h30, 15 Fév 9h", style: TextStyle(fontSize: 10)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error creating events: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDemoUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final now = Timestamp.now();
      
      // ==================== ADMIN USERS ====================
      final List<Map<String, dynamic>> adminUsers = [
        {
          "email": "admin.principal@runningclubtunis.tn",
          "password": "000123",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 1,
            "cin": "encrypted:12345678",
            "createdAt": now,
            "email": "admin.principal@runningclubtunis.tn",
            "fullName": "Mohamed Ben Ali",
            "groupId": "all",
            "isActive": true,
            "permissions": {
              "canCreateEvents": true,
              "canDeleteUsers": true,
              "canEditUsers": true,
              "canManageGroups": true,
              "canPostAnnouncements": true,
              "canViewAnalytics": true,
            },
            "phone": "+216 98 765 432",
            "pin": "123",
            "pinHash": "hash-123",
            "role": "main_admin",
            "updatedAt": now,
          }
        },
        {
          "email": "coach.senior@runningclubtunis.tn",
          "password": "000456",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 2,
            "cin": "encrypted:87654321",
            "createdAt": now,
            "email": "coach.senior@runningclubtunis.tn",
            "fullName": "Fatma Trabelsi",
            "groupId": "advanced",
            "isActive": true,
            "permissions": {
              "canCreateEvents": true,
              "canDeleteUsers": false,
              "canEditUsers": true,
              "canManageGroups": true,
              "canPostAnnouncements": true,
              "canViewAnalytics": true,
            },
            "phone": "+216 55 123 456",
            "pin": "456",
            "pinHash": "hash-456",
            "role": "coach_admin",
            "updatedAt": now,
          }
        },
        {
          "email": "assistant.admin@runningclubtunis.tn",
          "password": "000789",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 3,
            "cin": "encrypted:11223344",
            "createdAt": now,
            "email": "assistant.admin@runningclubtunis.tn",
            "fullName": "Ahmed Khediri",
            "groupId": "intermediate",
            "isActive": true,
            "permissions": {
              "canCreateEvents": true,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": true,
              "canViewAnalytics": false,
            },
            "phone": "+216 22 987 654",
            "pin": "789",
            "pinHash": "hash-789",
            "role": "sub_admin",
            "updatedAt": now,
          }
        },
      ];
      
      // ==================== ADHERANT USERS ====================
      final List<Map<String, dynamic>> memberUsers = [
        {
          "email": "samir.jaziri@gmail.com",
          "password": "000111",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 0,
            "cin": "encrypted:55667788",
            "createdAt": now,
            "email": "samir.jaziri@gmail.com",
            "fullName": "Samir Jaziri",
            "groupId": "beginner",
            "isActive": true,
            "permissions": {
              "canCreateEvents": false,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": false,
              "canViewAnalytics": false,
            },
            "phone": "+216 20 111 222",
            "pin": "111",
            "pinHash": "hash-111",
            "role": "user",
            "updatedAt": now,
          }
        },
        {
          "email": "nadia.bouazizi@outlook.com",
          "password": "000222",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 0,
            "cin": "encrypted:99887766",
            "createdAt": now,
            "email": "nadia.bouazizi@outlook.com",
            "fullName": "Nadia Bouazizi",
            "groupId": "intermediate",
            "isActive": true,
            "permissions": {
              "canCreateEvents": false,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": false,
              "canViewAnalytics": false,
            },
            "phone": "+216 25 333 444",
            "pin": "222",
            "pinHash": "hash-222",
            "role": "user",
            "updatedAt": now,
          }
        },
        {
          "email": "karim.belhaj@gmail.com",
          "password": "000333",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 0,
            "cin": "encrypted:44556677",
            "createdAt": now,
            "email": "karim.belhaj@gmail.com",
            "fullName": "Karim Belhaj",
            "groupId": "advanced",
            "isActive": true,
            "permissions": {
              "canCreateEvents": false,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": false,
              "canViewAnalytics": false,
            },
            "phone": "+216 29 555 666",
            "pin": "333",
            "pinHash": "hash-333",
            "role": "user",
            "updatedAt": now,
          }
        },
        {
          "email": "leila.mansour@yahoo.fr",
          "password": "000444",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 0,
            "cin": "encrypted:22334455",
            "createdAt": now,
            "email": "leila.mansour@yahoo.fr",
            "fullName": "Leila Mansour",
            "groupId": "beginner",
            "isActive": true,
            "permissions": {
              "canCreateEvents": false,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": false,
              "canViewAnalytics": false,
            },
            "phone": "+216 23 777 888",
            "pin": "444",
            "pinHash": "hash-444",
            "role": "user",
            "updatedAt": now,
          }
        },
        {
          "email": "youssef.hamdi@gmail.com",
          "password": "000555",
          "data": {
            "accountCreatedBy": "system_debug",
            "accountStatus": "active",
            "adminLevel": 0,
            "cin": "encrypted:66778899",
            "createdAt": now,
            "email": "youssef.hamdi@gmail.com",
            "fullName": "Youssef Hamdi",
            "groupId": "intermediate",
            "isActive": true,
            "permissions": {
              "canCreateEvents": false,
              "canDeleteUsers": false,
              "canEditUsers": false,
              "canManageGroups": false,
              "canPostAnnouncements": false,
              "canViewAnalytics": false,
            },
            "phone": "+216 27 999 000",
            "pin": "555",
            "pinHash": "hash-555",
            "role": "user",
            "updatedAt": now,
          }
        },
      ];
      
      int createdCount = 0;
      int failedCount = 0;
      
      // Create all users
      final allUsers = [...adminUsers, ...memberUsers];
      
      for (final userConfig in allUsers) {
        try {
          // Create Firebase Auth user
          final UserCredential cred = await auth.createUserWithEmailAndPassword(
            email: userConfig["email"],
            password: userConfig["password"],
          );
          
          // Create Firestore document with the Auth UID
          final userData = Map<String, dynamic>.from(userConfig["data"]);
          userData["userId"] = cred.user!.uid;
          
          await firestore.collection('users').doc(cred.user!.uid).set(userData);
          
          createdCount++;
          debugPrint("✅ Created user: ${userData['fullName']} (${userData['role']})");
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
            debugPrint("⚠️ User already exists: ${userConfig['email']}");
          } else {
            debugPrint("❌ Failed to create ${userConfig['email']}: $e");
            failedCount++;
          }
        }
      }
      
      // Sign out after creating users
      await auth.signOut();
      
      if (mounted) {
        final message = createdCount > 0 
            ? "✅ $createdCount utilisateurs créés avec succès!"
            : "⚠️ Aucun nouvel utilisateur créé (peut-être déjà existants)";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (failedCount > 0) Text("$failedCount échecs"),
                const SizedBox(height: 4),
                const Text("📌 PIN Admins: 123, 456, 789", style: TextStyle(fontSize: 11)),
                const Text("📌 PIN Adhérents: 111, 222, 333, 444, 555", style: TextStyle(fontSize: 11)),
              ],
            ),
            backgroundColor: createdCount > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error creating demo users: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestEvent() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final eventDate = now.add(const Duration(minutes: 30));
      final endDate = eventDate.add(const Duration(minutes: 90)); // 90 min duration

      final startHour = eventDate.hour.toString().padLeft(2, '0');
      final startMin = eventDate.minute.toString().padLeft(2, '0');
      final endHour = endDate.hour.toString().padLeft(2, '0');
      final endMin = endDate.minute.toString().padLeft(2, '0');

      final eventData = {
        "accessibility": {
          "audioGuidanceAvailable": true,
          "buddySystemAvailable": true,
          "signLanguageSupport": false,
          "visualGuidanceAvailable": true,
          "wheelchairAccessible": false,
        },
        "category": "tempo",
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": "HFQxwxxNGEfJhmqvOcuw69m9KMT2",
        "creatorName": "test admin",
        "creatorRole": "main_admin",
        "date": Timestamp.fromDate(eventDate),
        "description": "15 min warmup, 10K tempo at race pace, 10 min cooldown",
        "descriptionAr": "15 دقيقة إحماء، 10 كم إيقاع سريع، 10 دقائق استرخاء",
        "duration": 90,
        "endTime": "$endHour:$endMin",
        "groupColor": "#FFC107",
        "groupId": "intermediate",
        "groupName": "Intermédiaires",
        "intensity": "high",
        "isAllGroups": false,
        "isCancelled": false,
        "isFeatured": true,
        "isPinned": false,
        "maxParticipants": 40,
        "meetingPoint": {
          "address": "Avenue de la Ligue Arabe, Tunis",
          "coordinates": {
            "latitude": 36.835,
            "longitude": 10.21,
          },
          "name": "Lac de Tunis - Entrée Sud",
          "nameAr": "بحيرة تونس - المدخل الجنوبي",
        },
        "parkingAvailable": true,
        "publicTransport": [
          "Bus 20",
          "Metro Ligne 5"
        ],
        "participantCount": 0,
        "participants": [
          "JVURI4eq75etttrHAEDEBD5gTGb2"
        ],
        "publishedAt": FieldValue.serverTimestamp(),
        "route": {
          "difficulty": "moderate",
          "distance": 12,
          "elevation": 50,
          "routeDescription": "Flat course around the lake, 3 loops of 4km each",
          "routeDescriptionAr": "مسار مستو حول البحيرة، 3 دورات من 4 كم لكل منها",
          "terrain": "paved",
        },
        "startTime": "$startHour:$startMin",
        "status": "upcoming",
        "targetPace": "5:45",
        "title": "Morning Tempo Run",
        "titleAr": "جري الإيقاع الصباحي",
        "type": "daily",
        "updatedAt": FieldValue.serverTimestamp(),
        "waitlist": [],
      };

      await FirebaseFirestore.instance.collection('events').add(eventData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Événement de test créé pour dans 30 min !"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error creating test event: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
