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

  // ═══════════════════════════════════════════════════════════
  // LANGUAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    await _tts.setLanguage(language.ttsCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', language.code);
    
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT-TO-SPEECH
  // ═══════════════════════════════════════════════════════════

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage(_currentLanguage.ttsCode);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        // Stop listening while speaking
        if (_isListening) {
          _speech.stop();
          _isListening = false;
        }
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        // Resume continuous listening after speaking
        if (_continuousListeningEnabled && _voiceCommandsEnabled) {
          Future.delayed(const Duration(milliseconds: 300), () {
            startContinuousListening();
          });
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        notifyListeners();
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
      _isTtsInitialized = false;
    }
  }

  Future<void> speak(String message, {bool interrupt = true}) async {
    if (!_voiceGuidanceEnabled || !_isTtsInitialized) return;
    if (_audioNeeds == 'deaf') return; // Don't speak to deaf users
    
    if (interrupt && _isSpeaking) {
      await _tts.stop();
    }
    
    await _tts.speak(message);
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
                _voiceCommandsEnabled && 
                !_isSpeaking) {
              Future.delayed(const Duration(milliseconds: 500), () {
                startContinuousListening();
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
              _voiceCommandsEnabled && 
              !_isSpeaking) {
            Future.delayed(const Duration(seconds: 1), () {
              startContinuousListening();
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

  /// Start CONTINUOUS listening - always on!
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

          if (result.finalResult && _lastWords.isNotEmpty) {
            _executeVoiceCommand(_lastWords);
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

  /// Execute voice command - ACTUALLY CLICK THE BUTTON
  void _executeVoiceCommand(String words) {
    debugPrint('Trying to execute command from: "$words"');
    
    // Check each registered command
    for (final entry in _voiceCommandCallbacks.entries) {
      if (words.contains(entry.key)) {
        debugPrint('✅ EXECUTING: ${entry.key}');
        vibrateSuccess();
        
        // Execute the callback!
        entry.value();
        
        // Announce what was selected
        speak(_getConfirmationMessage(entry.key));
        return;
      }
    }
    
    // Check for common words in all languages
    if (_checkYes(words)) {
      _voiceCommandCallbacks['oui']?.call();
      _voiceCommandCallbacks['yes']?.call();
      _voiceCommandCallbacks['نعم']?.call();
    } else if (_checkNo(words)) {
      _voiceCommandCallbacks['non']?.call();
      _voiceCommandCallbacks['no']?.call();
      _voiceCommandCallbacks['لا']?.call();
    } else if (_checkContinue(words)) {
      _voiceCommandCallbacks['continuer']?.call();
      _voiceCommandCallbacks['continue']?.call();
      _voiceCommandCallbacks['متابعة']?.call();
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
           words.contains('متابعة');
  }

  String _getConfirmationMessage(String command) {
    switch (_currentLanguage.code) {
      case 'ar':
        return '$command تم اختياره';
      case 'en':
        return '$command selected';
      default:
        return '$command sélectionné';
    }
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
    if (needs == 'low_vision') {
      _textScale = 1.5;
      _highContrast = true;
      _boldText = true;
    } else if (needs == 'blind') {
      _voiceGuidanceEnabled = true;
      _voiceCommandsEnabled = true;
      _continuousListeningEnabled = true;
    }
    notifyListeners();
    await savePreferences();
  }

  Future<void> setAudioNeeds(String needs) async {
    _audioNeeds = needs;
    if (needs == 'deaf') {
      _voiceGuidanceEnabled = false;
    }
    notifyListeners();
    await savePreferences();
  }

  Future<void> setMotorNeeds(String needs) async {
    _motorNeeds = needs;
    if (needs == 'limited_dexterity') {
      _voiceCommandsEnabled = true;
      _continuousListeningEnabled = true;
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

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
