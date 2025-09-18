import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';

// Uma classe base para que possamos ter conquistas de nível único e de múltiplos níveis na mesma lista.
abstract class AchievementBase {
  final String id;
  final String title;
  final IconData icon;

  AchievementBase({required this.id, required this.title, required this.icon});
}

// Representa um único nível (tier) dentro de uma família de conquistas.
class AchievementTier {
  final int level;
  final String description;
  final bool Function(List<Book> readBooks) check;

  AchievementTier({
    required this.level,
    required this.description,
    required this.check,
  });
}

// Representa a família de conquistas com múltiplos níveis.
class TieredAchievement extends AchievementBase {
  final List<AchievementTier> tiers;

  TieredAchievement({
    required super.id,
    required super.title,
    required super.icon,
    required this.tiers,
  });
}

// Mantemos o modelo antigo para conquistas de nível único.
class SingleAchievement extends AchievementBase {
  final String description;
  final bool Function(List<Book> readBooks) check;

  SingleAchievement({
    required super.id,
    required super.title,
    required super.icon,
    required this.description,
    required this.check,
  });
}