import 'package:flutter/material.dart';
import 'package:livro/features/bookshelf/screens/bookshelf_screen.dart';
import 'package:livro/features/feed/screens/feed_screen.dart'; 
import 'package:livro/features/profile/screens/profile_screen.dart';
import 'package:livro/features/search/screens/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Reordenamos as telas para o Feed vir primeiro
  static const List<Widget> _screens = <Widget>[
    FeedScreen(),      // Aba 0: Feed
    SearchScreen(),    // Aba 1: Busca
    BookshelfScreen(), // Aba 2: Estante
    ProfileScreen(),   // Aba 3: Perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Adicionamos estas duas linhas para garantir que a barra de navegação fique bonita com 4 itens
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          // Reordenamos os itens para corresponder às telas
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed_outlined),
            activeIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Minha Estante',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}