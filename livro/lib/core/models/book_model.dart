import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnailUrl;
  final String? status; // Campo opcional para o status na estante

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    this.status, // Adicionado ao construtor
  });

  // Factory constructor para criar um Book a partir do JSON da API do Google
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
    );
  }

  // NOVO: Factory constructor para criar um Book a partir de um documento do Firestore
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id, // O ID do documento é o ID do livro
      title: data['title'] ?? 'Título Desconhecido',
      authors: data['authors'] != null
          ? List<String>.from(data['authors'])
          : ['Autor Desconhecido'],
      description: data['description'] ?? 'Sem descrição.',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      status: data['status'], // Pega o status do Firestore
    );
  }
}