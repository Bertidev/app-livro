import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/achievements/services/achievement_service.dart';

class BookshelfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adiciona um livro à estante do usuário ou atualiza seu status.
  Future<void> addBookToShelf(
    Book book,
    String status,
    BuildContext context,
  ) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para adicionar livros.'),
        ),
      );
      return;
    }

    try {
      // Cria o mapa de dados base
      final Map<String, dynamic> bookData = {
        'title': book.title,
        'authors': book.authors,
        'thumbnailUrl': book.thumbnailUrl,
        'description': book.description,
        'status': status,
        'addedAt': Timestamp.now(),
        'pageCount': book.pageCount,
        'currentPage': (status == 'Lido' && book.pageCount != null)
            ? book.pageCount
            : 0,
        'categories': book.categories,
      };

      // Se o status for 'Lido', adiciona a data de finalização
      if (status == 'Lido') {
        bookData['finishedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(book.id)
          .set(
            bookData,
            SetOptions(merge: true),
          ); // Usar merge para não apagar a avaliação se já existir

      // --- GATILHO DAS CONQUISTAS ---
      // Se o livro foi marcado como 'Lido', checa por novas conquistas
      if (status == 'Lido') {
        final newAchievements = await AchievementService()
            .checkAndUnlockAchievements();
        // Se alguma conquista nova foi desbloqueada, mostra uma notificação especial
        if (newAchievements.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Conquista Desbloqueada: ${newAchievements.join(', ')}',
              ),
              backgroundColor: Colors.amber[800],
            ),
          );
        }
      }
      // --- FIM DO GATILHO ---

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" adicionado à sua estante!'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar o livro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Retorna uma Stream com a lista de livros da estante do usuário.
  Stream<List<Book>> getBookshelfStream({String? userId}) {
    // Se nenhum ID for fornecido, usa o do usuário logado.
    final targetUserId = userId ?? _auth.currentUser?.uid;

    if (targetUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(targetUserId) // Usa o ID do alvo
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
  Future<void> updateBookProgress(
    String bookId, {
    int? currentPage,
    int? pageCount,
  }) async {
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

  /// Salva ou atualiza a avaliação (nota e resenha) de um livro.
  Future<void> rateBook(
    String bookId,
    int rating,
    String review,
    BuildContext context,
  ) async {
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
}
