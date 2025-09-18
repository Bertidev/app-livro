import 'package:flutter/material.dart';
import 'package:livro/features/achievements/models/achievement_tier_model.dart';

// Nossa lista agora pode conter tanto TieredAchievement quanto SingleAchievement.
final List<AchievementBase> achievementDefinitions = [
  // --- A CONQUISTA COM NÍVEIS ---
  TieredAchievement(
    id: 'VORACIOUS_READER',
    title: 'Leitor Voraz',
    icon: Icons.local_fire_department_rounded,
    tiers: [
      AchievementTier(level: 1, description: 'Termine 5 livros.', check: (books) => books.length >= 5),
      AchievementTier(level: 2, description: 'Termine 10 livros.', check: (books) => books.length >= 10),
      AchievementTier(level: 3, description: 'Termine 25 livros.', check: (books) => books.length >= 25),
      AchievementTier(level: 4, description: 'Termine 50 livros.', check: (books) => books.length >= 50),
    ],
  ),
  
  // --- AS CONQUISTAS DE NÍVEL ÚNICO ---
  SingleAchievement(
    id: 'FIRST_BOOK_READ',
    title: 'O Começo de Tudo',
    description: 'Termine seu primeiro livro.',
    icon: Icons.flag_rounded,
    check: (readBooks) => readBooks.isNotEmpty,
  ),
  SingleAchievement(
    id: 'PAGE_DEVOURER',
    title: 'O Devorador de Páginas',
    description: 'Leia um livro com mais de 500 páginas.',
    icon: Icons.auto_stories_rounded,
    check: (readBooks) => readBooks.any((book) => book.pageCount != null && book.pageCount! >= 500),
  ),
  SingleAchievement(
    id: 'GENRE_EXPLORER',
    title: 'Explorador de Gêneros',
    description: 'Leia livros de 3 categorias diferentes.',
    icon: Icons.explore_rounded,
    check: (readBooks) {
      final allCategories = readBooks.expand((book) => book.categories).toSet();
      return allCategories.length >= 3;
    },
  ),
  SingleAchievement(
    id: 'FIRST_REVIEW',
    title: 'Crítico Literário',
    description: 'Escreva sua primeira resenha.',
    icon: Icons.rate_review_rounded,
    check: (readBooks) => readBooks.any((book) => book.review != null && book.review!.isNotEmpty),
  ),
];