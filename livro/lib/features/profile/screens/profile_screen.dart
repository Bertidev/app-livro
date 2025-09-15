import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/core/services/storage_service.dart';
import 'package:livro/features/auth/services/auth_service.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart'; // 1. Importe o BookshelfService

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final BookshelfService _bookshelfService = BookshelfService(); // 2. Crie uma instância do serviço
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _changeProfilePicture() async {
    final downloadUrl = await _storageService.uploadProfileImage();
    if (downloadUrl != null) {
      await _authService.updateUserProfilePicture(downloadUrl);
      // O StreamBuilder já cuidará de reconstruir a tela, então o setState não é estritamente necessário aqui, mas não prejudica.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      // O primeiro StreamBuilder ouve os dados do perfil (nome, foto)
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

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _changeProfilePicture,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username ?? 'Usuário',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    currentUser?.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  
                  // 3. SEGUNDO STREAMBUILDER PARA AS ESTATÍSTICAS DA ESTANTE
                  StreamBuilder<List<Book>>(
                    stream: _bookshelfService.getBookshelfStream(),
                    builder: (context, bookshelfSnapshot) {
                      if (bookshelfSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      // Calcula as estatísticas a partir dos dados recebidos
                      final allBooks = bookshelfSnapshot.data ?? [];
                      final readCount = allBooks.where((b) => b.status == 'Lido').length;
                      final readingCount = allBooks.where((b) => b.status == 'Lendo').length;
                      final wantToReadCount = allBooks.where((b) => b.status == 'Quero Ler').length;

                      // 4. Exibe as estatísticas em uma Row de cartões
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Lidos', readCount.toString()),
                          _buildStatCard('Lendo', readingCount.toString()),
                          _buildStatCard('Quero Ler', wantToReadCount.toString()),
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

  // 5. WIDGET AUXILIAR para criar os cartões de estatística
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
}