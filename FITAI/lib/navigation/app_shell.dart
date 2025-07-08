// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
// import 'package:hk11/pages/profile_page_.dart'; // Remove or comment this line
import 'package:hk11/pages/journal_page.dart'; // Add this import
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

  // Replace ProfileScreen with JournalPage in the pages list
  final List<Widget> _pages = const [MyHomePage(), ChatPage(), JournalPage()];

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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _currentPage,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.secondary,
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
              icon: Icon(
                Icons.book_outlined,
              ), // Changed from person_outline to book_outlined
              activeIcon: Icon(Icons.book), // Changed from person to book
              label: 'Journal', // Changed from empty to 'Journal'
            ),
          ],
        ),
      ),
    );
  }
}
