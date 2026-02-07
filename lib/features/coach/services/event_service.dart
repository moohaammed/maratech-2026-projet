import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/models/user_model.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  /// Stream all events, optionally filtered by date range and group.
  /// Group filter is applied in memory to avoid composite index.
  Stream<List<EventModel>> getEventsStream({
    DateTime? fromDate,
    DateTime? toDate,
    RunningGroup? group,
  }) {
    Query<Map<String, dynamic>> query = _eventsRef;

    if (fromDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }
    query = query.orderBy('date', descending: false);

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      if (group != null) {
        list = list.where((e) => e.group == group).toList();
      }
      return list;
    });
  }

  /// One-time fetch with same filters.
  Future<List<EventModel>> getEvents({
    DateTime? fromDate,
    DateTime? toDate,
    RunningGroup? group,
  }) async {
    Query<Map<String, dynamic>> query = _eventsRef;

    if (fromDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }
    query = query.orderBy('date', descending: false);

    final snapshot = await query.get();
    var list = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    if (group != null) {
      list = list.where((e) => e.group == group).toList();
    }
    return list;
  }

  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _eventsRef.doc(eventId).get();
    if (doc.exists) {
      return EventModel.fromFirestore(doc);
    }
    return null;
  }

  Future<String> createEvent(EventModel event) async {
    final ref = await _eventsRef.add(event.toFirestore());
    return ref.id;
  }

  Future<void> updateEvent(String eventId, EventModel event) async {
    await _eventsRef.doc(eventId).update(event.toFirestore());
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }
}
