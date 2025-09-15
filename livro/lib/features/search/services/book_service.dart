import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:livro/core/models/book_model.dart';

class BookService {
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    final response = await http.get(Uri.parse('$_baseUrl?q=$query&maxResults=20'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['items'] != null) {
        final List<dynamic> items = data['items'];
        return items.map((item) => Book.fromJson(item)).toList();
      }
    }
    return [];
  }
}