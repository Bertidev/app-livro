import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:livro/features/feed/models/feed_event_model.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cria um evento na coleção principal e distribui referências para os seguidores.
  Future<void> fanOutEvent(FeedEvent event) async {
    if (kDebugMode) print('--- INICIANDO NOVO FAN-OUT ---');
    
    try {
      // 1. Cria o evento principal na coleção 'events'
      final eventRef = await _firestore.collection('events').add(event.toMap());
      if (kDebugMode) print('Evento principal criado com ID: ${eventRef.id}');

      // 2. Pega a lista de seguidores
      final followersSnapshot = await _firestore.collection('users').doc(event.authorId).collection('followers').get();
      final followersIds = followersSnapshot.docs.map((doc) => doc.id).toList();
      if (kDebugMode) print('Distribuindo para ${followersIds.length} seguidores.');

      // 3. Distribui os "ponteiros" para o feed dos seguidores
      final WriteBatch batch = _firestore.batch();
      for (final followerId in followersIds) {
        final feedDocRef = _firestore.collection('users').doc(followerId).collection('feed').doc();
        batch.set(feedDocRef, {'eventId': eventRef.id, 'timestamp': event.timestamp});
      }

      // 4. Adiciona o "ponteiro" ao feed do próprio autor
      final selfFeedDocRef = _firestore.collection('users').doc(event.authorId).collection('feed').doc();
      batch.set(selfFeedDocRef, {'eventId': eventRef.id, 'timestamp': event.timestamp});

      await batch.commit();
      if (kDebugMode) print('--- FAN-OUT DE PONTEIROS CONCLUÍDO ---');

    } catch (e) {
      if (kDebugMode) print('!!!!!!!!!! ERRO DURANTE O FAN-OUT: $e !!!!!!!!!!!');
    }
  }

  /// Ouve a coleção 'feed' do usuário logado (que contém os ponteiros).
  Stream<QuerySnapshot> getFeedPointersStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('feed')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Busca os documentos de evento completos a partir de uma lista de IDs.
  Future<List<DocumentSnapshot>> fetchEventsByIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    
    final querySnapshot = await _firestore
        .collection('events')
        .where(FieldPath.documentId, whereIn: eventIds)
        .get();
        
    return querySnapshot.docs;
  }

  // --- MÉTODOS DE CURTIDAS ATUALIZADOS (MAIS SIMPLES) ---

  /// Alterna a curtida (like/unlike) em um evento na coleção principal 'events'.
  Future<void> toggleLike(String eventId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final likeDocRef = _firestore.collection('events').doc(eventId).collection('likes').doc(currentUser.uid);
    final doc = await likeDocRef.get();

    if (doc.exists) {
      await likeDocRef.delete();
    } else {
      await likeDocRef.set({'likedAt': Timestamp.now()});
    }
  }

  /// Retorna um Stream com a contagem de curtidas de um evento.
  Stream<int> getLikeCount(String eventId) {
    return _firestore.collection('events').doc(eventId).collection('likes').snapshots().map((snapshot) => snapshot.size);
  }

  /// Retorna um Stream<bool> que indica se o usuário atual já curtiu um evento.
  Stream<bool> hasUserLiked(String eventId) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _firestore.collection('events').doc(eventId).collection('likes').doc(currentUser.uid).snapshots().map((snapshot) => snapshot.exists);
  }
}