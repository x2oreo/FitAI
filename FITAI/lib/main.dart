import 'package:flutter/material.dart';
import 'package:hk11/navigation/app_shell.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    )
    
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: themeProvider.theme,
      home: const AppShell(),
    );
  }
}


