import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/achievements/data/achievement_definitions.dart';
import 'package:livro/features/achievements/models/achievement_tier_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BookshelfService _bookshelfService = BookshelfService();

  Future<List<String>> checkAndUnlockAchievements() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final List<Book> readBooks = (await _bookshelfService.getBookshelfStream().first)
        .where((b) => b.status == 'Lido').toList();

    final unlockedSnapshot = await _firestore.collection('users').doc(currentUser.uid).collection('unlocked_achievements').get();
    final unlockedMap = { for (var doc in unlockedSnapshot.docs) doc.id : doc.data() };

    List<String> newlyUnlockedTitles = [];

    for (final achievementBase in achievementDefinitions) {
      if (achievementBase is SingleAchievement) {
        if (!unlockedMap.containsKey(achievementBase.id) && achievementBase.check(readBooks)) {
          await _unlockAchievement(currentUser.uid, achievementBase.id, achievementBase.title);
          newlyUnlockedTitles.add(achievementBase.title);
        }
      } else if (achievementBase is TieredAchievement) {
        final currentLevel = unlockedMap[achievementBase.id]?['level'] ?? 0;
        if (currentLevel < achievementBase.tiers.length) {
          final nextTier = achievementBase.tiers[currentLevel];
          if (nextTier.check(readBooks)) {
            await _unlockAchievement(currentUser.uid, achievementBase.id, achievementBase.title, level: nextTier.level);
            newlyUnlockedTitles.add('${achievementBase.title} Nível ${nextTier.level}');
          }
        }
      }
    }
    return newlyUnlockedTitles;
  }
  
  Future<void> _unlockAchievement(String userId, String achievementId, String title, {int? level}) {
    final dataToSet = {
      'title': title,
      'unlockedAt': Timestamp.now(),
      if (level != null) 'level': level,
    };
    return _firestore.collection('users').doc(userId).collection('unlocked_achievements').doc(achievementId).set(dataToSet);
  }

  Future<Map<String, dynamic>> getAchievementsData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'allAchievements': [], 'unlockedAchievements': <String, dynamic>{}};
    }

    final unlockedSnapshot = await _firestore.collection('users').doc(currentUser.uid).collection('unlocked_achievements').get();
    final unlockedMap = { for (var doc in unlockedSnapshot.docs) doc.id : doc.data() };

    // Adiciona a contagem de livros lidos para passar para a UI
    final List<Book> readBooks = (await _bookshelfService.getBookshelfStream().first)
        .where((b) => b.status == 'Lido').toList();

    return {
      'allAchievements': achievementDefinitions,
      'unlockedAchievements': unlockedMap,
      'readBooksCount': readBooks.length,
    };
  }
}