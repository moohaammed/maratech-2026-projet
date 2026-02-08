import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Enhanced TTS Service with improved quality settings and language support
/// 
/// Features:
/// - Optimized voice settings per language
/// - Queue management for sequential speech
/// - Dynamic speech rate based on content
/// - Better Arabic TTS handling
class EnhancedTtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Current settings
  String _currentLanguage = 'fr-FR';
  double _speechRate = 0.45;
  double _pitch = 1.0;
  double _volume = 1.0;
  
  // Speech queue for sequential playback
  final List<_SpeechItem> _queue = [];
  bool _isProcessingQueue = false;
  
  // Callbacks
  VoidCallback? onSpeakStart;
  VoidCallback? onSpeakComplete;
  Function(String)? onError;
  
  // Voice quality presets
  static const Map<String, Map<String, dynamic>> _languagePresets = {
    'fr-FR': {
      'speechRate': 0.45,
      'pitch': 1.0,
      'preferredVoice': 'fr-fr-x-vlf-network', // High quality French voice
      'fallbackVoice': 'fr-FR-language',
    },
    'ar-SA': {
      'speechRate': 0.40, // Slightly slower for Arabic clarity
      'pitch': 1.0,
      'preferredVoice': 'ar-sa-x-ard-network', // High quality Arabic voice
      'fallbackVoice': 'ar-SA-language',
    },
    'en-US': {
      'speechRate': 0.50,
      'pitch': 1.0,
      'preferredVoice': 'en-us-x-sfg-network', // High quality English voice
      'fallbackVoice': 'en-US-language',
    },
  };

  /// Getters
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  
  /// Initialize TTS with optimized settings
  Future<void> initialize({String? language}) async {
    try {
      _currentLanguage = language ?? 'fr-FR';
      
      // Set engine (prefer Google TTS if available)
      final engines = await _tts.getEngines;
      debugPrint('📢 Available TTS engines: $engines');
      
      // Prefer Google TTS for higher quality
      if (engines is List) {
        final googleEngine = engines.firstWhere(
          (e) => e.toString().toLowerCase().contains('google'),
          orElse: () => null,
        );
        if (googleEngine != null) {
          await _tts.setEngine(googleEngine.toString());
          debugPrint('📢 Using Google TTS engine');
        }
      }
      
      // Apply language-specific settings
      await _applyLanguageSettings(_currentLanguage);
      
      // Set handlers
      _tts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakStart?.call();
      });
      
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakComplete?.call();
        _processQueue(); // Process next item in queue
      });
      
      _tts.setErrorHandler((error) {
        debugPrint('📢 TTS Error: $error');
        _isSpeaking = false;
        onError?.call(error.toString());
        _processQueue(); // Try next item even on error
      });
      
      // Progress handler for real-time updates
      _tts.setProgressHandler((text, start, end, word) {
        // Can be used for word highlighting in UI
      });
      
      _isInitialized = true;
      debugPrint('📢 EnhancedTtsService initialized for $_currentLanguage');
    } catch (e) {
      debugPrint('📢 TTS initialization failed: $e');
      _isInitialized = false;
    }
  }
  
  /// Apply optimized settings for a specific language
  Future<void> _applyLanguageSettings(String language) async {
    final preset = _languagePresets[language] ?? _languagePresets['fr-FR']!;
    
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(_speechRate != 0.45 ? _speechRate : preset['speechRate']);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(_volume);
    
    // Try to set a high-quality voice
    await _setOptimalVoice(language, preset);
    
    debugPrint('📢 Applied settings for $language');
  }
  
  /// Set the best available voice for the language
  Future<void> _setOptimalVoice(String language, Map<String, dynamic> preset) async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices is! List) return;
      
      debugPrint('📢 Available voices: ${voices.length}');
      
      // Filter voices for current language
      final langVoices = voices.where((v) {
        final voiceMap = v as Map<dynamic, dynamic>;
        final locale = voiceMap['locale']?.toString() ?? '';
        return locale.startsWith(language.split('-')[0]);
      }).toList();
      
      if (langVoices.isEmpty) return;
      
      // Prefer network/high-quality voices
      final preferredVoice = langVoices.firstWhere(
        (v) {
          final name = (v as Map)['name']?.toString() ?? '';
          return name.contains('network') || name.contains('premium');
        },
        orElse: () => langVoices.first,
      );
      
      if (preferredVoice != null) {
        await _tts.setVoice({'name': (preferredVoice as Map)['name'], 'locale': language});
        debugPrint('📢 Set voice: ${(preferredVoice)['name']}');
      }
    } catch (e) {
      debugPrint('📢 Voice selection failed: $e');
    }
  }
  
  /// Set language with auto-optimized settings
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _applyLanguageSettings(language);
  }
  
  /// Set custom speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }
  
  /// Set pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }
  
  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }
  
  /// Speak text immediately (interrupts current speech)
  Future<void> speak(String text, {
    bool interrupt = true,
    SpeechPriority priority = SpeechPriority.normal,
  }) async {
    if (!_isInitialized || text.isEmpty) return;
    
    if (interrupt && _isSpeaking) {
      await stop();
    }
    
    // Normalize text for better pronunciation
    final normalizedText = _normalizeText(text);
    
    await _tts.speak(normalizedText);
  }
  
  /// Queue speech for sequential playback
  void queue(String text, {SpeechPriority priority = SpeechPriority.normal}) {
    if (text.isEmpty) return;
    
    final item = _SpeechItem(text: _normalizeText(text), priority: priority);
    
    // Insert based on priority
    if (priority == SpeechPriority.high) {
      final insertIndex = _queue.indexWhere((i) => i.priority != SpeechPriority.high);
      if (insertIndex == -1) {
        _queue.add(item);
      } else {
        _queue.insert(insertIndex, item);
      }
    } else {
      _queue.add(item);
    }
    
    _processQueue();
  }
  
  /// Process the speech queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _isSpeaking || _queue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    final item = _queue.removeAt(0);
    await _tts.speak(item.text);
    
    _isProcessingQueue = false;
  }
  
  /// Normalize text for better pronunciation
  String _normalizeText(String text) {
    var normalized = text;
    
    // Fix common abbreviations
    normalized = normalized.replaceAll(RegExp(r'\bRCT\b'), 'R C T');
    normalized = normalized.replaceAll(RegExp(r'\bKM\b', caseSensitive: false), 'kilomètres');
    normalized = normalized.replaceAll(RegExp(r'\bkm/h\b', caseSensitive: false), 'kilomètres par heure');
    
    // Add natural pauses
    normalized = normalized.replaceAll('. ', '. ... ');
    normalized = normalized.replaceAll('! ', '! ... ');
    normalized = normalized.replaceAll('? ', '? ... ');
    
    // Handle numbers with context
    normalized = _normalizeNumbers(normalized);
    
    return normalized;
  }
  
  /// Normalize numbers for natural speech
  String _normalizeNumbers(String text) {
    // Handle phone numbers (keep as digits)
    // Handle dates
    // Handle times
    return text;
  }
  
  /// Stop current speech and clear queue
  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
    _isSpeaking = false;
    _isProcessingQueue = false;
  }
  
  /// Pause speech (if supported)
  Future<void> pause() async {
    await _tts.pause();
  }
  
  /// Wait for current speech to complete
  Future<void> awaitCompletion() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  /// Speak with dynamic rate based on content length
  Future<void> speakDynamic(String text) async {
    // Adjust rate based on text length for natural pacing
    final wordCount = text.split(' ').length;
    
    double dynamicRate = _speechRate;
    if (wordCount > 50) {
      dynamicRate = (_speechRate + 0.1).clamp(0.1, 0.8); // Slightly faster for long text
    } else if (wordCount < 10) {
      dynamicRate = (_speechRate - 0.05).clamp(0.2, 1.0); // Slightly slower for short text
    }
    
    final originalRate = _speechRate;
    await setSpeechRate(dynamicRate);
    await speak(text);
    await setSpeechRate(originalRate); // Restore original rate
  }
  
  /// Get list of available voices for current language
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || voices is! List) return [];
      
      return voices
          .where((v) {
            final locale = (v as Map)['locale']?.toString() ?? '';
            return locale.startsWith(_currentLanguage.split('-')[0]);
          })
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Cleanup resources
  void dispose() {
    stop();
    _queue.clear();
  }
}

/// Speech priority levels
enum SpeechPriority {
  low,
  normal,
  high,
}

/// Internal class for queued speech items
class _SpeechItem {
  final String text;
  final SpeechPriority priority;
  
  _SpeechItem({required this.text, required this.priority});
}
