import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/achievements/services/achievement_service.dart';
import 'package:livro/features/feed/models/feed_event_model.dart';
import 'package:livro/features/feed/services/feed_service.dart';

class BookshelfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addBookToShelf(Book book, String status, BuildContext context, {int? currentPage, int? pageCount}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para adicionar livros.')),
      );
      return;
    }

    try {
      final effectivePageCount = pageCount ?? book.pageCount;
      final Map<String, dynamic> bookData = {
        'title': book.title,
        'authors': book.authors,
        'thumbnailUrl': book.thumbnailUrl,
        'description': book.description,
        'status': status,
        'addedAt': Timestamp.now(),
        'pageCount': effectivePageCount,
        'currentPage': currentPage ?? ((status == 'Lido' && effectivePageCount != null) ? effectivePageCount : 0),
        'categories': book.categories,
      };

      if (status == 'Lido') {
        bookData['finishedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(book.id)
          .set(bookData, SetOptions(merge: true));
      
      // --- LÓGICA DE GATILHOS DE EVENTOS ATUALIZADA ---
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final username = userDoc.data()?['username'] ?? 'Um usuário';
      final photoUrl = userDoc.data()?['photoUrl'];

      if (status == 'Lido') {
        // Gatilho para o Feed de "terminou de ler"
        final event = FeedEvent(
          authorId: currentUser.uid,
          authorUsername: username,
          authorPhotoUrl: photoUrl,
          type: 'finished_book',
          timestamp: Timestamp.now(),
          bookId: book.id,
          bookTitle: book.title,
          bookCoverUrl: book.thumbnailUrl,
        );
        await FeedService().fanOutEvent(event);

        // Gatilho para as Conquistas
        final newAchievements = await AchievementService().checkAndUnlockAchievements();
        if (newAchievements.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Conquista Desbloqueada: ${newAchievements.join(', ')}'),
              backgroundColor: Colors.amber[800],
            ),
          );
        }
      } else if (status == 'Lendo') {
        // NOVO GATILHO: para o Feed de "começou a ler"
        final event = FeedEvent(
          authorId: currentUser.uid,
          authorUsername: username,
          authorPhotoUrl: photoUrl,
          type: 'started_reading',
          timestamp: Timestamp.now(),
          bookId: book.id,
          bookTitle: book.title,
          bookCoverUrl: book.thumbnailUrl,
          currentPage: currentPage ?? 0,
          pageCount: effectivePageCount,
        );
        await FeedService().fanOutEvent(event);
      }
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" atualizado na sua estante!'),
          backgroundColor: Colors.green[600],
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar o livro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Salva ou atualiza a avaliação (nota e resenha) de um livro.
  Future<void> rateBook(String bookId, int rating, String review, BuildContext context) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(bookId)
          .update({
            'rating': rating,
            'review': review,
            'ratedAt': Timestamp.now(),
          });
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final username = userDoc.data()?['username'] ?? 'Um usuário';
      final photoUrl = userDoc.data()?['photoUrl'];
      final bookDoc = await _firestore.collection('users').doc(currentUser.uid).collection('bookshelf').doc(bookId).get();
      final bookData = bookDoc.data();

      final event = FeedEvent(
        authorId: currentUser.uid,
        authorUsername: username,
        authorPhotoUrl: photoUrl,
        type: 'rated_book',
        timestamp: Timestamp.now(),
        bookId: bookId,
        bookTitle: bookData?['title'],
        bookCoverUrl: bookData?['thumbnailUrl'],
        rating: rating,
        review: review,
      );
      await FeedService().fanOutEvent(event);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sua avaliação foi salva com sucesso!'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar sua avaliação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Retorna uma Stream com a lista de livros da estante de um usuário.
  Stream<List<Book>> getBookshelfStream({String? userId}) {
    final targetUserId = userId ?? _auth.currentUser?.uid;

    if (targetUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('bookshelf')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    });
  }

  /// Remove um livro da estante do usuário.
  Future<void> removeBookFromShelf(String bookId, BuildContext context) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(bookId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro removido da sua estante.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover o livro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Atualiza os detalhes de progresso de um livro na estante.
  Future<void> updateBookProgress(String bookId, {int? currentPage, int? pageCount}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final Map<String, dynamic> dataToUpdate = {};
    if (currentPage != null) {
      dataToUpdate['currentPage'] = currentPage;
    }
    if (pageCount != null) {
      dataToUpdate['pageCount'] = pageCount;
    }

    if (dataToUpdate.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bookshelf')
        .doc(bookId)
        .update(dataToUpdate);
  }
}