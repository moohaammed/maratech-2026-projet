import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../../admin/models/user_model.dart';

/// Service pour gérer les événements dans Firestore
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _collectionName = 'events';

  /// Récupère un événement par son ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(eventId).get();
      if (!doc.exists || doc.data() == null) return null;
      return EventModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error fetching event $eventId: $e');
      return null;
    }
  }

  /// Stream de tous les événements (triés par date) avec filtres optionnels
  Stream<List<EventModel>> getEventsStream({
    DateTime? fromDate,
    DateTime? toDate,
    RunningGroup? group,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(_collectionName);
    
    // Apply date filters
    if (fromDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      // Add 1 day to include events on the end date
      final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }
    
    // Apply group filter
    if (group != null) {
      query = query.where('group', isEqualTo: group.name);
    }
    
    query = query.orderBy('date', descending: false);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Stream d'événements filtrés par groupe
  Stream<List<EventModel>> getEventsByGroupStream(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('group', isEqualTo: groupId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Événements à venir
  Stream<List<EventModel>> getUpcomingEventsStream() {
    final now = DateTime.now();
    return _firestore
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Créer un nouvel événement
  Future<String> createEvent(EventModel event) async {
    final docRef = await _firestore.collection(_collectionName).add(event.toMap());
    debugPrint('Event created with ID: ${docRef.id}');
    return docRef.id;
  }

  /// Mettre à jour un événement
  Future<void> updateEvent(EventModel event) async {
    await _firestore.collection(_collectionName).doc(event.id).update(event.toMap());
    debugPrint('Event updated: ${event.id}');
  }

  /// Supprimer un événement
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_collectionName).doc(eventId).delete();
    debugPrint('Event deleted: $eventId');
  }

  /// Ajouter un participant à un événement
  Future<void> addParticipant(String eventId, String userId) async {
    await _firestore.collection(_collectionName).doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  /// Retirer un participant d'un événement
  Future<void> removeParticipant(String eventId, String userId) async {
    await _firestore.collection(_collectionName).doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  /// Vérifier si un utilisateur est inscrit
  Future<bool> isUserRegistered(String eventId, String userId) async {
    final event = await getEventById(eventId);
    if (event == null) return false;
    return event.participants.contains(userId);
  }
}
