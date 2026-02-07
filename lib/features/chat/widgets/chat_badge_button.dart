import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/services/notification_service.dart';

class ChatBadgeButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? iconColor;

  const ChatBadgeButton({
    super.key, 
    required this.onPressed,
    this.iconColor,
  });

  @override
  State<ChatBadgeButton> createState() => _ChatBadgeButtonState();
}

class _ChatBadgeButtonState extends State<ChatBadgeButton> {
  int _unreadCount = 0;
  DateTime? _lastReadTime;
  String? _groupId;
  bool _isFirstLoad = true;

  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user group
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;
    
    final groupId = userDoc.data()?['groupId'] ?? userDoc.data()?['group'];
    if (groupId == null) return;
    
    setState(() => _groupId = groupId);

    // Get last read time
    final prefs = await SharedPreferences.getInstance();
    final lastReadIso = prefs.getString('chat_last_read_$groupId');
    _lastReadTime = lastReadIso != null ? DateTime.parse(lastReadIso) : DateTime.now().subtract(const Duration(days: 1));

    // Limit query to recent messages (last 7 days) to avoid fetching too much history
    // but allow filtering locally for unread count
    final queryDate = DateTime.now().subtract(const Duration(days: 7));

    // Listen to messages
    FirebaseFirestore.instance
        .collection('groupChats')
        .doc(groupId)
        .collection('messages')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(queryDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Filter: received messages AND newer than last read
        final unreadMessages = snapshot.docs.where((doc) {
          final data = doc.data();
          final isOther = data['senderId'] != user.uid;
          
          if (!isOther) return false;
          
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp == null) return false;
          
          final date = timestamp.toDate();
          return date.isAfter(_lastReadTime!);
        }).toList();
        
        final count = unreadMessages.length;
        
        // Initial sync
        if (_isFirstLoad) {
           _previousCount = count;
           _isFirstLoad = false;
           setState(() => _unreadCount = count);
           return;
        }
        
        // Check for NEW received messages
        // Notification only if count INCREASED compared to previous snapshot processing
        if (count > _previousCount) {
          // Play sound and show notification if we have messages
          if (unreadMessages.isNotEmpty) {
            final lastMsg = unreadMessages.first.data();
            final sender = lastMsg['senderName'] ?? 'Groupe';
            final text = lastMsg['text'] ?? 'Nouveau message';
            
            // Show local notification (popup + sound)
            NotificationService().showChatMessageNotification(sender, text);
          }
        }
        
        _previousCount = count;
        setState(() => _unreadCount = count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: widget.iconColor),
          onPressed: () async {
            // Update last read time locally when opening
            if (_groupId != null) {
              final now = DateTime.now();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('chat_last_read_$_groupId', now.toIso8601String());
              
              setState(() {
                _unreadCount = 0;
                _previousCount = 0; // Reset previous count to avoid immediate notification on next stream event
                _lastReadTime = now; // Update filter time for future stream events
              });
            }
            widget.onPressed();
          },
          tooltip: 'Messagerie',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
