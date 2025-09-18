import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  // A função que define a regra para desbloquear
  final bool Function(List<Book> readBooks) check;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.check,
  });
}