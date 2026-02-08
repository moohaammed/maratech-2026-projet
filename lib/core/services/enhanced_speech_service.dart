import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Enhanced Speech Recognition Service with word correction and improved accuracy
/// 
/// Features:
/// - Fuzzy matching for voice commands
/// - Auto word correction
/// - Confidence thresholds
/// - Multi-language support with phonetic matching
/// - Continuous listening with smart restart
class EnhancedSpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Current settings
  String _currentLocale = 'fr-FR';
  double _confidenceThreshold = 0.5;
  
  // Recognition state
  String _recognizedWords = '';
  String _lastFinalResult = '';
  double _lastConfidence = 0.0;
  
  // Command mapping with phonetic variations
  final Map<String, CommandMapping> _commands = {};
  
  // Continuous listening
  bool _continuousMode = false;
  final int _restartDelayMs = 500;
  final int _maxRestartAttempts = 3;
  int _restartAttempts = 0;
  
  // Callbacks
  Function(String, double)? onResult;
  Function(String)? onFinalResult;
  Function(String)? onPartialResult;
  Function(String)? onCommandRecognized;
  VoidCallback? onListeningStart;
  VoidCallback? onListeningStop;
  Function(String)? onError;
  
  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedWords => _recognizedWords;
  String get lastFinalResult => _lastFinalResult;
  double get lastConfidence => _lastConfidence;
  
  /// Common word corrections per language
  static const Map<String, Map<String, String>> _corrections = {
    'fr': {
      // French phonetic corrections
      'continu': 'continuer',
      'continue': 'continuer',
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
    },
    'en': {
      // English phonetic corrections
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
      // Arabic phonetic corrections
      'متابعه': 'متابعة',
      'نعمم': 'نعم',
      'لاا': 'لا',
    },
  };
  
  /// Phonetic variations for command matching
  static const Map<String, List<String>> _phoneticVariations = {
    // Navigation
    'continuer': ['continue', 'continew', 'كونتينيو', 'متابعة', 'متابعه', 'next', 'suivant'],
    'retour': ['back', 'رجوع', 'ريتور', 'previous'],
    'oui': ['yes', 'ouais', 'نعم', 'yeah', 'yep', 'ok', 'okay'],
    'non': ['no', 'nope', 'لا', 'nan'],
    'terminer': ['finish', 'done', 'انتهى', 'termine', 'fini', 'complete'],
    'commencer': ['start', 'begin', 'ابدأ', 'commence', 'go'],
    
    // Languages
    'français': ['french', 'francais', 'france', 'فرنسي', 'fransi', 'فرانسي'],
    'arabe': ['arabic', 'عربي', 'عربية', 'العربية', 'arabi', 'arabique'],
    'anglais': ['english', 'انجليزي', 'inglish', 'anglish'],
    
    // Accessibility options
    'aveugle': ['blind', 'اعمى', 'أعمى', 'aveug'],
    'sourd': ['deaf', 'اصم', 'أصم', 'sour'],
    'normal': ['standard', 'عادي', 'normall', 'bien'],
  };
  
  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: true,
      );
      
      if (_isInitialized) {
        // Get available locales
        final locales = await _speech.locales();
        debugPrint('🎤 Available locales: ${locales.length}');
        for (final locale in locales) {
          debugPrint('   - ${locale.localeId}: ${locale.name}');
        }
      }
      
      debugPrint('🎤 EnhancedSpeechService initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('🎤 Speech initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Set the recognition language
  Future<void> setLocale(String localeId) async {
    _currentLocale = localeId;
    debugPrint('🎤 Set locale: $localeId');
  }
  
  /// Register a voice command with optional variations
  void registerCommand(String command, VoidCallback callback, {
    List<String>? variations,
    double? minConfidence,
  }) {
    final normalizedCommand = command.toLowerCase().trim();
    
    // Build list of all variations
    final allVariations = <String>{normalizedCommand};
    
    // Add provided variations
    if (variations != null) {
      allVariations.addAll(variations.map((v) => v.toLowerCase().trim()));
    }
    
    // Add known phonetic variations
    for (final entry in _phoneticVariations.entries) {
      if (entry.value.contains(normalizedCommand) || entry.key == normalizedCommand) {
        allVariations.add(entry.key);
        allVariations.addAll(entry.value);
      }
    }
    
    _commands[normalizedCommand] = CommandMapping(
      primaryCommand: normalizedCommand,
      variations: allVariations.toList(),
      callback: callback,
      minConfidence: minConfidence ?? _confidenceThreshold,
    );
    
    debugPrint('🎤 Registered command: $normalizedCommand with ${allVariations.length} variations');
  }
  
  /// Clear all registered commands
  void clearCommands() {
    _commands.clear();
    debugPrint('🎤 Cleared all commands');
  }
  
  /// Start listening for speech
  Future<void> startListening({
    bool continuous = false,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized || _isListening) return;
    
    _continuousMode = continuous;
    _isListening = true;
    _recognizedWords = '';
    _restartAttempts = 0;
    
    onListeningStart?.call();
    
    try {
      await _speech.listen(
        onResult: _handleResult,
        localeId: _currentLocale,
        listenMode: ListenMode.dictation,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
      );
      
      debugPrint('🎤 Started listening (continuous: $continuous)');
    } catch (e) {
      debugPrint('🎤 Listen error: $e');
      _isListening = false;
      onError?.call(e.toString());
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    _continuousMode = false;
    await _speech.stop();
    _isListening = false;
    onListeningStop?.call();
    debugPrint('🎤 Stopped listening');
  }
  
  /// Handle speech recognition results
  void _handleResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase().trim();
    final confidence = result.hasConfidenceRating ? result.confidence : 1.0;
    
    _recognizedWords = result.recognizedWords;
    _lastConfidence = confidence;
    
    debugPrint('🎤 Heard: "$words" (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
    
    // Emit callbacks
    onResult?.call(result.recognizedWords, confidence);
    
    if (result.finalResult) {
      onFinalResult?.call(result.recognizedWords);
      _lastFinalResult = words;
    } else {
      onPartialResult?.call(result.recognizedWords);
    }
    
    // Apply corrections
    final correctedWords = _applyCorrections(words);
    
    // Check for command matches
    _checkForCommands(correctedWords, confidence, result.finalResult);
  }
  
  /// Apply word corrections based on language
  String _applyCorrections(String text) {
    final langCode = _currentLocale.split('-')[0];
    final corrections = _corrections[langCode] ?? {};
    
    var corrected = text;
    
    for (final entry in corrections.entries) {
      corrected = corrected.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }
    
    return corrected;
  }
  
  /// Check if recognized words match any registered commands
  void _checkForCommands(String words, double confidence, bool isFinal) {
    for (final mapping in _commands.values) {
      // Skip if confidence is too low
      if (confidence < mapping.minConfidence) continue;
      
      // Check exact match first
      if (words.contains(mapping.primaryCommand)) {
        _executeCommand(mapping, words);
        return;
      }
      
      // Check variations
      for (final variation in mapping.variations) {
        if (words.contains(variation)) {
          _executeCommand(mapping, words);
          return;
        }
      }
      
      // Fuzzy match for final results only
      if (isFinal && _fuzzyMatch(words, mapping.primaryCommand)) {
        _executeCommand(mapping, words);
        return;
      }
    }
  }
  
  /// Execute a matched command
  void _executeCommand(CommandMapping mapping, String recognizedWords) {
    debugPrint('🎤 ✅ Command matched: ${mapping.primaryCommand}');
    onCommandRecognized?.call(mapping.primaryCommand);
    mapping.callback();
  }
  
  /// Simple fuzzy matching for approximate command recognition
  bool _fuzzyMatch(String input, String target) {
    // Levenshtein distance threshold
    final maxDistance = (target.length * 0.3).ceil();
    final distance = _levenshteinDistance(input, target);
    return distance <= maxDistance;
  }
  
  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  /// Handle status changes
  void _handleStatus(String status) {
    debugPrint('🎤 Status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningStop?.call();
      
      // Restart if continuous mode is enabled
      if (_continuousMode && _restartAttempts < _maxRestartAttempts) {
        _restartAttempts++;
        Future.delayed(Duration(milliseconds: _restartDelayMs), () {
          if (_continuousMode) {
            startListening(continuous: true);
          }
        });
      }
    }
  }
  
  /// Handle errors
  void _handleError(SpeechRecognitionError error) {
    debugPrint('🎤 Error: ${error.errorMsg}');
    onError?.call(error.errorMsg);
    
    // Retry on temporary errors if in continuous mode
    if (_continuousMode && error.permanent == false) {
      Future.delayed(Duration(milliseconds: _restartDelayMs * 2), () {
        if (_continuousMode) {
          startListening(continuous: true);
        }
      });
    }
  }
  
  /// Set confidence threshold (0.0 - 1.0)
  void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
  }
  
  /// Listen for a yes/no response
  Future<bool?> listenForYesNo({Duration? timeout}) async {
    if (!_isInitialized) return null;
    
    bool? result;
    bool completed = false;
    
    // Temporarily register yes/no commands
    registerCommand('oui', () {
      result = true;
      completed = true;
    });
    registerCommand('non', () {
      result = false;
      completed = true;
    });
    
    await startListening(
      listenFor: timeout ?? const Duration(seconds: 10),
    );
    
    // Wait for result
    final endTime = DateTime.now().add(timeout ?? const Duration(seconds: 10));
    while (!completed && DateTime.now().isBefore(endTime)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await stopListening();
    clearCommands();
    
    return result;
  }
  
  /// Get list of available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    return await _speech.locales();
  }
  
  /// Check if a specific locale is available
  Future<bool> isLocaleAvailable(String localeId) async {
    final locales = await getAvailableLocales();
    return locales.any((l) => l.localeId == localeId);
  }
  
  /// Cleanup resources
  void dispose() {
    stopListening();
    clearCommands();
  }
}

/// Command mapping with variations
class CommandMapping {
  final String primaryCommand;
  final List<String> variations;
  final VoidCallback callback;
  final double minConfidence;
  
  CommandMapping({
    required this.primaryCommand,
    required this.variations,
    required this.callback,
    required this.minConfidence,
  });
}
