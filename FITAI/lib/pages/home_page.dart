import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import '../services/quotes_service.dart';
import 'workout_page.dart';
import 'meal_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Add Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add auth instance
  
  String _currentQuote = 'Loading quote...';
  String _userGoal = 'Loading goal...'; // Add goal state variable
  bool _isLoading = true;
  bool _isLoadingGoal = true; // Add loading state for goal
  
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
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text('FitAi'),
        
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              // First container with quote from Firebase
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.hintColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                height: 220,
                
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(

                        children: [
                          Icon(
                            Icons.format_quote,  // Quote icon
                            color: Colors.deepPurple,  // Changed from theme.colorScheme.secondary
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Quote',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.deepPurple,  // Changed from theme.colorScheme.secondary
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
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.hintColor.withOpacity(0.5),
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
                            Icons.flag, // Goal/target icon
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
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Text between containers
              
              SizedBox(height: 16),
              
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.hintColor.withOpacity(0.5),
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
                              Icons.fitness_center,  // Workout/fitness icon
                              color: theme.hintColor,  // Changed from theme.colorScheme.secondary
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Workout',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.hintColor,  // Changed from theme.colorScheme.secondary
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Text(
                          'Workout Routine',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MealPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.hintColor.withOpacity(0.5),
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
                              Icons.restaurant,  // Food/meal icon
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
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
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
