import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';
import 'package:livro/features/search/screens/book_details_screen.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> with SingleTickerProviderStateMixin {
  final BookshelfService _bookshelfService = BookshelfService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Estante'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quero Ler'),
            Tab(text: 'Lendo'),
            Tab(text: 'Lido'),
          ],
        ),
      ),
      // StreamBuilder vai ouvir as atualizações do serviço e reconstruir a tela
      body: StreamBuilder<List<Book>>(
        stream: _bookshelfService.getBookshelfStream(),
        builder: (context, snapshot) {
          // Estado de Carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado de Erro
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro ao carregar seus livros.'));
          }
          // Sem dados ou lista vazia
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sua estante está vazia.\nAdicione livros pela busca!', textAlign: TextAlign.center));
          }

          // Temos os dados! Vamos filtrar para cada aba.
          final allBooks = snapshot.data!;
          final wantToRead = allBooks.where((b) => b.status == 'Quero Ler').toList();
          final reading = allBooks.where((b) => b.status == 'Lendo').toList();
          final read = allBooks.where((b) => b.status == 'Lido').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookListView(books: wantToRead),
              _BookListView(books: reading),
              _BookListView(books: read),
            ],
          );
        },
      ),
    );
  }
}

// Widget auxiliar para exibir a lista de livros, evitando repetição de código
class _BookListView extends StatelessWidget {
  final List<Book> books;
  const _BookListView({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('Nenhum livro nesta estante.'));
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: book.thumbnailUrl.isNotEmpty
              ? Image.network(book.thumbnailUrl)
              : const Icon(Icons.book),
          title: Text(book.title),
          subtitle: Text(book.authors.join(', ')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(book: book),
              ),
            );
          },
        );
      },
    );
  }
}