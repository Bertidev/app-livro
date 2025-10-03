import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';
import 'package:livro/features/bookshelf/widgets/update_progress_dialog.dart';
import 'package:livro/features/search/screens/book_details_screen.dart';

class BookshelfScreen extends StatefulWidget {
  final int initialTabIndex;

  const BookshelfScreen({
    super.key,
    this.initialTabIndex = 0, // O valor padrão é a primeira aba
  });

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> with SingleTickerProviderStateMixin {
  final BookshelfService _bookshelfService = BookshelfService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Usa o parâmetro do widget para definir a aba inicial do controller
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      body: StreamBuilder<List<Book>>(
        stream: _bookshelfService.getBookshelfStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro ao carregar seus livros.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sua estante está vazia.\nAdicione livros pela busca!', textAlign: TextAlign.center));
          }

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

/// Widget auxiliar para exibir a lista de livros em cada aba.
class _BookListView extends StatelessWidget {
  final List<Book> books;
  const _BookListView({required this.books});

  /// Chama o diálogo reutilizável para atualizar o progresso.
  void _showUpdateProgressDialog(BuildContext context, Book book) async {
    final result = await showDialog<Map<String, int?>>(
      context: context,
      builder: (context) => UpdateProgressDialog(book: book),
    );

    // Se o usuário salvou os dados no diálogo, o resultado não será nulo
    if (result != null) {
      BookshelfService().updateBookProgress(
        book.id,
        currentPage: result['currentPage'],
        pageCount: result['pageCount'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('Nenhum livro nesta estante.'));
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        Widget? trailing;
        Widget? subtitle;

        // Lógica para a estante "Lendo"
        if (book.status == 'Lendo' && book.pageCount != null && book.pageCount! > 0) {
          final currentPage = book.currentPage ?? 0;
          final totalPages = book.pageCount!;
          final progress = (currentPage / totalPages).clamp(0.0, 1.0);
          
          subtitle = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.authors.join(', ')),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text('Página $currentPage de $totalPages (${(progress * 100).toStringAsFixed(0)}%)'),
            ],
          );

          trailing = IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => _showUpdateProgressDialog(context, book),
          );
        } else {
          // Comportamento padrão para as outras estantes
          subtitle = Text(book.authors.join(', '));
        }

        return ListTile(
          leading: book.thumbnailUrl.isNotEmpty
              ? Image.network(book.thumbnailUrl)
              : const Icon(Icons.book),
          title: Text(book.title),
          subtitle: subtitle,
          trailing: trailing,
          isThreeLine: book.status == 'Lendo' && book.pageCount != null && book.pageCount! > 0,
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