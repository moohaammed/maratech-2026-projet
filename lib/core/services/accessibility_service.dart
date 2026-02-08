import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langues supportées
class AppLanguage {
  final String code;
  final String ttsCode;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.ttsCode,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const french = AppLanguage(
    code: 'fr',
    ttsCode: 'fr-FR',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
  );

  static const arabic = AppLanguage(
    code: 'ar',
    ttsCode: 'ar-SA',
    name: 'Arabic',
    nativeName: 'العربية',
    flag: '🇹🇳',
  );

  static const english = AppLanguage(
    code: 'en',
    ttsCode: 'en-US',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
  );

  static const List<AppLanguage> all = [french, arabic, english];
}

/// AccessibilityService - Écoute continue + Commandes vocales
class AccessibilityService extends ChangeNotifier {
  // TTS Engine
  final FlutterTts _tts = FlutterTts();
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;

  // Speech Recognition
  final SpeechToText _speech = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _continuousListeningEnabled = true; // ALWAYS ON
  String _lastWords = '';
  String _recognizedText = ''; // Real-time display

  // Device capabilities
  bool _hasVibrator = false;

  // Language
  AppLanguage _currentLanguage = AppLanguage.french;

  // User preferences
  bool _voiceGuidanceEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _voiceCommandsEnabled = true;
  double _speechRate = 0.45;
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _boldText = false;
  String _visualNeeds = 'normal';
  String _audioNeeds = 'normal';
  String _motorNeeds = 'normal';

  // Voice command callbacks
  final Map<String, VoidCallback> _voiceCommandCallbacks = {};
  DateTime? _lastCommandTime;
  
  // Callback for when speech is recognized (for UI updates)
  Function(String)? onSpeechRecognized;

  // Getters
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get voiceGuidanceEnabled => _voiceGuidanceEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get voiceCommandsEnabled => _voiceCommandsEnabled;
  bool get continuousListeningEnabled => _continuousListeningEnabled;
  String get lastWords => _lastWords;
  String get recognizedText => _recognizedText;
  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get boldText => _boldText;
  String get visualNeeds => _visualNeeds;
  String get audioNeeds => _audioNeeds;
  String get motorNeeds => _motorNeeds;
  AppLanguage get currentLanguage => _currentLanguage;

  /// Initialize all accessibility features
  Future<void> initialize() async {
    await _loadPreferences();
    await _initializeTts();
    await _initializeSpeech();
    await _checkVibrationCapability();
    
    debugPrint('♿ AccessibilityService initialized');
    debugPrint('   Language: ${_currentLanguage.nativeName}');
    debugPrint('   TTS: $_isTtsInitialized');
    debugPrint('   Speech: $_isSpeechAvailable');
    debugPrint('   Vibration: $_hasVibrator');
  }
  
  /// Sync service settings with an AccessibilityProfile
  /// Call this when profile changes to ensure consistency
  void syncWithProfile({
    required bool ttsEnabled,
    required bool vibrationEnabled, 
    required String audioNeeds,
    required String visualNeeds,
    required String motorNeeds,
    required String languageCode,
  }) {
    _voiceGuidanceEnabled = ttsEnabled && audioNeeds != 'deaf';
    _hapticFeedbackEnabled = vibrationEnabled;
    _audioNeeds = audioNeeds;
    _visualNeeds = visualNeeds;
    _motorNeeds = motorNeeds;
    
    // 🛑 RESTRICT VOICE COMMANDS: Based on Motor Needs
    // Force DISABLE voice commands if user has 'normal' motor skills (even if blind).
    // They should use Touch + TTS. Voice Input is reserved for motor difficulties.
    if (motorNeeds == 'normal') {
      _voiceCommandsEnabled = false;
      if (_isListening) {
        _speech.stop();
        _isListening = false;
      }
    } else {
      _voiceCommandsEnabled = true;
    }
    
    // Update language if changed
    final newLang = AppLanguage.all.firstWhere(
      (l) => l.code == languageCode,
      orElse: () => AppLanguage.french,
    );
    if (newLang.code != _currentLanguage.code) {
      setLanguage(newLang);
    }
    
    debugPrint('♿ Synced with profile:');
    debugPrint('   TTS: $_voiceGuidanceEnabled');
    debugPrint('   Voice Cmds: $_voiceCommandsEnabled');
    debugPrint('   Vibration: $_hapticFeedbackEnabled');
    debugPrint('   Language: ${_currentLanguage.nativeName}');
    
    notifyListeners();
  }
  
  /// Quick method to set TTS enabled/disabled
  void setTtsEnabled(bool enabled) {
    _voiceGuidanceEnabled = enabled;
    if (!enabled) {
      stopSpeaking();
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // LANGUAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    
    // Apply optimized TTS settings for this language
    await _applyTtsLanguageSettings(language.ttsCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', language.code);
    
    debugPrint('🌐 Language changed to: ${language.nativeName}');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT-TO-SPEECH (Enhanced with Google TTS preference)
  // ═══════════════════════════════════════════════════════════

  /// Language-specific TTS presets for optimal quality
  static const Map<String, Map<String, dynamic>> _ttsPresets = {
    'fr-FR': {'speechRate': 0.45, 'pitch': 1.0, 'preferredEngine': 'google'},
    'ar-SA': {'speechRate': 0.40, 'pitch': 1.0, 'preferredEngine': 'google'}, // Slower for Arabic clarity
    'en-US': {'speechRate': 0.50, 'pitch': 1.0, 'preferredEngine': 'google'},
  };

  Future<void> _initializeTts() async {
    try {
      // Try to use Google TTS engine for higher quality
      await _selectBestTtsEngine();
      
      // Apply language-specific settings
      await _applyTtsLanguageSettings(_currentLanguage.ttsCode);

      _tts.setStartHandler(() async {
        _isSpeaking = true;
        // Stop listening while speaking to avoid self-detection
        if (_isListening) {
          await _speech.stop();
          _isListening = false;
        }
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        // Ensure listening is active immediately
        if (_continuousListeningEnabled && _voiceCommandsEnabled && !_isListening) {
           startContinuousListening();
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('📢 TTS Error: $msg');
        _isSpeaking = false;
        notifyListeners();
      });

      _isTtsInitialized = true;
      debugPrint('📢 TTS initialized for ${_currentLanguage.ttsCode}');
    } catch (e) {
      debugPrint('📢 TTS initialization failed: $e');
      _isTtsInitialized = false;
    }
  }
  
  /// Select the best available TTS engine (prefer Google)
  Future<void> _selectBestTtsEngine() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.isNotEmpty) {
        debugPrint('📢 Available TTS engines: $engines');
        
        // Prefer Google TTS for higher quality
        final googleEngine = engines.firstWhere(
          (e) => e.toString().toLowerCase().contains('google'),
          orElse: () => null,
        );
        
        if (googleEngine != null) {
          await _tts.setEngine(googleEngine.toString());
          debugPrint('📢 Using Google TTS engine');
        }
      }
    } catch (e) {
      debugPrint('📢 Engine selection failed: $e');
    }
  }
  
  /// Apply optimized TTS settings for a specific language
  Future<void> _applyTtsLanguageSettings(String ttsCode) async {
    final preset = _ttsPresets[ttsCode] ?? _ttsPresets['fr-FR']!;
    
    await _tts.setLanguage(ttsCode);
    await _tts.setSpeechRate(preset['speechRate'] as double);
    await _tts.setPitch(preset['pitch'] as double);
    await _tts.setVolume(1.0);
    
    // Try to select the best voice for this language
    await _selectBestVoice(ttsCode);
  }
  
  /// Select the highest quality voice for the language
  Future<void> _selectBestVoice(String ttsCode) async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices is! List) return;
      
      // Filter voices for current language
      final langCode = ttsCode.split('-')[0];
      final langVoices = voices.where((v) {
        final locale = (v as Map)['locale']?.toString() ?? '';
        return locale.toLowerCase().startsWith(langCode);
      }).toList();
      
      if (langVoices.isEmpty) return;
      
      // Prefer network/premium voices
      final bestVoice = langVoices.firstWhere(
        (v) {
          final name = (v as Map)['name']?.toString().toLowerCase() ?? '';
          return name.contains('network') || 
                 name.contains('premium') ||
                 name.contains('enhanced');
        },
        orElse: () => langVoices.first,
      );
      
      if (bestVoice != null) {
        await _tts.setVoice({
          'name': (bestVoice as Map)['name'],
          'locale': ttsCode,
        });
        debugPrint('📢 Selected voice: ${bestVoice['name']}');
      }
    } catch (e) {
      debugPrint('📢 Voice selection failed: $e');
    }
  }

  /// Speak text with optional interruption and text normalization
  Future<void> speak(String message, {bool interrupt = true}) async {
    if (!_voiceGuidanceEnabled || !_isTtsInitialized) return;
    if (_audioNeeds == 'deaf') return; // Don't speak to deaf users
    
    if (interrupt && _isSpeaking) {
      await _tts.stop();
    }
    
    // Normalize text for better pronunciation
    final normalizedMessage = _normalizeTextForTts(message);
    
    await _tts.speak(normalizedMessage);
  }
  
  /// Normalize text for better TTS pronunciation
  String _normalizeTextForTts(String text) {
    var normalized = text;
    
    // Fix common abbreviations
    normalized = normalized.replaceAll(RegExp(r'\bRCT\b'), 'R C T');
    normalized = normalized.replaceAll(RegExp(r'\bKM\b', caseSensitive: false), 'kilomètres');
    normalized = normalized.replaceAll(RegExp(r'\bkm/h\b', caseSensitive: false), 'kilomètres par heure');
    normalized = normalized.replaceAll(RegExp(r'\bmin\b'), 'minutes');
    normalized = normalized.replaceAll(RegExp(r'\bh\b'), 'heures');
    
    // Add natural pauses at sentence boundaries
    if (_currentLanguage.code != 'ar') {
      // Don't add pauses for Arabic as it reads correctly
      normalized = normalized.replaceAll('. ', '. ... ');
      normalized = normalized.replaceAll('! ', '! ... ');
      normalized = normalized.replaceAll('? ', '? ... ');
    }
    
    return normalized;
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> speakWithHaptic(String message) async {
    await vibrateTap();
    await speak(message);
  }

  Future<void> waitForSpeechComplete() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CONTINUOUS SPEECH RECOGNITION
  // ═══════════════════════════════════════════════════════════

  Future<void> _initializeSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
            
            // RESTART listening if continuous mode enabled
            if (_continuousListeningEnabled && 
                _voiceCommandsEnabled) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!_isListening) startContinuousListening();
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _isListening = false;
          notifyListeners();
          
          // Restart on error too
          if (_continuousListeningEnabled && 
              _voiceCommandsEnabled) {
            Future.delayed(const Duration(seconds: 2), () { // Longer delay on error
              if (!_isListening) startContinuousListening();
            });
          }
        },
      );
      debugPrint('Speech available: $_isSpeechAvailable');
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      _isSpeechAvailable = false;
    }
  }

  /// Register a voice command
  void registerVoiceCommand(String command, VoidCallback callback) {
    _voiceCommandCallbacks[command.toLowerCase()] = callback;
    debugPrint('Registered command: $command');
  }

  void clearVoiceCommands() {
    _voiceCommandCallbacks.clear();
  }

  Future<void> startContinuousListening() async {
    if (!_isSpeechAvailable || _isListening || _isSpeaking) return;
    if (!_voiceCommandsEnabled) return;

    _isListening = true;
    _recognizedText = '';
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _lastWords = result.recognizedWords.toLowerCase();
          
          // Update UI in real-time
          onSpeechRecognized?.call(_recognizedText);
          notifyListeners();
          
          debugPrint('Heard: $_lastWords');

          // FAST TRIGGER: Execute on partial results too!
          // The debounce in _executeVoiceCommand will prevent double-firing.
          if (_lastWords.isNotEmpty) {
            _executeVoiceCommand(_lastWords);
          }
          
          if (result.finalResult) {
             // Logic if needed for final cleanup, currently handled by execute logic
          }
        },
        listenFor: const Duration(seconds: 30), // Listen longer
        pauseFor: const Duration(seconds: 3), // Wait 3s for more speech
        localeId: _currentLanguage.ttsCode,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop continuous listening
  Future<void> stopContinuousListening() async {
    _continuousListeningEnabled = false;
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Enable/disable continuous listening
  void setContinuousListening(bool enabled) {
    _continuousListeningEnabled = enabled;
    if (enabled && !_isListening && !_isSpeaking) {
      startContinuousListening();
    } else if (!enabled) {
      stopContinuousListening();
    }
    notifyListeners();
  }

  /// Word corrections for common misrecognitions by language
  static const Map<String, Map<String, String>> _wordCorrections = {
    'fr': {
      'continu': 'continuer',
      'francais': 'français',
      'france': 'français',
      'ouis': 'oui',
      'nong': 'non',
      'arab': 'arabe',
      'anglai': 'anglais',
      'suivent': 'suivant',
      'retours': 'retour',
      'termine': 'terminer',
      'fini': 'terminer',
      'commense': 'commencer',
      'avugle': 'aveugle',
      'vibrations': 'vibration',
      'vocale': 'vocal',
      'fransi': 'français',
    },
    'en': {
      'continew': 'continue',
      'nex': 'next',
      'bak': 'back',
      'stert': 'start',
      'yess': 'yes',
      'noo': 'no',
      'frensh': 'french',
      'arebic': 'arabic',
      'inglish': 'english',
      'blinde': 'blind',
      'deff': 'deaf',
    },
    'ar': {
      'متابعه': 'متابعة',
      'نعمم': 'نعم',
      'لاا': 'لا',
    },
  };

  /// Apply word corrections based on current language
  String _applyWordCorrections(String text) {
    final langCode = _currentLanguage.code;
    final corrections = _wordCorrections[langCode] ?? {};
    
    var corrected = text;
    for (final entry in corrections.entries) {
      corrected = corrected.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }
    
    return corrected;
  }

  /// Execute voice command - ACTUALLY CLICK THE BUTTON
  void _executeVoiceCommand(String words) {
    // Debounce to prevent multiple executions for same phrase
    if (_lastCommandTime != null && 
        DateTime.now().difference(_lastCommandTime!) < const Duration(milliseconds: 1000)) {
       return;
    }
    _lastCommandTime = DateTime.now();

    // Apply word corrections for better accuracy
    final correctedWords = _applyWordCorrections(words);
    
    debugPrint('🎤 Trying to execute command from: "$words"');
    if (correctedWords != words) {
      debugPrint('🎤 Corrected to: "$correctedWords"');
    }
    
    // Check each registered command
    for (final entry in _voiceCommandCallbacks.entries) {
      if (correctedWords.contains(entry.key)) {
        debugPrint('✅ EXECUTING: ${entry.key}');
        
        // Interrupt immediately!
        stopSpeaking();
        vibrateSuccess();
        
        // Execute the callback!
        entry.value();
        
        // Removed generic speak() to avoid conflicts with callback feedback
        return;
      }
    }
    
    // Check for common words in all languages (also check corrected words)
    if (_checkYes(correctedWords)) {
      _voiceCommandCallbacks['oui']?.call();
      _voiceCommandCallbacks['yes']?.call();
      _voiceCommandCallbacks['نعم']?.call();
    } else if (_checkNo(correctedWords)) {
      _voiceCommandCallbacks['non']?.call();
      _voiceCommandCallbacks['no']?.call();
      _voiceCommandCallbacks['لا']?.call();
    } else if (_checkContinue(correctedWords)) {
      _voiceCommandCallbacks['continuer']?.call();
      _voiceCommandCallbacks['continue']?.call();
      _voiceCommandCallbacks['متابعة']?.call();
      _voiceCommandCallbacks['متابعه']?.call();
    }
  }

  bool _checkYes(String words) {
    return words.contains('oui') || 
           words.contains('yes') || 
           words.contains('نعم') ||
           words.contains('ouais');
  }

  bool _checkNo(String words) {
    return words.contains('non') || 
           words.contains('no') || 
           words.contains('لا');
  }

  bool _checkContinue(String words) {
    return words.contains('continuer') || 
           words.contains('suivant') ||
           words.contains('continue') ||
           words.contains('next') ||
           words.contains('متابعة') ||
           words.contains('متابعه');
  }

  /// Get a localized confirmation message for a command
  String getConfirmationMessage(String command) {
    switch (_currentLanguage.code) {
      case 'ar':
        return '$command تم اختياره';
      case 'en':
        return '$command selected';
      default:
        return '$command sélectionné';
    }
  }
  
  /// Speak a confirmation message for a recognized command
  Future<void> speakConfirmation(String command) async {
    final message = getConfirmationMessage(command);
    await speakWithHaptic(message);
  }

  /// Listen for yes/no response
  Future<bool?> listenForYesNo() async {
    if (!_isSpeechAvailable) return null;

    await stopSpeaking();
    await vibrateTap();
    
    bool? result;
    
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (speechResult) {
        final words = speechResult.recognizedWords.toLowerCase();
        _recognizedText = speechResult.recognizedWords;
        onSpeechRecognized?.call(_recognizedText);
        notifyListeners();
        
        debugPrint('Yes/No heard: $words');
        
        if (speechResult.finalResult) {
          if (_checkYes(words)) {
            result = true;
            vibrateSuccess();
          } else if (_checkNo(words)) {
            result = false;
            vibrateSuccess();
          }
          _isListening = false;
          notifyListeners();
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: _currentLanguage.ttsCode,
    );

    // Wait for result
    int waited = 0;
    while (_isListening && waited < 11000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // HAPTIC FEEDBACK
  // ═══════════════════════════════════════════════════════════

  Future<void> _checkVibrationCapability() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
    } catch (e) {
      _hasVibrator = false;
    }
  }

  Future<void> vibrateTap() async {
    if (!_hapticFeedbackEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 50);
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> vibrateSuccess() async {
    if (!_hapticFeedbackEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(pattern: [0, 100, 100, 100]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> vibrateError() async {
    if (!_hapticFeedbackEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 500);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PREFERENCES
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceGuidanceEnabled = prefs.getBool('voiceGuidance') ?? true;
    _hapticFeedbackEnabled = prefs.getBool('hapticFeedback') ?? true;
    _voiceCommandsEnabled = prefs.getBool('voiceCommands') ?? true;
    _continuousListeningEnabled = prefs.getBool('continuousListening') ?? true;
    _speechRate = prefs.getDouble('speechRate') ?? 0.45;
    _textScale = prefs.getDouble('textScale') ?? 1.0;
    _highContrast = prefs.getBool('highContrast') ?? false;
    _boldText = prefs.getBool('boldText') ?? false;
    _visualNeeds = prefs.getString('visualNeeds') ?? 'normal';
    _audioNeeds = prefs.getString('audioNeeds') ?? 'normal';
    _motorNeeds = prefs.getString('motorNeeds') ?? 'normal';
    
    // Load language
    final langCode = prefs.getString('languageCode') ?? 'fr';
    _currentLanguage = AppLanguage.all.firstWhere(
      (l) => l.code == langCode,
      orElse: () => AppLanguage.french,
    );
    
    notifyListeners();
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voiceGuidance', _voiceGuidanceEnabled);
    await prefs.setBool('hapticFeedback', _hapticFeedbackEnabled);
    await prefs.setBool('voiceCommands', _voiceCommandsEnabled);
    await prefs.setBool('continuousListening', _continuousListeningEnabled);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setDouble('textScale', _textScale);
    await prefs.setBool('highContrast', _highContrast);
    await prefs.setBool('boldText', _boldText);
    await prefs.setString('visualNeeds', _visualNeeds);
    await prefs.setString('audioNeeds', _audioNeeds);
    await prefs.setString('motorNeeds', _motorNeeds);
    await prefs.setString('languageCode', _currentLanguage.code);
  }

  // Setters
  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    await savePreferences();
  }

  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    notifyListeners();
    await savePreferences();
  }

  Future<void> setBoldText(bool enabled) async {
    _boldText = enabled;
    notifyListeners();
    await savePreferences();
  }

  Future<void> setVisualNeeds(String needs) async {
    _visualNeeds = needs;
    
    // RESET first
    _textScale = 1.0;
    _highContrast = false;
    _boldText = false;
    // Don't reset voice guidance here, managed separately or by blind check below
    
    if (needs == 'low_vision') {
      _textScale = 1.5;
      _highContrast = true;
      _boldText = true;
    } else if (needs == 'blind') {
      _voiceGuidanceEnabled = true;
      _voiceCommandsEnabled = true;
      _continuousListeningEnabled = true;
      // Also enable visual aids for partially sighted users who identify as blind
      _textScale = 1.5;
      _highContrast = true;
      _boldText = true;
    }
    notifyListeners();
    await savePreferences();
  }

  Future<void> setAudioNeeds(String needs) async {
    _audioNeeds = needs;
    
    if (needs == 'deaf') {
      _voiceGuidanceEnabled = false;
    } else {
        // Re-enable if returning to normal/hearing
        _voiceGuidanceEnabled = true;
    }
    
    notifyListeners();
    await savePreferences();
  }

  Future<void> setMotorNeeds(String needs) async {
    _motorNeeds = needs;
    
    if (needs == 'limited_dexterity') {
      _voiceCommandsEnabled = true;
      _continuousListeningEnabled = true;
    } else {
        // Option: Disable voice commands if going back to normal?
        // Or keep them enabled if user wants?
        // For Wizard purposes, we likely want to revert to default (false) unless user manually toggled.
        // But let's be safe and only enable for limited.
        // User can manually toggle later in settings.
        // Actually, let's leave it as is, or reset?
        // Let's reset to match "Back to Normal" behavior.
        _voiceCommandsEnabled = false;
        _continuousListeningEnabled = false;
    }
    
    notifyListeners();
    await savePreferences();
  }

  Future<void> setVoiceCommands(bool enabled) async {
    _voiceCommandsEnabled = enabled;
    if (enabled) {
      _continuousListeningEnabled = true;
      startContinuousListening();
    } else {
      stopContinuousListening();
    }
    notifyListeners();
    await savePreferences();
  }

  // ═══════════════════════════════════════════════════════════
  // EXPORT PROFILE
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic> getProfileJson() {
    return {
      'languageCode': _currentLanguage.code,
      'isProfileComplete': true,
      'completedAt': DateTime.now().toIso8601String(), // Will be converted to Timestamp by Firestore
      'lastUpdated': DateTime.now().toIso8601String(),
      
      'visual': {
        'needsCategory': _visualNeeds,
        'textSize': (_textScale * 100).round(),
        'fontWeight': _boldText ? 'bold' : 'normal',
        'lineHeight': 1.5,
        'letterSpacing': 0.0,
        'contrastMode': _highContrast ? 'high_contrast' : 'standard',
        'colorblindType': null,
        'reduceTransparency': _highContrast,
        'boldText': _boldText,
        'largerIcons': _textScale > 1.2,
        'screenReaderEnabled': _visualNeeds == 'blind', // Auto-enable for blind
      },
      
      'audio': {
        'needsCategory': _audioNeeds,
        'notificationStyle': _audioNeeds == 'deaf' ? 'visual' : 'sound_visual',
        'vibrationEnabled': _hapticFeedbackEnabled,
        'vibrationStrength': 'medium',
        'showCaptions': _audioNeeds == 'deaf' || _audioNeeds == 'hearing_loss',
        'transcribeAudio': _audioNeeds == 'deaf',
      },
      
      'motor': {
        'needsCategory': _motorNeeds,
        'buttonSize': _textScale > 1.2 ? 'large' : 'standard',
        'touchHoldDuration': 500,
        'simplifiedGestures': _motorNeeds == 'limited_dexterity',
        'voiceControlEnabled': _voiceCommandsEnabled,
      },
      
      'cognitive': {
        'reduceMotion': false,
        'simpleLanguage': false,
        'focusHighlight': 'standard',
      },
      
      'theme': {
        'mode': 'system',
        'customColors': null,
      },
      
      'version': 1,
    };
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
