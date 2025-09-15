import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';

class BookshelfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addBookToShelf(Book book, String status, BuildContext context) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para adicionar livros.')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookshelf')
          .doc(book.id)
          .set({
            'title': book.title,
            'authors': book.authors,
            'thumbnailUrl': book.thumbnailUrl, // MUDANÇA AQUI
            'description': book.description,
            'status': status,
            'addedAt': Timestamp.now(),
            'pageCount': book.pageCount,
            'currentPage': 0,
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

  Stream<List<Book>> getBookshelfStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bookshelf')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    });
  }

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

  Future<String?> getBookStatus(String bookId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final docSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('bookshelf')
        .doc(bookId)
        .get();

    if (docSnapshot.exists) {
      return docSnapshot.data()?['status'];
    }
    return null;
  }
  
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