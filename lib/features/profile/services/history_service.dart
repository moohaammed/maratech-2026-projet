import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/history_event_model.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HistoryEventModel>> getUserHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                HistoryEventModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
