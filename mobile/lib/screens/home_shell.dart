import 'package:flutter/material.dart';

import 'favorites_screen.dart';
import 'history_screen.dart';
import 'search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    SearchScreen(),
    FavoritesScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
        ],
      ),
    );
  }
}
