import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';

class BookshelfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adiciona um livro à estante do usuário logado ou atualiza seu status.
  Future<void> addBookToShelf(Book book, String status, BuildContext context) async {
    // Pega o usuário atual. Se não houver, exibe um erro e interrompe a função.
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para adicionar livros.')),
      );
      return;
    }

    try {
      // O caminho no Firestore será: users -> [ID do usuário] -> bookshelf -> [ID do livro]
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(book.id) // Usamos o ID do livro do Google para evitar duplicatas
          .set({
            'title': book.title,
            'authors': book.authors,
            'thumbnailUrl': book.thumbnailUrl,
            'description': book.description,
            'status': status, // 'Quero Ler', 'Lendo' ou 'Lido'
            'addedAt': Timestamp.now(),
          });
      
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

  /// Retorna uma Stream com a lista de livros da estante do usuário para atualizações em tempo real.
  Stream<List<Book>> getBookshelfStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Retorna uma stream vazia se o usuário não estiver logado
      return Stream.value([]);
    }

    // Ouve as mudanças na subcoleção 'bookshelf' do usuário
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bookshelf')
        .orderBy('addedAt', descending: true) // Ordena pelos mais recentes
        .snapshots() // Isso nos dá uma stream de atualizações em tempo real
        .map((snapshot) {
      // Para cada atualização, mapeia os documentos para uma lista de objetos Book
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    });
  }
}