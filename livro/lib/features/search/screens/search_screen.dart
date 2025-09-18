import 'package:flutter/material.dart';
import 'package:livro/core/models/book_model.dart';
import 'package:livro/features/profile/models/user_model.dart';
import 'package:livro/features/profile/screens/public_profile_screen.dart'; // Vamos criar a seguir
import 'package:livro/features/search/screens/book_details_screen.dart';
import 'package:livro/features/search/services/book_service.dart';
import 'package:livro/features/search/services/user_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar...',
            border: InputBorder.none,
          ),
          // O setState aqui notifica os widgets filhos da mudança no texto
          onChanged: (value) => setState(() {}),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Livros'),
            Tab(text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Passamos o controller para a busca de livros
          _BookSearchTab(searchQuery: _searchController.text),
          // E também para a busca de usuários
          _UserSearchTab(searchQuery: _searchController.text),
        ],
      ),
    );
  }
}

// --- WIDGET PARA A ABA DE BUSCA DE LIVROS ---
class _BookSearchTab extends StatefulWidget {
  final String searchQuery;
  const _BookSearchTab({required this.searchQuery});

  @override
  State<_BookSearchTab> createState() => _BookSearchTabState();
}

class _BookSearchTabState extends State<_BookSearchTab> {
  final BookService _bookService = BookService();
  Future<List<Book>>? _searchResults;

  @override
  void didUpdateWidget(covariant _BookSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o texto da busca mudou, inicia uma nova busca
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchResults = _bookService.searchBooks(widget.searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return const Center(child: Text('Digite para buscar livros.'));
    }

    return FutureBuilder<List<Book>>(
      future: _searchResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum livro encontrado.'));
        }
        
        final books = snapshot.data!;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              leading: book.thumbnailUrl.isNotEmpty ? Image.network(book.thumbnailUrl) : const Icon(Icons.book),
              title: Text(book.title),
              subtitle: Text(book.authors.join(', ')),
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)));
              },
            );
          },
        );
      },
    );
  }
}

// --- WIDGET PARA A ABA DE BUSCA DE USUÁRIOS ---
class _UserSearchTab extends StatefulWidget {
  final String searchQuery;
  const _UserSearchTab({required this.searchQuery});

  @override
  State<_UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<_UserSearchTab> {
  final UserSearchService _userSearchService = UserSearchService();
  Future<List<UserModel>>? _searchResults;

  @override
  void didUpdateWidget(covariant _UserSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchResults = _userSearchService.searchUsers(widget.searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return const Center(child: Text('Digite para buscar usuários.'));
    }

    return FutureBuilder<List<UserModel>>(
      future: _searchResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum usuário encontrado.'));
        }
        
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.username),
              subtitle: Text(user.email),
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: user.uid)));
              },
            );
          },
        );
      },
    );
  }
}