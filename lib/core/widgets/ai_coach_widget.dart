import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_coach_service.dart';
import '../services/accessibility_service.dart';
import '../../features/accessibility/providers/accessibility_provider.dart';
import '../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Floating AI Coach Button - Add this to any screen
class AICoachButton extends StatelessWidget {
  const AICoachButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'ai_coach_button',
      onPressed: () => _showAICoachDialog(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      label: const Text('Coach IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  void _showAICoachDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AICoachSheet(),
    );
  }
}

/// AI Coach Bottom Sheet - Full chat interface
class AICoachSheet extends StatefulWidget {
  const AICoachSheet({super.key});

  @override
  State<AICoachSheet> createState() => _AICoachSheetState();
}

class _AICoachSheetState extends State<AICoachSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Add welcome message
    _messages.add(ChatMessage(
      text: _getWelcomeMessage(),
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    // Initialize AI
    _initAI();
  }

  void _initAI() async {
    final aiService = Provider.of<AICoachService>(context, listen: false);
    final accessibility = Provider.of<AccessibilityService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    
    // Sync language if needed
    if (aiService.currentLanguage != accessibility.currentLanguage.code) {
       aiService.setLanguage(accessibility.currentLanguage.code);
    }
    
    // Initialize if not ready OR if user changed (e.g. initial load vs logged in)
    if (!aiService.isInitialized || aiService.userId != user?.uid) {
      await aiService.initialize(
        userId: user?.uid, 
        language: accessibility.currentLanguage.code
      );
    }
    
    // Auto-open mic for blind users
    if (mounted) {
       // Use a slight delay to allow TTS welcome message to start/finish
       Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_isListening) {
             final profile = Provider.of<AccessibilityProvider>(context, listen: false).profile;
             if (profile.visualNeeds == 'blind') {
                _toggleVoiceInput();
             }
          }
       });
    }
  }

  String _getWelcomeMessage() {
    return '''🏃 Salut! Je suis ton Coach IA!

Tu peux me demander:
• "Quelle course aujourd'hui?"
• "Inscris-moi à l'événement"
• "Donne-moi un conseil"

Parle ou écris ta question! 🎤''';
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          _buildHeader(),
          
          // Quick Actions
          _buildQuickActions(),
          
          // Chat messages
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AICoachService>(
            builder: (context, ai, _) {
              if (ai.isProcessing) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Réflexion...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      {'icon': Icons.today, 'label': 'Aujourd\'hui', 'intent': 'today_run'},
      {'icon': Icons.event, 'label': 'Prochain', 'intent': 'next_event'},
      {'icon': Icons.group, 'label': 'Mon groupe', 'intent': 'my_group'},
      {'icon': Icons.lightbulb, 'label': 'Conseil', 'intent': 'motivation'},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickActions.length,
        itemBuilder: (context, index) {
          final action = quickActions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(action['icon'] as IconData, size: 18),
              label: Text(action['label'] as String),
              onPressed: () => _sendQuickAction(action['intent'] as String),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppColors.primary 
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primary : Colors.black).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : null,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voice recognition feedback
          if (_isListening || _recognizedText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (_isListening)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.5 + _pulseController.value * 0.5),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recognizedText.isEmpty ? 'Écoute...' : _recognizedText,
                      style: TextStyle(
                        color: _recognizedText.isEmpty ? Colors.grey : AppColors.primary,
                        fontStyle: _recognizedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Input row
          Row(
            children: [
              // Voice button
              _buildVoiceButton(),
              
              const SizedBox(width: 12),
              
              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Pose ta question...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: _toggleVoiceInput,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isListening ? [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  void _toggleVoiceInput() async {
    final accessibility = Provider.of<AccessibilityService>(context, listen: false);
    
    if (_isListening) {
      // Stop listening
      await accessibility.stopContinuousListening();
      setState(() {
        _isListening = false;
        if (_recognizedText.isNotEmpty) {
          _sendMessage(_recognizedText);
        }
        _recognizedText = '';
      });
    } else {
      // Start listening
      accessibility.onSpeechRecognized = (text) {
        setState(() {
          _recognizedText = text;
        });
      };
      
      setState(() => _isListening = true);
      await accessibility.startContinuousListening();
      
      // Auto-send after pause
      Future.delayed(const Duration(seconds: 5), () {
        if (_isListening && _recognizedText.isNotEmpty) {
          _toggleVoiceInput(); // This will stop and send
        }
      });
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    
    // Capture providers before async gap
    final aiService = Provider.of<AICoachService>(context, listen: false);
    final accessibility = Provider.of<AccessibilityService>(context, listen: false);
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    
    _scrollToBottom();
    
    // Get AI response
    final response = await aiService.ask(text);
    
    // Check if still mounted
    if (!mounted) return;
    
    // Add AI response
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _scrollToBottom();
    
    // Speak response if voice guidance enabled
    if (accessibility.voiceGuidanceEnabled) {
      accessibility.speak(response);
    }
  }

  void _sendQuickAction(String intent) async {
    final labelMap = {
      'today_run': 'Quelle course aujourd\'hui?',
      'next_event': 'Quel est le prochain événement?',
      'my_group': 'Parle-moi de mon groupe',
      'motivation': 'Donne-moi un conseil de motivation',
    };
    
    final question = labelMap[intent] ?? intent;
    _sendMessage(question);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
