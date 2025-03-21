import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
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
  int _currentDayNum = 1; // Add day number state variable
  bool _isLoading = true;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _fetchUserData(); // Renamed method to fetch all user data
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

  // Updated method to fetch user data including goal and day number
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoadingGoal = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Get user goal
        String goal = userData['goal'] ?? '10.000 steps';

        // Get created date and calculate day number
        Timestamp? createdAtTimestamp = userData['createdAt'] as Timestamp?;
        int storedDayNum = userData['dayNum'] ?? 1;

        // Calculate current day in the 7-day cycle
        int calculatedDayNum = 1;
        if (createdAtTimestamp != null) {
          DateTime createdAt = createdAtTimestamp.toDate();
          DateTime now = DateTime.now();

          // Calculate days difference
          int daysDifference = now.difference(createdAt).inDays;
          calculatedDayNum = (daysDifference % 7) + 1; // Day 1-7 in cycle
        }

        // Update day number in Firestore if it changed
        if (calculatedDayNum != storedDayNum) {
          await _firestore.collection('users').doc(userId).update({
            'dayNum': calculatedDayNum,
          });
        }

        setState(() {
          _userGoal = goal;
          _currentDayNum = calculatedDayNum;
        });
      } else {
        setState(() {
          _userGoal = '10.000 steps'; // Default value if no data
          _currentDayNum = 1;
        });
      }
    } catch (e) {
      setState(() {
        _userGoal = '10.000 steps'; // Default on error
        _currentDayNum = 1;
      });
      print('Error fetching user data: $e');
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
            colors:
                isDarkMode
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
                SizedBox(height: 100),

                // Quote container with blur and gradient border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors:
                          isDarkMode
                              ? [
                                Colors.tealAccent.withOpacity(0.7),
                                Colors.blue.withOpacity(0.7),
                              ]
                              : [
                                Colors.blue.withOpacity(0.7),
                                Colors.purple.withOpacity(0.7),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2), // Space for gradient border
                  child: BlurTheme.applyBlur(
                    context: context,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          // Decorative elements
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Icon(
                              Icons.format_quote,
                              color: Colors.blue.withOpacity(0.3),
                              size: 30,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Icon(
                              Icons.format_quote,
                              color: Colors.blue.withOpacity(0.3),
                              size: 30,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                30.0,
                                48.0,
                                30.0,
                                30.0,
                              ),
                              child:
                                  _isLoading
                                      ? CircularProgressIndicator()
                                      : SingleChildScrollView(
                                        physics: BouncingScrollPhysics(),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight: 120,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _currentQuote,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontSize: 22,
                                                    color: Colors.white,
                                                    fontStyle: FontStyle.italic,
                                                    height:
                                                        1.4, // Adds line spacing
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 4,
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        offset: Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Goal container with blur and gradient border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors:
                          isDarkMode
                              ? [
                                Colors.orangeAccent.withOpacity(0.7),
                                Colors.deepOrangeAccent.withOpacity(0.7),
                              ]
                              : [
                                Colors.orange.withOpacity(0.7),
                                Colors.deepOrange.withOpacity(0.7),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2), // Space for gradient border
                  child: BlurTheme.applyBlur(
                    context: context,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          // Decorative elements
                          Positioned(
                            right: 15,
                            bottom: 15,
                            child: Icon(
                              Icons.star,
                              color: Colors.orangeAccent.withOpacity(0.3),
                              size: 40,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                40.0,
                                16.0,
                                8.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontSize: 24,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  offset: Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
                        border: Border.all(color: Colors.white, width: 1),
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
                                fontSize: 28,
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
                        border: Border.all(color: Colors.white, width: 1),
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
                                fontSize: 28,
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
      ),
    );
  }
}
