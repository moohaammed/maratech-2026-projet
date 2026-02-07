import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/services/accessibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is here due to explicit usage

/// Voice-First Accessibility Wizard with Language Selection
/// 
/// FLOW:
/// 0. LANGUAGE SELECTION - French, Arabic, English
/// 1. Ask about vision
/// 2. Ask about hearing
/// 3. Ask about motor abilities
/// 4. Summary and finish
class AccessibilityWizardScreen extends StatefulWidget {
  const AccessibilityWizardScreen({super.key});

  @override
  State<AccessibilityWizardScreen> createState() => _AccessibilityWizardScreenState();
}

class _AccessibilityWizardScreenState extends State<AccessibilityWizardScreen> {
  late AccessibilityService _accessibility;
  bool _isInitialized = false;
  int _currentStep = 0; // 0 = language
  
  // Voice mode - if user taps screen, we disable voice mode
  bool _useVoiceMode = true;
  bool _userHasTouched = false; // Track if user used touch
  
  // Real-time speech display
  String _recognizedText = '';

  // Selections
  AppLanguage _selectedLanguage = AppLanguage.french;
  String _visualNeeds = 'normal';
  String _audioNeeds = 'normal';
  String _motorNeeds = 'normal';
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _boldText = false;

  @override
  void initState() {
    super.initState();
    _accessibility = AccessibilityService();
    _initializeAndStart();
  }

  Future<void> _initializeAndStart() async {
    await _accessibility.initialize();
    
    // Set up real-time speech display callback
    _accessibility.onSpeechRecognized = (text) {
      setState(() => _recognizedText = text);
    };
    
    setState(() => _isInitialized = true);

    // Start with voice welcome
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLanguageSelection();
    });
  }

  /// User touched the screen - disable voice mode for sighted users
  void _onUserTouch() {
    if (!_userHasTouched) {
      setState(() {
        _userHasTouched = true;
        _useVoiceMode = false;
      });
      // Stop listening and speaking
      _accessibility.stopContinuousListening();
      _accessibility.stopSpeaking();
      debugPrint('👆 User touched screen - voice mode disabled');
    }
  }

  Future<void> _startLanguageSelection() async {
    // ALWAYS speak welcome on launch!
    debugPrint('🎙️ Starting voice welcome...');
    
    // Force TTS to speak
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 1. Speak French
    await _accessibility.setLanguage(AppLanguage.french);
    await _accessibility.speakWithHaptic(
      "Bienvenue dans Running Club Tunis! Dites Français, Arabe, ou Anglais."
    );
    await _accessibility.waitForSpeechComplete();

    // 2. Speak Arabic (Switching language ensures it is spoken correctly)
    await _accessibility.setLanguage(AppLanguage.arabic);
    await _accessibility.speak(
      "مرحبا! قل عربي، فرنسي، أو إنجليزي."
    );
    await _accessibility.waitForSpeechComplete();

    // 3. Speak English
    await _accessibility.setLanguage(AppLanguage.english);
    await _accessibility.speak(
      "Welcome! Say English, French, or Arabic."
    );
    await _accessibility.waitForSpeechComplete();
    
    // Reset to default (French) or keep English, but we should listen now.
    // Let's set back to French as default fallback for listening if needed, 
    // BUT listening actually uses the current language. 
    // We should probably enable listening for multiple languages or just expect the user to reply in any.
    // Since we can't easily listen in 3 languages at once with standard plugins, we might stick to one or rely on the fact that "Arabe" / "Arabic" sounds similar.
    // However, for recognition to work well for "Arabe" (French word), we need French locale?
    // actually _accessibility.startContinuousListening() uses _currentLanguage.ttsCode. 
    
    // Let's set it back to French as a baseline as it's the primary language of the region.
    await _accessibility.setLanguage(AppLanguage.french);
    
    // Register language voice commands
    _registerLanguageCommands();
    
    // Start listening immediately (Barge-in enabled)
    if (_useVoiceMode) {
      // Don't wait for speech to complete
      _accessibility.startContinuousListening();
    }
  }

  void _registerLanguageCommands() {
    _accessibility.clearVoiceCommands();
    
    // French commands (incl. phonetics)
    _accessibility.registerVoiceCommand('français', () => _selectLanguage(AppLanguage.french));
    _accessibility.registerVoiceCommand('french', () => _selectLanguage(AppLanguage.french));
    _accessibility.registerVoiceCommand('francais', () => _selectLanguage(AppLanguage.french));
    _accessibility.registerVoiceCommand('france', () => _selectLanguage(AppLanguage.french));
    _accessibility.registerVoiceCommand('fransi', () => _selectLanguage(AppLanguage.french));

    // Arabic commands (incl. phonetics)
    _accessibility.registerVoiceCommand('arabe', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('arabic', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('arabia', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('arabi', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('arab', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('عربي', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('العربية', () => _selectLanguage(AppLanguage.arabic));
    _accessibility.registerVoiceCommand('عربية', () => _selectLanguage(AppLanguage.arabic));
    
    // English commands (incl. phonetics)
    _accessibility.registerVoiceCommand('anglais', () => _selectLanguage(AppLanguage.english));
    _accessibility.registerVoiceCommand('english', () => _selectLanguage(AppLanguage.english));
    _accessibility.registerVoiceCommand('inglish', () => _selectLanguage(AppLanguage.english));
    _accessibility.registerVoiceCommand('angle', () => _selectLanguage(AppLanguage.english));
    
    // Navigation
    _accessibility.registerVoiceCommand('continuer', _nextStep);
    _accessibility.registerVoiceCommand('continue', _nextStep);
    _accessibility.registerVoiceCommand('متابعة', _nextStep);
    _accessibility.registerVoiceCommand('suivant', _nextStep);
    _accessibility.registerVoiceCommand('next', _nextStep);
  }

  void _registerVisionCommands() {
    _accessibility.clearVoiceCommands();
    
    // Navigation
    _accessibility.registerVoiceCommand('continuer', _nextStep);
    _accessibility.registerVoiceCommand('continue', _nextStep);
    _accessibility.registerVoiceCommand('suivant', _nextStep);
    _accessibility.registerVoiceCommand('retour', _previousStep);
    _accessibility.registerVoiceCommand('back', _previousStep);
    _accessibility.registerVoiceCommand('passer', _skipToLogin);
    
    // Yes/No
    _accessibility.registerVoiceCommand('oui', () {
      _selectVisual('blind');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('yes', () {
      _selectVisual('blind');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('نعم', () {
      _selectVisual('blind');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('non', () {
      _selectVisual('normal');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('no', () {
      _selectVisual('normal');
      _nextStep();
    });
    
    // Vision options (French)
    _accessibility.registerVoiceCommand('normal', () => _selectVisual('normal'));
    _accessibility.registerVoiceCommand('standard', () => _selectVisual('normal'));
    _accessibility.registerVoiceCommand('bien', () => _selectVisual('normal'));
    
    _accessibility.registerVoiceCommand('agrandi', () => _selectVisual('low_vision'));
    _accessibility.registerVoiceCommand('grand', () => _selectVisual('low_vision'));
    _accessibility.registerVoiceCommand('plus grand', () => _selectVisual('low_vision'));
    
    _accessibility.registerVoiceCommand('aveugle', () => _selectVisual('blind'));
    _accessibility.registerVoiceCommand('blind', () => _selectVisual('blind'));
    
    // English
    _accessibility.registerVoiceCommand('see well', () => _selectVisual('normal'));
    _accessibility.registerVoiceCommand('larger', () => _selectVisual('low_vision'));
    _accessibility.registerVoiceCommand('bigger', () => _selectVisual('low_vision'));
  }

  void _registerHearingCommands() {
    _accessibility.clearVoiceCommands();
    
    // Navigation
    _accessibility.registerVoiceCommand('continuer', _nextStep);
    _accessibility.registerVoiceCommand('continue', _nextStep);
    _accessibility.registerVoiceCommand('suivant', _nextStep);
    _accessibility.registerVoiceCommand('retour', _previousStep);
    
    // Yes/No
    _accessibility.registerVoiceCommand('oui', () {
      _selectAudio('deaf');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('yes', () {
      _selectAudio('deaf');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('non', () {
      _selectAudio('normal');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('no', () {
      _selectAudio('normal');
      _nextStep();
    });
    
    // Hearing options
    _accessibility.registerVoiceCommand('entends', () => _selectAudio('normal'));
    _accessibility.registerVoiceCommand('hear', () => _selectAudio('normal'));
    _accessibility.registerVoiceCommand('vibration', () => _selectAudio('hearing_loss'));
    _accessibility.registerVoiceCommand('sourd', () => _selectAudio('deaf'));
    _accessibility.registerVoiceCommand('deaf', () => _selectAudio('deaf'));
  }

  void _registerMotorCommands() {
    _accessibility.clearVoiceCommands();
    
    // Navigation
    _accessibility.registerVoiceCommand('continuer', _nextStep);
    _accessibility.registerVoiceCommand('continue', _nextStep);
    _accessibility.registerVoiceCommand('terminer', _finishOnboarding);
    _accessibility.registerVoiceCommand('finish', _finishOnboarding);
    _accessibility.registerVoiceCommand('retour', _previousStep);
    
    // Yes/No
    _accessibility.registerVoiceCommand('oui', () {
      _selectMotor('limited_dexterity');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('yes', () {
      _selectMotor('limited_dexterity');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('non', () {
      _selectMotor('normal');
      _nextStep();
    });
    _accessibility.registerVoiceCommand('no', () {
      _selectMotor('normal');
      _nextStep();
    });
    
    // Motor options
    _accessibility.registerVoiceCommand('normal', () => _selectMotor('normal'));
    _accessibility.registerVoiceCommand('standard', () => _selectMotor('normal'));
    _accessibility.registerVoiceCommand('difficultés', () => _selectMotor('limited_dexterity'));
    _accessibility.registerVoiceCommand('vocale', () => _selectMotor('limited_dexterity'));
    _accessibility.registerVoiceCommand('voice', () => _selectMotor('limited_dexterity'));
  }

  void _registerSummaryCommands() {
    _accessibility.clearVoiceCommands();
    
    _accessibility.registerVoiceCommand('commencer', _goToLogin);
    _accessibility.registerVoiceCommand('start', _goToLogin);
    _accessibility.registerVoiceCommand('continuer', _goToLogin);
    _accessibility.registerVoiceCommand('continue', _goToLogin);
    _accessibility.registerVoiceCommand('يبدأ', _goToLogin);
  }

  void _selectLanguage(AppLanguage language) async {
    setState(() => _selectedLanguage = language);
    await _accessibility.setLanguage(language);
    await _accessibility.vibrateSuccess();
    
    // Confirm in the selected language
    String message;
    switch (language.code) {
      case 'ar':
        message = 'تم اختيار اللغة العربية. قل متابعة للاستمرار.';
        break;
      case 'en':
        message = 'English selected. Say continue to proceed.';
        break;
      default:
        message = 'Français sélectionné. Dites continuer pour avancer.';
    }
    await _accessibility.speak(message);
  }

  void _selectVisual(String needs) {
    setState(() {
      _visualNeeds = needs;
      if (needs == 'normal') {
        // Reset all visual settings to defaults
        _textScale = 1.0;
        _highContrast = false;
        _boldText = false;
      } else if (needs == 'low_vision') {
        _textScale = 1.5;
        _highContrast = true;
        _boldText = true;
      } else if (needs == 'blind') {
        _highContrast = true; // Use simple high contrast for any UI remnants
        _boldText = true;
        // Enable full talkback simulation
        _accessibility.setVoiceCommands(true); 
      }
    });
    _accessibility.setVisualNeeds(needs);
    _accessibility.vibrateSuccess();
  }

  void _selectAudio(String needs) {
    setState(() => _audioNeeds = needs);
    _accessibility.setAudioNeeds(needs);
    _accessibility.vibrateSuccess();

    if (needs == 'deaf') {
      // Immediate Context Awareness: Deaf user can't hear us
      _accessibility.stopSpeaking(); 
      _accessibility.setVoiceCommands(false); // Can't speak commands if they can't hear prompts? Or maybe they can speak but prefer not to hear? 
      // Usually defaults to visual only.
    }
  }

  void _selectMotor(String needs) {
    setState(() => _motorNeeds = needs);
    _accessibility.setMotorNeeds(needs);
    _accessibility.vibrateSuccess();
    
    // Context Awareness: If user *spoke* this command, they rely on voice.
    // If they *tapped* this, they might not.
    // However, if needs == 'limited_dexterity', assume voice needed.
    if (needs == 'limited_dexterity') {
      _accessibility.setVoiceCommands(true);
    }
  }

  void _nextStep() async {
    await _accessibility.vibrateTap();
    
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _announceStep();
    } else {
      _goToLogin();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _accessibility.vibrateTap();
      setState(() => _currentStep--);
      _announceStep();
    }
  }

  void _announceStep() async {
    // interrupt previous speech is handled by speak() automatically
    
    switch (_currentStep) {
      case 0:
        _registerLanguageCommands();
        await _accessibility.speak(_getLanguagePrompt());
        break;
      case 1:
        _registerVisionCommands();
        await _accessibility.speak(_getVisionPrompt());
        break;
      case 2:
        _registerHearingCommands();
        await _accessibility.speak(_getHearingPrompt());
        break;
      case 3:
        _registerMotorCommands();
        await _accessibility.speak(_getMotorPrompt());
        break;
      case 4:
        _registerSummaryCommands();
        await _finishOnboarding();
        break;
    }
    
    // Start listening immediately (Barge-in)
    _accessibility.startContinuousListening();
  }

  String _getLanguagePrompt() {
    return "Choisissez votre langue. Dites français, arabe ou anglais.";
  }

  String _getVisionPrompt() {
    switch (_selectedLanguage.code) {
      case 'ar':
        return "السؤال 1 من 3. هل لديك صعوبات في الرؤية؟ قل نعم أو لا.";
      case 'en':
        return "Question 1 of 3. Do you have any visual difficulties? Say yes or no.";
      default:
        return "Question 1 sur 3. Avez-vous des difficultés visuelles? Dites oui ou non.";
    }
  }

  String _getHearingPrompt() {
    switch (_selectedLanguage.code) {
      case 'ar':
        return "السؤال 2 من 3. هل لديك صعوبات في السمع؟ قل نعم أو لا.";
      case 'en':
        return "Question 2 of 3. Do you have any hearing difficulties? Say yes or no.";
      default:
        return "Question 2 sur 3. Avez-vous des difficultés auditives? Dites oui ou non.";
    }
  }

  String _getMotorPrompt() {
    switch (_selectedLanguage.code) {
      case 'ar':
        return "السؤال 3 من 3. هل لديك صعوبات في استخدام يديك؟ إذا كانت الإجابة نعم، يمكنك التحكم بالتطبيق بصوتك.";
      case 'en':
        return "Question 3 of 3. Do you have difficulty using your hands? If yes, you can control the app with your voice.";
      default:
        return "Question 3 sur 3. Avez-vous des difficultés à utiliser vos mains? Si oui, vous pourrez contrôler l'application avec votre voix.";
    }
  }

  Future<void> _finishOnboarding() async {
    // Save deeply context-aware profile
    final profile = _accessibility.getProfileJson();
    final prefs = await SharedPreferences.getInstance();
    
    // Save for Auth screen to pick up later
    await prefs.setString('accessibility_profile_json', jsonEncode(profile));
    await prefs.setBool('onboarding_wizard_completed', true);
    
    // Debug log
    debugPrint('✅ Accessibility Profile Saved locally: ${jsonEncode(profile)}');
    
    await _accessibility.savePreferences();
    
    String message;
    switch (_selectedLanguage.code) {
      case 'ar':
        message = "اكتمل الإعداد! مرحبًا بك في نادي الجري تونس. قل ابدأ.";
        break;
      case 'en':
        message = "Setup complete! Welcome to Running Club Tunis. Say start.";
        break;
      default:
        message = "Configuration terminée! Bienvenue dans Running Club Tunis. Dites commencer.";
    }
    
    await _accessibility.speakWithHaptic(message);
    setState(() => _currentStep = 4);
  }

  void _skipToLogin() {
    _accessibility.speak(_selectedLanguage.code == 'en' ? "Skipping." : "Passage.");
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goToLogin() {
    _accessibility.stopContinuousListening();
    _accessibility.speak(_selectedLanguage.code == 'en' ? "Let's go!" : "Allons-y!");
    _accessibility.vibrateSuccess();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _accessibility.clearVoiceCommands();
    _accessibility.stopContinuousListening();
    _accessibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final useHighContrast = _highContrast || _visualNeeds == 'blind';
    final bgColor = useHighContrast ? Colors.black : AppColors.background;
    final textColor = useHighContrast ? Colors.white : Colors.black;
    final ts = _textScale;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: _currentStep > 0
            ? Semantics(
                button: true,
                label: _T('Retour', 'Back', 'رجوع'),
                child: IconButton(
                  onPressed: () {
                    _onUserTouch();
                    _previousStep();
                  },
                  icon: Icon(Icons.arrow_back, color: textColor),
                ),
              )
            : null,
        title: _currentStep == 0
            ? null // No title on language step (logo is in body) vs Standard title?
            : Text(
                _T('Étape $_currentStep / 4', 'Step $_currentStep / 4', 'الخطوة $_currentStep / 4'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18 * ts,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              _onUserTouch();
              _skipToLogin();
            },
            child: Text(
              _T('Passer', 'Skip', 'تخطي'),
              style: TextStyle(
                fontSize: 16 * ts,
                color: useHighContrast ? Colors.white70 : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar handles top
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Progress (moved out of SafeArea as AppBar handles top)
                if (_currentStep > 0)
                  _buildProgress(useHighContrast, ts),
                
                SizedBox(height: 16 * ts),
      
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24 * ts.clamp(1.0, 1.3)),
                    child: _buildCurrentStep(useHighContrast, textColor, ts),
                  ),
                ),
      
                // Listening indicator - ALWAYS VISIBLE
                _buildListeningIndicator(useHighContrast, ts),
      
                // Main button
                Padding(
                  padding: EdgeInsets.all(24 * ts.clamp(1.0, 1.3)),
                  child: _buildMainButton(useHighContrast, ts),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildProgress(bool useHighContrast, double ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LinearProgressIndicator(
        value: _currentStep / 4,
        backgroundColor: useHighContrast ? Colors.grey[800] : Colors.grey[200],
        valueColor: AlwaysStoppedAnimation(
          useHighContrast ? Colors.white : AppColors.primary,
        ),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildListeningIndicator(bool useHighContrast, double ts) {
    if (!_useVoiceMode) return const SizedBox.shrink();

    final isListening = _accessibility.isListening;
    
    return Column(
      children: [
        // Real-time Text Bubble (Floating)
        if (_recognizedText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: useHighContrast ? Colors.white : Colors.black87,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '"$_recognizedText"',
              style: TextStyle(
                color: useHighContrast ? Colors.black : Colors.white,
                fontSize: 18 * ts,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Minimalist Status Indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isListening 
                ? (useHighContrast ? Colors.white : AppColors.primary.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isListening 
                ? Border.all(color: AppColors.primary.withOpacity(0.5)) 
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isListening ? 1.2 : 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening 
                          ? (useHighContrast ? Colors.black : AppColors.primary) 
                          : Colors.grey,
                      size: 24 * ts,
                    ),
                  );
                },
                onEnd: () {
                   // Loop animation manually if needed in a stateful widget, 
                   // but simplified here for reliability.
                },
              ),
              if (isListening) ...[
                SizedBox(width: 8),
                Text(
                  _T('Je vous écoute...', 'I\'m listening...', 'أنا أستمع...'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14 * ts,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(bool useHighContrast, double ts) {
    final isLast = _currentStep == 4;
    final buttonText = isLast 
      ? _T('Commencer', 'Start', 'ابدأ')
      : _T('Continuer', 'Continue', 'متابعة');
    
    return SizedBox(
      width: double.infinity,
      height: 64 * ts.clamp(1.0, 1.3),
      child: ElevatedButton(
        onPressed: () {
          _onUserTouch(); // Disable voice mode when user touches
          if (isLast) {
            _goToLogin();
          } else {
            _nextStep();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: useHighContrast ? Colors.white : AppColors.primary,
          foregroundColor: useHighContrast ? Colors.black : Colors.white,
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: useHighContrast ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 20 * ts,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool useHighContrast, Color textColor, double ts) {
    switch (_currentStep) {
      case 0:
        return _buildLanguageStep(useHighContrast, textColor, ts);
      case 1:
        return _buildVisionStep(useHighContrast, textColor, ts);
      case 2:
        return _buildHearingStep(useHighContrast, textColor, ts);
      case 3:
        return _buildMotorStep(useHighContrast, textColor, ts);
      case 4:
        return _buildSummaryStep(useHighContrast, textColor, ts);
      default:
        return const SizedBox();
    }
  }

  Widget _buildLanguageStep(bool useHighContrast, Color textColor, double ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Standard App Header with Logo
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => const Icon(Icons.language, size: 50, color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 16 * ts),
              Text(
                _T('Choisissez votre langue', 'Choose your language', 'اختر لغتك'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32 * ts),

        // Standard Material Cards
        for (final lang in AppLanguage.all)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: _selectedLanguage.code == lang.code ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: _selectedLanguage.code == lang.code 
                  ? BorderSide(color: AppColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () {
                 _onUserTouch();
                 _selectLanguage(lang);
              },
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Text(
                  lang.flag,
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(
                  lang.nativeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * ts,
                    color: _selectedLanguage.code == lang.code ? AppColors.primary : textColor,
                  ),
                ),
                subtitle: Text(lang.name),
                trailing: _selectedLanguage.code == lang.code 
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
              ),
            ),
          ),

        SizedBox(height: 16 * ts),
        Text(
          _T(
            'Ou dites simplement le nom de la langue',
            'Or just say the language name',
            'أو قل اسم اللغة ببساطة',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // _buildLanguageButton is processed inline above now for better context
  Widget _buildLanguageButton(AppLanguage lang, bool useHighContrast, Color textColor, double ts) {
    return const SizedBox.shrink(); // Deprecated
  }Widget _buildVisionStep(bool useHighContrast, Color textColor, double ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.visibility,
          size: 60 * ts.clamp(1.0, 1.3),
          color: useHighContrast ? Colors.white : AppColors.primary,
        ),
        SizedBox(height: 16 * ts),
        Text(
          _T('👁️ Vision', '👁️ Vision', '👁️ الرؤية'),
          style: TextStyle(
            fontSize: 28 * ts,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 24 * ts),

        _buildOption(
          title: _T('Je vois bien', 'I see well', 'أرى جيدًا'),
          subtitle: _T('Mode standard', 'Standard mode', 'الوضع العادي'),
          voiceHint: _T('Dites "normal"', 'Say "normal"', 'قل "عادي"'),
          isSelected: _visualNeeds == 'normal',
          onTap: () => _selectVisual('normal'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        SizedBox(height: 12 * ts),
        
        _buildOption(
          title: _T('Texte plus grand', 'Larger text', 'نص أكبر'),
          subtitle: _T('Texte agrandi + contraste', 'Enlarged + contrast', 'مكبّر + تباين'),
          voiceHint: _T('Dites "agrandi"', 'Say "larger"', 'قل "أكبر"'),
          isSelected: _visualNeeds == 'low_vision',
          onTap: () => _selectVisual('low_vision'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        SizedBox(height: 12 * ts),
        
        _buildOption(
          title: _T('Je suis aveugle', 'I am blind', 'أنا كفيف'),
          subtitle: _T('Tout sera lu à voix haute', 'Everything read aloud', 'كل شيء يُقرأ بصوت عالٍ'),
          voiceHint: _T('Dites "aveugle"', 'Say "blind"', 'قل "كفيف"'),
          isSelected: _visualNeeds == 'blind',
          onTap: () => _selectVisual('blind'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),

        if (_visualNeeds != 'blind') ...[
          SizedBox(height: 32 * ts),
          Text(
            _T('Taille du texte', 'Text size', 'حجم النص'),
            style: TextStyle(
              fontSize: 18 * ts,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 14, color: textColor)),
              Expanded(
                child: Slider(
                  value: _textScale,
                  min: 1.0,
                  max: 2.0,
                  divisions: 5,
                  label: '${(_textScale * 100).round()}%',
                  onChanged: (value) {
                    setState(() => _textScale = value);
                    _accessibility.setTextScale(value);
                  },
                ),
              ),
              Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          // Preview
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * ts.clamp(1.0, 1.2)),
            decoration: BoxDecoration(
              color: useHighContrast ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _T('Aperçu du texte', 'Text preview', 'معاينة النص'),
              style: TextStyle(
                fontSize: 16 * _textScale,
                fontWeight: _boldText ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHearingStep(bool useHighContrast, Color textColor, double ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.hearing,
          size: 60 * ts.clamp(1.0, 1.3),
          color: useHighContrast ? Colors.white : AppColors.primary,
        ),
        SizedBox(height: 16 * ts),
        Text(
          '👂 ${_T('Audition', 'Hearing', 'السمع')}',
          style: TextStyle(
            fontSize: 28 * ts,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 24 * ts),

        _buildOption(
          title: _T("J'entends bien", 'I hear well', 'أسمع جيدًا'),
          subtitle: _T('Notifications sonores', 'Sound notifications', 'إشعارات صوتية'),
          voiceHint: _T('Dites "entends"', 'Say "hear"', 'قل "أسمع"'),
          isSelected: _audioNeeds == 'normal',
          onTap: () => _selectAudio('normal'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        SizedBox(height: 12 * ts),
        
        _buildOption(
          title: _T('Vibrations renforcées', 'Enhanced vibrations', 'اهتزازات معززة'),
          subtitle: _T('Vibrations fortes', 'Strong vibrations', 'اهتزازات قوية'),
          voiceHint: _T('Dites "vibration"', 'Say "vibration"', 'قل "اهتزاز"'),
          isSelected: _audioNeeds == 'hearing_loss',
          onTap: () => _selectAudio('hearing_loss'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        SizedBox(height: 12 * ts),
        
        _buildOption(
          title: _T('Je suis sourd', 'I am deaf', 'أنا أصم'),
          subtitle: _T('Notifications visuelles', 'Visual notifications', 'إشعارات مرئية'),
          voiceHint: _T('Dites "sourd"', 'Say "deaf"', 'قل "أصم"'),
          isSelected: _audioNeeds == 'deaf',
          onTap: () => _selectAudio('deaf'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
      ],
    );
  }

  Widget _buildMotorStep(bool useHighContrast, Color textColor, double ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.touch_app,
          size: 60 * ts.clamp(1.0, 1.3),
          color: useHighContrast ? Colors.white : AppColors.primary,
        ),
        SizedBox(height: 16 * ts),
        Text(
          '✋ ${_T('Interaction', 'Interaction', 'التفاعل')}',
          style: TextStyle(
            fontSize: 28 * ts,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 24 * ts),

        _buildOption(
          title: _T('Oui, sans problème', 'Yes, no problem', 'نعم، بدون مشكلة'),
          subtitle: _T('Écran tactile standard', 'Standard touch', 'لمس عادي'),
          voiceHint: _T('Dites "normal"', 'Say "normal"', 'قل "عادي"'),
          isSelected: _motorNeeds == 'normal',
          onTap: () => _selectMotor('normal'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        SizedBox(height: 12 * ts),
        
        _buildOption(
          title: _T('Difficultés motrices', 'Motor difficulties', 'صعوبات حركية'),
          subtitle: _T('Commandes vocales activées', 'Voice commands enabled', 'أوامر صوتية مفعّلة'),
          voiceHint: _T('Dites "vocale"', 'Say "voice"', 'قل "صوت"'),
          isSelected: _motorNeeds == 'limited_dexterity',
          onTap: () => _selectMotor('limited_dexterity'),
          useHighContrast: useHighContrast,
          textColor: textColor,
          ts: ts,
        ),
        
        if (_motorNeeds == 'limited_dexterity') ...[
          SizedBox(height: 24 * ts),
          Container(
            padding: EdgeInsets.all(16 * ts),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.green, size: 32),
                SizedBox(width: 12 * ts),
                Expanded(
                  child: Text(
                    _T(
                      '✅ Commandes vocales activées! Dites le nom du bouton.',
                      '✅ Voice commands enabled! Say the button name.',
                      '✅ الأوامر الصوتية مفعّلة! قل اسم الزر.',
                    ),
                    style: TextStyle(
                      fontSize: 14 * ts,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStep(bool useHighContrast, Color textColor, double ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 80 * ts.clamp(1.0, 1.3),
          color: Colors.green,
        ),
        SizedBox(height: 24 * ts),
        Text(
          '✅ ${_T('Configuration terminée!', 'Setup complete!', 'اكتمل الإعداد!')}',
          style: TextStyle(
            fontSize: 28 * ts,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32 * ts),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20 * ts.clamp(1.0, 1.2)),
          decoration: BoxDecoration(
            color: useHighContrast ? Colors.grey[900] : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: useHighContrast ? Colors.white : AppColors.primary,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              _buildSummaryRow('🌍 ${_T('Langue', 'Language', 'اللغة')}', _selectedLanguage.nativeName, textColor, ts),
              SizedBox(height: 12 * ts),
              _buildSummaryRow('👁️ ${_T('Vision', 'Vision', 'الرؤية')}', _getVisualSummary(), textColor, ts),
              SizedBox(height: 12 * ts),
              _buildSummaryRow('👂 ${_T('Audition', 'Hearing', 'السمع')}', _getAudioSummary(), textColor, ts),
              SizedBox(height: 12 * ts),
              _buildSummaryRow('✋ ${_T('Interaction', 'Interaction', 'التفاعل')}', _getMotorSummary(), textColor, ts),
            ],
          ),
        ),
        
        SizedBox(height: 24 * ts),
        Text(
          _T(
            'Dites "Commencer" pour continuer',
            'Say "Start" to continue',
            'قل "ابدأ" للمتابعة',
          ),
          style: TextStyle(
            fontSize: 16 * ts,
            fontStyle: FontStyle.italic,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color textColor, double ts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16 * ts,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16 * ts,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _T(String fr, String en, String ar) {
    switch (_selectedLanguage.code) {
      case 'en': return en;
      case 'ar': return ar;
      default: return fr;
    }
  }

  String _getVisualSummary() {
    switch (_visualNeeds) {
      case 'low_vision': return _T('Texte agrandi', 'Enlarged text', 'نص مكبّر');
      case 'blind': return _T('Lecture vocale', 'Voice reading', 'قراءة صوتية');
      default: return _T('Standard', 'Standard', 'عادي');
    }
  }

  String _getAudioSummary() {
    switch (_audioNeeds) {
      case 'hearing_loss': return _T('Vibrations', 'Vibrations', 'اهتزازات');
      case 'deaf': return _T('Mode visuel', 'Visual mode', 'وضع مرئي');
      default: return _T('Standard', 'Standard', 'عادي');
    }
  }

  String _getMotorSummary() {
    return _motorNeeds == 'limited_dexterity' 
      ? _T('Commandes vocales', 'Voice commands', 'أوامر صوتية')
      : _T('Standard', 'Standard', 'عادي');
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required String voiceHint,
    required bool isSelected,
    required VoidCallback onTap,
    required bool useHighContrast,
    required Color textColor,
    required double ts,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle. $voiceHint',
      child: InkWell(
        onTap: () {
          _onUserTouch(); // Disable voice mode when user touches
          _accessibility.vibrateTap();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20 * ts.clamp(1.0, 1.2)),
          decoration: BoxDecoration(
            color: isSelected 
              ? (useHighContrast ? Colors.blue.withOpacity(0.3) : AppColors.primary.withOpacity(0.15))
              : (useHighContrast ? Colors.grey[900] : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                ? (useHighContrast ? Colors.white : AppColors.primary)
                : (useHighContrast ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18 * ts,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                          ? (useHighContrast ? Colors.white : AppColors.primary)
                          : textColor,
                      ),
                    ),
                    SizedBox(height: 4 * ts),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14 * ts,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4 * ts),
                    Text(
                      voiceHint,
                      style: TextStyle(
                        fontSize: 12 * ts,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: useHighContrast ? Colors.white : AppColors.primary,
                  size: 28 * ts.clamp(1.0, 1.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
