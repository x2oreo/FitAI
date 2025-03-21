// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hk11/pages/calendar_page.dart';
import 'package:hk11/pages/profile_page_.dart';
import '../pages/home_page.dart';
import '../pages/chat_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  Widget _currentPage = const MyHomePage();

  // List of main pages to navigate between
  final List<Widget> _pages = const [MyHomePage(), ChatPage(), ProfileScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentPage = _pages[index];
    });
  }

  void navigateTo(Widget page) {
    setState(() {
      _currentPage = page;
    });
  }

  void goToMainPage(int index) {
    setState(() {
      _selectedIndex = index;
      _currentPage = _pages[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.hintColor,
        unselectedItemColor: theme.listTileTheme.iconColor?.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}
