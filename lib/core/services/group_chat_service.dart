import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/chat/models/message_model.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'groupChats';

  /// Subscribe to messages for a given group (real-time)
  /// Returns a Stream of messages
  Stream<List<MessageModel>> subscribeToMessages(String groupId) {
    return _firestore
        .collection(_collection)
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(500)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final message = MessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(groupId)
        .collection('messages')
        .add(message.toFirestore());
  }
}
