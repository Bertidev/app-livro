import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';

class BookDetailsScreen extends StatelessWidget {
  // A tela recebe um objeto 'Book' para exibir
  final Book book;

  final BookshelfService _bookshelfService = BookshelfService();

  BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para pegar o tamanho da tela e deixar a capa responsiva
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        // O título da barra será o título do livro
        title: Text(book.title),
      ),
      // SingleChildScrollView permite que a tela role se o conteúdo for muito grande
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- CAPA DO LIVRO ---
              SizedBox(
                height: screenSize.height * 0.35, // 35% da altura da tela
                child: book.thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book.thumbnailUrl,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.book, size: 80)),
                      ),
              ),
              const SizedBox(height: 24),

              // --- TÍTULO E AUTOR ---
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                // O método .join junta os itens de uma lista com um separador
                book.authors.join(', '),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),

              // --- BOTÕES DE AÇÃO (ESTANTES) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShelfButton(context, icon: Icons.bookmark_add_outlined, label: 'Quero Ler'),
                  _buildShelfButton(context, icon: Icons.menu_book_outlined, label: 'Lendo'),
                  _buildShelfButton(context, icon: Icons.check_circle_outline, label: 'Lido'),
                ],
              ),
              const SizedBox(height: 24),

              // --- DESCRIÇÃO ---
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Descrição',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                book.description,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para criar os botões da estante e evitar repetição de código
  Widget _buildShelfButton(BuildContext context, {required IconData icon, required String label}) {
    return Column(
      children: [
        IconButton.filledTonal(
          iconSize: 32,
          icon: Icon(icon),
           onPressed: () {
            // Chama o serviço para adicionar o livro com o status correspondente ao botão
            _bookshelfService.addBookToShelf(book, label, context);
          },
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}