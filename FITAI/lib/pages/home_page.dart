import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('FITAI', style: theme.appBarTheme.titleTextStyle),
      
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            
            children: [
              Text("Daily Quote", style: theme.textTheme.bodyLarge),
              SizedBox(height: 16),
              // First container
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.listTileTheme.iconColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.listTileTheme.iconColor?.withOpacity(0.3) ?? Colors.grey,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Sample Quote',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Goal: ',
                    style: theme.textTheme.headlineLarge,
                  ),
                  SizedBox(width: 8), // Add spacing between the texts
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '10.000 steps',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              // Text between containers
              
              SizedBox(height: 16),
              Text('Work', style: theme.textTheme.bodyLarge),
              SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.listTileTheme.iconColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.listTileTheme.iconColor?.withOpacity(0.3) ?? Colors.grey,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Workout Routine',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

              SizedBox(height: 16),
              Text('Meal', style: theme.textTheme.bodyLarge),
              SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.listTileTheme.iconColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.listTileTheme.iconColor?.withOpacity(0.3) ?? Colors.grey,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Meal Plan',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
