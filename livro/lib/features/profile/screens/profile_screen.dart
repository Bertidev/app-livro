import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/core/services/storage_service.dart';
import 'package:livro/features/achievements/screens/achievements_screen.dart';
import 'package:livro/features/auth/services/auth_service.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final BookshelfService _bookshelfService = BookshelfService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Abre a galeria para o usuário escolher uma nova foto e faz o upload.
  Future<void> _changeProfilePicture() async {
    final downloadUrl = await _storageService.uploadProfileImage();
    if (downloadUrl != null) {
      await _authService.updateUserProfilePicture(downloadUrl);
    }
  }

  /// Mostra um diálogo para o usuário definir ou editar sua meta de leitura anual.
  void _showSetGoalDialog(int currentGoal) {
    final goalController = TextEditingController(text: currentGoal > 0 ? currentGoal.toString() : '');
    final currentYear = DateTime.now().year;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Meta de Leitura $currentYear'),
          content: TextField(
            controller: goalController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Quantos livros você quer ler?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final goal = int.tryParse(goalController.text);
                if (goal != null && goal > 0) {
                  _authService.setReadingGoal(goal);
                }
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      // StreamBuilder principal que ouve os dados do documento do usuário (nome, foto, meta)
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return const Center(child: Text('Não foi possível carregar os dados do perfil.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = userData['photoUrl'] as String?;
          final username = userData['username'] as String?;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeProfilePicture,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.camera_alt, size: 30) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(username ?? 'Usuário', style: Theme.of(context).textTheme.headlineMedium),
                  Text(currentUser?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  
                  // StreamBuilder aninhado que ouve os dados da estante (para as estatísticas)
                  StreamBuilder<List<Book>>(
                    stream: _bookshelfService.getBookshelfStream(),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Lidos', readCount.toString()),
                              _buildStatCard('Lendo', readingCount.toString()),
                              _buildStatCard('Quero Ler', wantToReadCount.toString()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Botão para a tela de conquistas
                          ListTile(
                            leading: Icon(Icons.emoji_events_rounded, color: Colors.amber[700]),
                            title: const Text('Minhas Conquistas'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                              );
                            },
                          ),
                          const Divider(),
                          
                          // Seção do Desafio de Leitura Anual
                          _buildReadingChallengeSection(userData, allBooks),
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

  /// Constrói um cartão de estatística.
  Widget _buildStatCard(String title, String value) {
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

  /// Constrói a seção do Desafio de Leitura Anual.
  Widget _buildReadingChallengeSection(Map<String, dynamic> userData, List<Book> allBooks) {
    final year = DateTime.now().year.toString();
    final goals = userData['readingGoals'] as Map<String, dynamic>?;
    final goal = goals?[year] as int? ?? 0;

    if (goal == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ElevatedButton(
            onPressed: () => _showSetGoalDialog(0),
            child: Text('Definir Meta de Leitura para ${DateTime.now().year}'),
          ),
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
          title: Text('Desafio de Leitura ${DateTime.now().year}', style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('Meta: $goal livros'),
          trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showSetGoalDialog(goal)),
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
          const Text('Comece a ler para preencher seu desafio!')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: booksReadThisYear.map((book) {
              return SizedBox(
                width: 60,
                child: book.thumbnailUrl.isNotEmpty
                  ? Image.network(book.thumbnailUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey, child: const Icon(Icons.book, color: Colors.white)),
              );
            }).toList(),
          ),
      ],
    );
  }
}