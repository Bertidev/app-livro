import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';
import 'package:livro/features/profile/services/follow_service.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Instanciamos os serviços que esta tela precisa
    final bookshelfService = BookshelfService();
    final followService = FollowService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Leitor'),
      ),
      // StreamBuilder principal que busca os dados do perfil do usuário visitado
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return const Center(child: Text('Este usuário não existe.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = userData['photoUrl'] as String?;
          final username = userData['username'] as String?;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(username ?? 'Usuário', style: Theme.of(context).textTheme.headlineMedium),
                  
                  const SizedBox(height: 16),
                  // Contadores de Seguidores e Seguindo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFollowerStat(context, followService.getFollowersCount(userId), 'Seguidores'),
                      const SizedBox(width: 32),
                      _buildFollowerStat(context, followService.getFollowingCount(userId), 'Seguindo'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botão dinâmico de Seguir/Deixar de Seguir
                  // Só aparece se não for o seu próprio perfil
                  if (currentUser != null && currentUser.uid != userId)
                    StreamBuilder<bool>(
                      stream: followService.isFollowing(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(height: 40); // Espaço para evitar pulo na UI
                        
                        final isFollowing = snapshot.data!;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
                              foregroundColor: isFollowing ? Colors.black87 : Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              if (isFollowing) {
                                followService.unfollowUser(userId);
                              } else {
                                followService.followUser(userId);
                              }
                            },
                            child: Text(isFollowing ? 'Deixar de Seguir' : 'Seguir'),
                          ),
                        );
                      }
                    ),

                  const SizedBox(height: 24),
                  
                  // StreamBuilder aninhado para buscar a estante do usuário visitado
                  StreamBuilder<List<Book>>(
                    stream: bookshelfService.getBookshelfStream(userId: userId),
                    builder: (context, bookshelfSnapshot) {
                      if (bookshelfSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      final allBooks = bookshelfSnapshot.data ?? [];
                      final readCount = allBooks.where((b) => b.status == 'Lido').length;
                      final readingCount = allBooks.where((b) => b.status == 'Lendo').length;
                      final wantToReadCount = allBooks.where((b) => b.status == 'Quero Ler').length;

                      return Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(context, 'Lidos', readCount.toString()),
                              _buildStatCard(context, 'Lendo', readingCount.toString()),
                              _buildStatCard(context, 'Quero Ler', wantToReadCount.toString()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          
                          // Mostra o desafio de leitura do usuário visitado
                          _buildReadingChallengeSection(context, userData, allBooks),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói o widget para os contadores de seguidores/seguindo.
  Widget _buildFollowerStat(BuildContext context, Stream<int> stream, String label) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          children: [
            Text(count.toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }
    );
  }
  
  /// Constrói um cartão de estatística (reutilizado da ProfileScreen).
  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Constrói a seção do Desafio de Leitura Anual (versão somente leitura).
  Widget _buildReadingChallengeSection(BuildContext context, Map<String, dynamic> userData, List<Book> allBooks) {
    final year = DateTime.now().year.toString();
    final goals = userData['readingGoals'] as Map<String, dynamic>?;
    final goal = goals?[year] as int? ?? 0;

    if (goal == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Este leitor não definiu uma meta para ${DateTime.now().year}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    
    final booksReadThisYear = allBooks.where((b) {
      return b.status == 'Lido' && b.finishedAt != null && b.finishedAt!.toDate().year == DateTime.now().year;
    }).toList();
    
    final progress = booksReadThisYear.isNotEmpty ? (booksReadThisYear.length / goal) : 0.0;

    return Column(
      children: [
        ListTile(
          title: Text('Desafio de Leitura $year', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('Meta: $goal livros'),
          // Sem o botão de editar
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text('${booksReadThisYear.length} de $goal livros concluídos (${(progress * 100).toStringAsFixed(0)}%)'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (booksReadThisYear.isEmpty)
          const Text('Nenhum livro concluído para o desafio ainda.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: booksReadThisYear.map((book) {
              return SizedBox(
                width: 60,
                child: book.thumbnailUrl.isNotEmpty
                  ? Image.network(book.thumbnailUrl, fit: BoxFit.cover)
                  : Container(
                      height: 90,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
              );
            }).toList(),
          ),
      ],
    );
  }
}