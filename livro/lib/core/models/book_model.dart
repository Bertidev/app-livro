import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnailUrl; // VOLTAMOS para a URL completa
  final String? status;
  final int? pageCount;
  final int? currentPage;
  final int? rating;
  final String? review;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl, // VOLTAMOS para a URL
    this.status,
    this.pageCount,
    this.currentPage,
    this.rating,
    this.review,
  });

  // Factory REESCRITO para o JSON da API do Google Books
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    return Book(
      id: json['id'] ?? 'N/A',
      title: volumeInfo['title'] ?? 'Título Desconhecido',
      authors: volumeInfo['authors'] != null
          ? List<String>.from(volumeInfo['authors'])
          : ['Autor Desconhecido'],
      description: volumeInfo['description'] ?? 'Sem descrição.',
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      pageCount: volumeInfo['pageCount'],
    );
  }

  // Factory do Firestore ATUALIZADO para ler thumbnailUrl
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? 'Título Desconhecido',
      authors: data['authors'] != null
          ? List<String>.from(data['authors'])
          : ['Autor Desconhecido'],
      description: data['description'] ?? 'Sem descrição.',
      thumbnailUrl: data['thumbnailUrl'] ?? '', // Lendo a URL
      status: data['status'],
      pageCount: data['pageCount'],
      currentPage: data['currentPage'],
      rating: data['rating'],
      review: data['review'],
    );
  }
}