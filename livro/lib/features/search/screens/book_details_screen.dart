import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/bookshelf/services/bookshelf_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final BookshelfService _bookshelfService = BookshelfService();
  
  Book? _shelfBook;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _fetchBookDataFromShelf();
  }

  Future<void> _fetchBookDataFromShelf() async {
    final bookStream = _bookshelfService.getBookshelfStream();
    bookStream.listen((books) {
      if (mounted) {
        setState(() {
          try {
            _shelfBook = books.firstWhere((b) => b.id == widget.book.id);
          } catch (e) {
            _shelfBook = null;
          }
          _isLoadingStatus = false;
        });
      }
    });
  }

  Future<void> _handleShelfButtonTap(String status) async {
    final currentStatus = _shelfBook?.status;
    if (currentStatus == status) {
      await _bookshelfService.removeBookFromShelf(widget.book.id, context);
    } else {
      await _bookshelfService.addBookToShelf(widget.book, status, context);
    }
  }
  
  void _showRatingDialog() {
    int currentRating = _shelfBook?.rating ?? 0;
    final reviewController = TextEditingController(text: _shelfBook?.review ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Avalie este livro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            index < currentRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              currentRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Escreva sua resenha (opcional)',
                        border: OutlineInputBorder(),
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
                    if (currentRating > 0) {
                      _bookshelfService.rateBook(
                        widget.book.id,
                        currentRating,
                        reviewController.text.trim(),
                        context
                      );
                    }
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: screenSize.height * 0.35,
                child: widget.book.thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.book.thumbnailUrl,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Icon(Icons.book, size: 80)),
                      ),
              ),
              const SizedBox(height: 24),
              Text(widget.book.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.book.authors.join(', '), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 24),
              _isLoadingStatus
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShelfButton(context, icon: Icons.bookmark_add_outlined, label: 'Quero Ler'),
                        _buildShelfButton(context, icon: Icons.menu_book_outlined, label: 'Lendo'),
                        _buildShelfButton(context, icon: Icons.check_circle_outline, label: 'Lido'),
                      ],
                    ),
              const SizedBox(height: 24),
              if (_shelfBook?.status == 'Lido') ...[
                _buildUserReviewSection(),
                const SizedBox(height: 24),
              ],
              const Divider(),
              const SizedBox(height: 16),
              Text('Descrição', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                widget.book.description,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserReviewSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.rate_review_outlined),
          title: const Text('Sua Avaliação'),
          subtitle: _shelfBook?.rating != null
              ? Row(
                  children: List.generate(5, (index) => Icon(
                    index < _shelfBook!.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                )
              : const Text('Ainda não avaliado'),
          trailing: OutlinedButton(
            onPressed: _showRatingDialog,
            child: Text(_shelfBook?.rating != null ? 'Editar' : 'Avaliar'),
          ),
        ),
        if (_shelfBook?.review?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '"${_shelfBook!.review!}"',
              style: const TextStyle(fontStyle: FontStyle.italic)
            ),
          ),
      ],
    );
  }

  Widget _buildShelfButton(BuildContext context, {required IconData icon, required String label}) {
    final bool isActive = _shelfBook?.status == label;
    return Column(
      children: [
        isActive
            ? IconButton.filled(iconSize: 32, icon: Icon(icon), onPressed: () => _handleShelfButtonTap(label))
            : IconButton.filledTonal(iconSize: 32, icon: Icon(icon), onPressed: () => _handleShelfButtonTap(label)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}