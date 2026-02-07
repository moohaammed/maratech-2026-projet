import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AI Coach Service - Powered by Google Gemini
/// Provides intelligent responses about running events, training, and club info
class AICoachService extends ChangeNotifier {
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _lastResponse = '';
  String _errorMessage = '';
  
  // Gemini API Key - Replace with your own from https://aistudio.google.com/apikey
  static const String _apiKey = 'AIzaSyA_0k58xcEUOWpZUSEVN-jSKPS9PJHsLw8';
  
  // User context
  String? _userId;
  String? _userName;
  String? _userGroup;
  String _currentLanguage = 'fr';
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String get lastResponse => _lastResponse;
  String get errorMessage => _errorMessage;
  String get currentLanguage => _currentLanguage;
  String? get userId => _userId;
  
  /// Initialize the AI Coach
  Future<void> initialize({String? userId, String language = 'fr'}) async {
    try {
      _currentLanguage = language;
      _userId = userId;
      
      // Initialize Gemini
      _model = GenerativeModel(
        model: 'gemini-flash-latest', // Optimized flash model
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
          topP: 0.9,
        ),
        systemInstruction: Content.text(_getSystemPrompt()),
      );
      
      // Load user context if logged in
      if (_userId != null) {
        await _loadUserContext();
      }
      
      // Start chat session
      _chat = _model!.startChat(history: []);
      
      _isInitialized = true;
      _errorMessage = '';
      notifyListeners();
      
      debugPrint('🤖 AI Coach initialized successfully');
    } catch (e) {
      _errorMessage = 'Failed to initialize AI Coach: $e';
      debugPrint('❌ AI Coach error: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }
  
  /// Get system prompt based on language
  String _getSystemPrompt() {
    switch (_currentLanguage) {
      case 'ar':
        return '''
أنت "المدرب الذكي" لنادي الجري تونس. أنت مساعد ودود يساعد الأعضاء في:
- معرفة الفعاليات والسباقات القادمة
- نصائح التدريب
- معلومات عن النادي
- تشجيع وتحفيز العدائين

أجب بإيجاز ووضوح. استخدم الإيموجي لجعل الردود حيوية.
اسم المستخدم: ${_userName ?? 'عداء'}
المجموعة: ${_userGroup ?? 'غير محدد'}
''';
      case 'en':
        return '''
You are "Smart Coach" for RCT (Running Club Tunis). You're a friendly assistant helping members with:
- Learning about upcoming events and runs
- Training advice
- Club information
- Motivation and encouragement

Keep responses brief and clear. Use emojis to make responses lively.
User name: ${_userName ?? 'Runner'}
Group: ${_userGroup ?? 'Not assigned'}
''';
      default: // French
        return '''
Tu es le "Coach Intelligent" du Running Club Tunis. Tu es un assistant amical qui aide les membres avec:
- Les événements et courses à venir
- Les conseils d'entraînement
- Les informations sur le club
- La motivation et l'encouragement

Contexte:
- Ville: Tunis, Tunisie
- Date actuelle: ${_formatDate(DateTime.now())}
- Saison: Hiver/Printemps (selon la date)

Réponds de façon brève et claire. Utilise des emojis pour rendre les réponses vivantes.
Nom de l'utilisateur: ${_userName ?? 'Coureur'}
Groupe: ${_userGroup ?? 'Non assigné'}

IMPORTANT: 
- Réponds TOUJOURS en français
- Sois concis (max 2-3 phrases)
- Si on te demande les courses d'aujourd'hui, donne des informations pratiques
- Encourage toujours les coureurs!
''';
    }
  }
  
  /// Load user context from Firestore
  Future<void> _loadUserContext() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _userName = data['fullName'] ?? data['name'];
        _userGroup = data['groupName'] ?? _getGroupNameById(data['assignedGroupId']);
      }
    } catch (e) {
      debugPrint('Could not load user context: $e');
    }
  }
  
  String _getGroupNameById(String? groupId) {
    switch (groupId) {
      case 'beginner': return 'Débutants';
      case 'intermediate': return 'Intermédiaires';
      case 'advanced': return 'Confirmés';
      default: return 'Non assigné';
    }
  }
  
  /// Ask the AI Coach a question
  Future<String> ask(String question) async {
    if (!_isInitialized || _model == null) {
      _errorMessage = 'AI Coach not initialized';
      return _getErrorResponse();
    }
    
    if (question.trim().isEmpty) {
      return _getEmptyQuestionResponse();
    }
    
    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get context about today's events
      final eventsContext = await _getEventsContext();
      
      // Get user statistics context
      final statsContext = await _getStatsContext();
      
      // Build enriched prompt
      final enrichedPrompt = '''
$question

Contexte actuel:
$eventsContext

Statistiques utilisateur:
$statsContext
''';
      
      // Send to Gemini
      final response = await _chat!.sendMessage(Content.text(enrichedPrompt));
      
      _lastResponse = response.text ?? _getNoResponseMessage();
      _isProcessing = false;
      notifyListeners();
      
      debugPrint('🤖 AI Response: $_lastResponse');
      return _lastResponse;
      
    } catch (e) {
      _errorMessage = 'AI Error: $e';
      _isProcessing = false;
      notifyListeners();
      
      debugPrint('❌ AI Error: $e');
      return _getErrorResponse();
    }
  }

  /// Get user statistics from past events
  Future<String> _getStatsContext() async {
    if (_userId == null) return "Données utilisateur non disponibles.";
    
    try {
      final now = DateTime.now();
      
      // Query past events where user participated
      // Query all past events where user participated (no composite index needed)
      final pastEventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('participants', arrayContains: _userId)
          .get();
      
      // Filter and sort in memory to avoid "FAILED_PRECONDITION" index error
      final allDocs = pastEventsQuery.docs.where((doc) {
        final data = doc.data();
        if (data['date'] == null) return false;
        final date = (data['date'] as Timestamp).toDate();
        return date.isBefore(now);
      }).toList();

      // Sort descending (most recent first)
      allDocs.sort((a, b) {
        final dateA = (a.data()['date'] as Timestamp).toDate();
        final dateB = (b.data()['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      // Take last 20
      final recentDocs = allDocs.take(20).toList();
      
      if (recentDocs.isEmpty) {
        return "Nouvel utilisateur sans historique de course.";
      }
      
      int totalRuns = recentDocs.length;
      double totalDistance = 0;
      DateTime? lastRunDate;
      String lastRunTitle = '';
      
      for (var doc in recentDocs) {
        final data = doc.data();
        final distance = (data['distanceKm'] as num?)?.toDouble() ?? 0.0;
        final date = (data['date'] as Timestamp).toDate();
        
        totalDistance += distance;
        
        if (lastRunDate == null) {
          lastRunDate = date;
          lastRunTitle = data['title'] ?? 'Entraînement';
        }
      }
      
      final lastRunStr = lastRunDate != null 
          ? "${_formatDate(lastRunDate)} ($lastRunTitle)" 
          : "N/A";
          
      return '''
- Courses récentes analysées: $totalRuns
- Distance totale récente: ${totalDistance.toStringAsFixed(1)} km
- Dernière course: $lastRunStr
- Moyenne par course: ${(totalDistance / totalRuns).toStringAsFixed(1)} km
''';

    } catch (e) {
      debugPrint('Could not load stats: $e');
      return "Impossible de charger les statistiques.";
    }
  }
  
  /// Get events context from Firestore
  Future<String> _getEventsContext() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = today.add(const Duration(days: 7));
      
      // Get today's and upcoming events
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(nextWeek))
          .orderBy('date')
          .limit(5)
          .get();
      
      if (eventsQuery.docs.isEmpty) {
        return "Aucun événement prévu cette semaine.";
      }
      
      final buffer = StringBuffer();
      buffer.writeln("Événements à venir:");
      
      for (var doc in eventsQuery.docs) {
        final data = doc.data();
        final dateTime = (data['date'] as Timestamp?)?.toDate();
        final title = data['title'] ?? 'Événement';
        final location = data['location'] ?? '';
        final distance = data['distance'];
        final targetGroup = data['targetGroup'] ?? 'all';
        
        if (dateTime != null) {
          final isToday = dateTime.day == now.day && dateTime.month == now.month;
          final dayLabel = isToday ? "Aujourd'hui" : _formatDate(dateTime);
          
          buffer.writeln("- $dayLabel ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}: $title");
          if (location.isNotEmpty) buffer.writeln("  📍 $location");
          if (distance != null) buffer.writeln("  📏 ${distance}km");
          buffer.writeln("  👥 Groupe: ${_getGroupNameById(targetGroup)}");
        }
      }
      
      return buffer.toString();
    } catch (e) {
      debugPrint('Could not get events context: $e');
      return "Impossible de charger les événements.";
    }
  }
  
  String _formatDate(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return "${days[date.weekday - 1]} ${date.day}/${date.month}";
  }
  
  String _getErrorResponse() {
    switch (_currentLanguage) {
      case 'ar':
        return 'عذراً، حدث خطأ. حاول مرة أخرى.';
      case 'en':
        return 'Sorry, an error occurred. Please try again.';
      default:
        return 'Désolé, une erreur s\'est produite. Réessayez.';
    }
  }
  
  String _getEmptyQuestionResponse() {
    switch (_currentLanguage) {
      case 'ar':
        return 'مرحباً! كيف يمكنني مساعدتك اليوم؟';
      case 'en':
        return 'Hello! How can I help you today?';
      default:
        return 'Comment puis-je t\'aider aujourd\'hui?';
    }
  }
  
  String _getNoResponseMessage() {
    switch (_currentLanguage) {
      case 'ar':
        return 'لم أفهم. هل يمكنك إعادة الصياغة؟';
      case 'en':
        return 'I didn\'t understand. Could you rephrase?';
      default:
        return 'Je n\'ai pas compris. Peux-tu reformuler?';
    }
  }
  
  /// Quick responses for common questions
  Future<String> getQuickResponse(String intent) async {
    switch (intent) {
      case 'today_run':
        return ask('Quelle est la course prévue aujourd\'hui?');
      case 'next_event':
        return ask('Quel est le prochain événement?');
      case 'my_group':
        return ask('Parle-moi de mon groupe');
      case 'motivation':
        return ask('Donne-moi un conseil de motivation');
      case 'weather':
        return ask('Des conseils pour courir par ce temps?');
      default:
        return ask(intent);
    }
  }
  
  /// Set language
  void setLanguage(String langCode) {
    _currentLanguage = langCode;
    // Reinitialize with new language
    if (_isInitialized) {
      initialize(userId: _userId, language: langCode);
    }
  }
  
  /// Update API key
  static void updateApiKey(String newKey) {
    // For production, store in secure storage
    debugPrint('API Key updated');
  }
  
  /// Check if API key is configured
  bool get isApiKeyConfigured => _apiKey.isNotEmpty && !_apiKey.contains('xxxxxx');
  
  @override
  void dispose() {
    _chat = null;
    _model = null;
    super.dispose();
  }
}
