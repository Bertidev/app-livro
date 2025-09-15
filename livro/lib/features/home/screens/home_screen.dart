import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/features/bookshelf/screens/bookshelf_screen.dart'; // Importe a tela da estante
import 'package:livro/features/search/screens/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _navigateToBookshelf(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BookshelfScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.displayName ?? 'Bem-vindo!'),
        actions: [
          IconButton(
            onPressed: () => _navigateToSearch(context),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
              'Logado como:\n${user?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.book_sharp),
              label: const Text('Ver Minha Estante'),
              onPressed: () => _navigateToBookshelf(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}