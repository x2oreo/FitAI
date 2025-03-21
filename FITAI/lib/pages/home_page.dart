import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/quotes_service.dart';
import '../theme/theme.dart'; // Ensure the theme import is present
import 'workout_page.dart';
import 'meal_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add auth instance

  String _currentQuote = 'Loading quote...';
  String _userGoal = 'Loading goal...'; // Add goal state variable
  bool _isLoading = true;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _fetchUserGoal(); // Add goal fetching
  }

  Future<void> _loadQuote() async {
    try {
      final quote = await _quotesService.getRandomQuote();
      setState(() {
        _currentQuote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentQuote = 'Failed to load quote';
        _isLoading = false;
      });
    }
  }

  // Add method to fetch user goal
  Future<void> _fetchUserGoal() async {
    setState(() {
      _isLoadingGoal = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String goal = userData['goal'] ?? '10.000 steps';
        setState(() {
          _userGoal = goal;
        });
      } else {
        setState(() {
          _userGoal = '10.000 steps'; // Default value if no data
        });
      }
    } catch (e) {
      setState(() {
        _userGoal = '10.000 steps'; // Default on error
      });
      print('Error fetching user goal: $e');
    } finally {
      setState(() {
        _isLoadingGoal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: isDarkMode ? Alignment.topLeft : Alignment.topRight,
            radius: 1.3,
            colors: isDarkMode 
              ? [
                  Color.fromARGB(255, 27, 105, 48), // Light green
                  Color.fromARGB(255, 15, 28, 33), // Dark green/blue
                ]
              : [
                  Color.fromARGB(255, 61, 238, 135), // Light green
                  Color.fromARGB(255, 142, 224, 209), // Dark green/blue
                ],
            stops: [0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              
              // Quote container with blur
              BlurTheme.applyBlur(
                context: context,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Quote',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.blue,
                                
                              ),
                              
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isLoading
                            ? CircularProgressIndicator()
                            : Text(
                                _currentQuote,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Goal container with blur
              BlurTheme.applyBlur(
                context: context,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Goal',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 8),
                            _isLoadingGoal 
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _userGoal,
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontSize: 28,
                                    color: Colors.white,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Workout container with blur
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: BlurTheme.applyBlur(
                  context: context,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: theme.hintColor,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Workout',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            'Workout Routine',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 28
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),
              
              // Meal plan container with blur
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MealPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: BlurTheme.applyBlur(
                  context: context,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Meal',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            'Meal Plan',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 28
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ));
  }
}
