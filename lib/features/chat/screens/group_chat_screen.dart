import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/services/group_chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../accessibility/providers/accessibility_provider.dart';
import '../models/message_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String? groupId;

  const GroupChatScreen({super.key, this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final GroupChatService _chatService = GroupChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _userGroupId;
  String _userName = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
  }

  Future<void> _loadUserGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _userName = data?['fullName'] ?? data?['name'] ?? user.email?.split('@')[0] ?? 'User';
          _userGroupId = widget.groupId ?? data?['groupId'] ?? data?['group'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user group: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _userGroupId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _chatService.sendMessage(
        groupId: _userGroupId!,
        senderId: user.uid,
        senderName: _userName,
        text: text,
      );
      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final profile = accessibility.profile;
    final textScale = profile.textSize;
    final highContrast = profile.highContrast;
    final primaryColor = highContrast ? AppColors.highContrastPrimary : AppColors.primary;
    final bgColor = highContrast ? Colors.black : Colors.white;
    final textColor = highContrast ? Colors.white : AppColors.textPrimary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Messagerie du groupe', style: TextStyle(fontSize: 16 * textScale)),
          backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
          foregroundColor: highContrast ? primaryColor : Colors.white,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (user == null || _userGroupId == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Messagerie du groupe', style: TextStyle(fontSize: 16 * textScale)),
          backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
          foregroundColor: highContrast ? primaryColor : Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off_outlined, size: 64 * textScale, color: textColor.withOpacity(0.5)),
              SizedBox(height: 16 * textScale),
              Text(
                'Vous devez être connecté et assigné à un groupe',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14 * textScale),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Messagerie du groupe',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16 * textScale),
        ),
        backgroundColor: highContrast ? AppColors.highContrastSurface : primaryColor,
        foregroundColor: highContrast ? primaryColor : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.subscribeToMessages(_userGroupId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48 * textScale, color: AppColors.error),
                        SizedBox(height: 16 * textScale),
                        Text(
                          'Impossible de charger les messages',
                          style: TextStyle(color: textColor, fontSize: 14 * textScale),
                        ),
                        SizedBox(height: 12 * textScale),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: highContrast ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64 * textScale, color: textColor.withOpacity(0.3)),
                        SizedBox(height: 16 * textScale),
                        Text(
                          'Aucun message pour l\'instant',
                          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14 * textScale),
                        ),
                        SizedBox(height: 8 * textScale),
                        Text(
                          'Soyez le premier à écrire!',
                          style: TextStyle(color: primaryColor, fontSize: 12 * textScale, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage = message.senderId == user.uid;

                    return Align(
                      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: isOwnMessage 
                              ? CrossAxisAlignment.end 
                              : CrossAxisAlignment.start,
                          children: [
                            // Sender name
                            Padding(
                              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2),
                              child: Text(
                                message.senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOwnMessage ? AppColors.primary : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            // Message bubble
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isOwnMessage ? AppColors.primary : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isOwnMessage ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Tapez votre message…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLength: 500,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
