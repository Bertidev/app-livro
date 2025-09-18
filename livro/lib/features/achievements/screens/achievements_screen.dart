import 'package:flutter/material.dart';
import 'package:livro/features/achievements/models/achievement_tier_model.dart';
import 'package:livro/features/achievements/services/achievement_service.dart';
import 'package:intl/intl.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  late Future<Map<String, dynamic>> _achievementsData;

  @override
  void initState() {
    super.initState();
    _achievementsData = _achievementService.getAchievementsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Conquistas')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _achievementsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar conquistas.'));
          }

          final allAchievements =
              snapshot.data!['allAchievements'] as List<AchievementBase>;
          final unlockedAchievements =
              snapshot.data!['unlockedAchievements'] as Map<String, dynamic>;
          final readBooksCount = snapshot.data!['readBooksCount'] as int;

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: allAchievements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              if (achievement is SingleAchievement) {
                return _buildSingleAchievementCard(
                  achievement,
                  unlockedAchievements,
                );
              } else if (achievement is TieredAchievement) {
                return _buildTieredAchievementCard(
                  achievement,
                  unlockedAchievements,
                  readBooksCount,
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildSingleAchievementCard(
    SingleAchievement achievement,
    Map<String, dynamic> unlocked,
  ) {
    final isUnlocked = unlocked.containsKey(achievement.id);
    final unlockedDate = isUnlocked
        ? DateFormat(
            'dd/MM/yyyy',
          ).format((unlocked[achievement.id]['unlockedAt']).toDate())
        : null;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        elevation: isUnlocked ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnlocked
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
          ),
        ),
        child: ListTile(
          leading: Icon(
            achievement.icon,
            size: 40,
            color: isUnlocked
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade600,
          ),
          title: Text(
            achievement.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.description),
              if (isUnlocked) ...[
                const SizedBox(height: 4),
                Text(
                  'Desbloqueado em: $unlockedDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          trailing: isUnlocked
              ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
              : const Icon(Icons.lock, color: Colors.grey, size: 30),
        ),
      ),
    );
  }

  Widget _buildTieredAchievementCard(
    TieredAchievement achievement,
    Map<String, dynamic> unlocked,
    int readBooksCount,
  ) {
    final currentLevel = unlocked[achievement.id]?['level'] ?? 0;
    final isMaxLevel = currentLevel == achievement.tiers.length;
    final nextTier = isMaxLevel
        ? achievement.tiers.last
        : achievement.tiers[currentLevel];

    // Calcula o progresso para o próximo nível (apenas para conquistas baseadas em contagem de livros)
    double progress = 0;
    String progressText = nextTier.description;
    if (achievement.id == 'VORACIOUS_READER') {
      final goal = int.parse(nextTier.description.split(' ')[1]);
      progress = (readBooksCount / goal).clamp(0.0, 1.0);
      progressText = '$readBooksCount / $goal livros';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  achievement.icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Nível atual: $currentLevel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isMaxLevel)
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 40,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMaxLevel)
              const Text(
                'Você atingiu o nível máximo!',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            else ...[
              Text(progressText, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
