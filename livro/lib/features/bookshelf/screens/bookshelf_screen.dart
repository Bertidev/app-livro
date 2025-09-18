import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';
import 'package:livro/features/search/screens/book_details_screen.dart';

class BookshelfScreen extends StatefulWidget {
  // 1. Adicionamos um novo parâmetro para o índice da aba inicial
  final int initialTabIndex;

  const BookshelfScreen({
    super.key,
    this.initialTabIndex = 0, // O valor padrão será 0 (primeira aba)
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
    // 2. Usamos o parâmetro para definir a aba inicial do controller
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

class _BookListView extends StatelessWidget {
  final List<Book> books;
  const _BookListView({required this.books});

  void _showUpdateProgressDialog(BuildContext context, Book book) {
    final progressController = TextEditingController(text: book.currentPage?.toString() ?? '0');
    final totalPagesController = TextEditingController(text: book.pageCount?.toString() ?? '');
    
    final bookshelfService = BookshelfService();
    bool isPercentageMode = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Atualizar Progresso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('%')),
                        ButtonSegment(value: false, label: Text('Pág.')),
                      ],
                      selected: {isPercentageMode},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          isPercentageMode = newSelection.first;
                          progressController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: progressController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: isPercentageMode ? 'Progresso em %' : 'Página atual',
                        hintText: isPercentageMode ? 'Ex: 50' : 'Ex: 125',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: totalPagesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total de páginas',
                        hintText: 'Ex: 350',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final progressValue = int.tryParse(progressController.text);
                    final totalPages = int.tryParse(totalPagesController.text);
                    int? newCurrentPage;

                    if (progressValue != null && totalPages != null && totalPages > 0) {
                      if (isPercentageMode) {
                        newCurrentPage = (progressValue / 100 * totalPages).round();
                      } else {
                        newCurrentPage = progressValue;
                      }
                    } else if (progressValue != null && !isPercentageMode) {
                        newCurrentPage = progressValue;
                    }
                    
                    bookshelfService.updateBookProgress(
                      book.id,
                      currentPage: newCurrentPage,
                      pageCount: totalPages,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
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