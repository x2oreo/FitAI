import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:hk11/pages/profile_page_.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/quotes_service.dart';
import 'workout_page.dart';
import 'meal_page.dart';
import 'package:hk11/providers/user_provider.dart';
import 'dart:ui';
import '../providers/home_data_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _currentQuote = 'Loading quote...';
  String _userGoal = 'Loading goal...';
  int _currentDayNum = 1;
  bool _isLoading = true;
  bool _isLoadingGoal = true;
  Map<String, dynamic>? userData;  // Add this line to store user data

  // Add these variables
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = false;

  // Add animation controller
  late AnimationController _animationController;
  late Animation<double> _appBarOpacity;

  // Add these variables near your other class variables 
  String _currentMealType = '';
  String _currentMealContent = '';
  bool _isMealLoading = true;

  // Add these variables near your other class variables
  String _currentWorkoutType = '';
  String _currentWorkoutContent = '';
  bool _isWorkoutLoading = true;

  @override
  void initState() {
    super.initState();
    // _loadQuote();
    // _fetchUserData();
    // _fetchCurrentMeal(); // Add this new method call
    // _fetchCurrentWorkout(); // Add this new method call
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000), // Adjust duration as needed
    );
    _appBarOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    // Add scroll listener
    _scrollController.addListener(_scrollListener);
    
    // Initialize data once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeDataProvider>(context, listen: false).initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  // Updated scroll listener function
  void _scrollListener() {
    // Use animation instead of boolean toggle
    if (_scrollController.offset > 100 && !_showAppBar) {
      setState(() {
        _showAppBar = true;
      });
      _animationController.forward(); // Start animation to show AppBar
    } else if (_scrollController.offset <= 100 && _showAppBar) {
      setState(() {
        _showAppBar = false;
      });
      _animationController.reverse(); // Reverse animation to hide AppBar
    }
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

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoadingGoal = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        userData = doc.data() as Map<String, dynamic>;  // Store the entire userData
        String goal = userData?['goal'] ?? '10.000 steps';
        Timestamp? createdAtTimestamp = userData?['createdAt'] as Timestamp?;
        int storedDayNum = userData?['dayNum'] ?? 1;

        int calculatedDayNum = 1;
        if (createdAtTimestamp != null) {
          DateTime createdAt = createdAtTimestamp.toDate();
          DateTime now = DateTime.now();
          int daysDifference = now.difference(createdAt).inDays;
          calculatedDayNum = (daysDifference % 7) + 1;
        }

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
          _userGoal = '10.000 steps';
          _currentDayNum = 1;
        });
      }
    } catch (e) {
      setState(() {
        _userGoal = '10.000 steps';
        _currentDayNum = 1;
      });
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoadingGoal = false;
      });
    }
  }

  // Add this new method to determine meal time and fetch content
  Future<void> _fetchCurrentMeal() async {
    setState(() {
      _isMealLoading = true;
    });
    
    try {
      print("------ MEAL DEBUG START ------");
      print("Current time: ${DateTime.now()}");
      
      // Determine current meal type based on time of day
      final now = DateTime.now();
      final hour = now.hour;
      
      if (hour >= 5 && hour < 11) {
        _currentMealType = "Breakfast";
      } else if (hour >= 11 && hour < 16) {
        _currentMealType = "Lunch";
      } else if (hour >= 16 && hour < 22) {
        _currentMealType = "Dinner";
      } else {
        _currentMealType = "Late Night Snack";
      }
      
      print("Selected meal type: $_currentMealType");
      
      // Fetch meal plan data
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      print("Fetching data for user: $userId, day: $_currentDayNum");
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('diet')
          .get();
      
      if (doc.exists) {
        print("Diet document exists");
        Map<String, dynamic> dietPlan = doc.data() as Map<String, dynamic>;
        
        String dayKey = 'day$_currentDayNum';
        print("Looking for day key: $dayKey");
        
        if (dietPlan.containsKey(dayKey)) {
          print("Day key found");
          var dayData = dietPlan[dayKey];
          
          print("Data type: ${dayData.runtimeType}");
          
          if (dayData is String) {
            print("Data is String, length: ${dayData.length}");
            print("First 100 chars: ${dayData.substring(0, min(100, dayData.length))}");
            
            // Updated regex pattern to better match your **MealType:** format
            final pattern = r'\*\*' + _currentMealType + r':\*\*(.*?)(?=\*\*\w+:|$)';
            print("Using regex pattern: $pattern");
            
            RegExp mealRegex = RegExp(
              pattern,
              caseSensitive: false,
              multiLine: true,
              dotAll: true,
            );
            
            Match? match = mealRegex.firstMatch(dayData);
            if (match != null) {
              print("Regex match found!");
              // Extract just the content part, not the heading
              _currentMealContent = match.group(1)?.trim() ?? 'No details available';
              print("Raw match content: $_currentMealContent");
            } else {
              print("NO REGEX MATCH FOUND!");
              _currentMealContent = "Details for $_currentMealType not found in your meal plan.";
            }
          } 
          // Replace your existing meal extraction logic with this specific version:

else if (dayData is Map) {
  print("Data is Map with keys: ${dayData.keys.toList()}");
  
  // Extract plan data from the Map (the key is 'plan')
  if (dayData.containsKey('plan')) {
    var planData = dayData['plan'];
    print("Plan data type: ${planData.runtimeType}");
    
    if (planData is String) {
      // Print the first part of the plan to debug the format
      print("Plan content sample: ${planData.length > 200 ? planData.substring(0, 200) + '...' : planData}");
      
      // Debug what meal sections are available
      final allMeals = RegExp(r'\*\*(\w+\s*\w*)\*\*').allMatches(planData).map((m) => m.group(1)).toList();
      print("Available meals in the plan: $allMeals");
      
      // Create a regex pattern that matches exactly how your meals are formatted
      final pattern = r'\*\*' + _currentMealType + r'\*\*\s*([\s\S]*?)(?=\*\*\w+(?:\s+\w+)?\*\*|$)';
      print("Using improved pattern: $pattern");
      
      RegExp mealRegex = RegExp(
        pattern,
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
      
      Match? match = mealRegex.firstMatch(planData);
      if (match != null && match.groupCount >= 1) {
        // Add additional debugging
        print("Match groups: ${match.groupCount}");
        for (int i = 0; i <= match.groupCount; i++) {
          print("Group $i: ${match.group(i)?.length ?? 0} chars");
        }
        
        String rawContent = match.group(1) ?? '';
        print("Raw content first 50 chars: ${rawContent.length > 50 ? rawContent.substring(0, 50) : rawContent}");
        
        _currentMealContent = rawContent.trim();
        
        // If we still have empty content, try fallback approach
        if (_currentMealContent.isEmpty) {
          print("Empty content detected, trying fallback approach");
          // Look for lines after Dinner heading in the complete plan
          final lines = planData.split('\n');
          bool capturingContent = false;
          List<String> mealLines = [];
          
          for (String line in lines) {
            if (line.toLowerCase().contains("**" + _currentMealType.toLowerCase() + "**")) {
              capturingContent = true;
              continue; // Skip the heading line
            } else if (capturingContent && line.contains("**") && RegExp(r'\*\*\w+\*\*').hasMatch(line)) {
              break; // Stop when we hit the next meal heading
            }
            
            if (capturingContent) {
              mealLines.add(line);
            }
          }
          
          _currentMealContent = mealLines.join('\n').trim();
          print("Fallback content length: ${_currentMealContent.length}");
        }
      } else {
        // Check if there's a close match (e.g., "Morning Snack" vs "Snack")
        if (_currentMealType == "Snack") {
          // Try alternate meal names
          final alternateNames = ["Morning Snack", "Afternoon Snack"];
          for (final name in alternateNames) {
            final altPattern = r'\*\*' + name + r'\*\*([\s\S]*?)(?=\*\*\w+(?:\s+\w+)?\*\*|$)';
            RegExp altRegex = RegExp(
              altPattern,
              caseSensitive: false,
              multiLine: true,
              dotAll: true,
            );
            
            Match? altMatch = altRegex.firstMatch(planData);
            if (altMatch != null && altMatch.groupCount >= 1) {
              _currentMealContent = "**$name**" + (altMatch.group(1)?.trim() ?? '');
              print("Alternate match found for $name");
              print("Content preview: ${_currentMealContent.substring(0, min(50, _currentMealContent.length))}...");
              break;
            }
          }
        } else {
          print("No match found for $_currentMealType");
          _currentMealContent = "Details for $_currentMealType not found in your meal plan.";
        }
      }
    } else {
      _currentMealContent = "Your meal plan format isn't recognized.";
    }
  } else {
    _currentMealContent = "No meal plan data found for today.";
  }
}
        } else {
          print("Day key NOT found. Available keys: ${dietPlan.keys.toList()}");
          _currentMealContent = "No meal plan found for today (Day $_currentDayNum).";
        }
      } else {
        print("Diet document does NOT exist");
        _currentMealContent = "No meal plan found. Generate one from the Meal Plan page.";
      }
    } catch (e, stackTrace) {
      print("ERROR in meal fetch: $e");
      print("Stack trace: $stackTrace");
      _currentMealContent = "Error loading meal plan: ${e.toString()}";
    } finally {
      setState(() {
        _isMealLoading = false;
      });
      print("------ MEAL DEBUG END ------");
    }
  }

  // Simplified workout fetching - doesn't process plan data

Future<void> _fetchCurrentWorkout() async {
  setState(() {
    _isWorkoutLoading = true;
  });
  
  try {
    print("------ WORKOUT DEBUG START ------");
    
    // Determine current workout type based on day of week
    List<String> workoutTypes = [
      "Strength Training",
      "Cardio",
      "Flexibility & Balance",
      "HIIT",
      "Core & Abs",
      "Full Body",
      "Rest Day"
    ];
    
    // Default workout type from preset list
    _currentWorkoutType = workoutTypes[_currentDayNum - 1];
    print("Default workout type: $_currentWorkoutType");
    
    // Fetch just the workout day data
    String userId = _auth.currentUser?.uid ?? 'anonymous_user';
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('plans')
        .doc('workout')
        .get();
    
    if (doc.exists) {
      print("Workout document exists");
      Map<String, dynamic> workoutPlan = doc.data() as Map<String, dynamic>;
      
      String dayKey = 'day$_currentDayNum';
      if (workoutPlan.containsKey(dayKey)) {
        print("Day key found");
        var dayData = workoutPlan[dayKey];
        
        // Try to extract just the workout title if available
        if (dayData is Map && dayData.containsKey('plan')) {
          var planData = dayData['plan'];
          if (planData is String) {
            // Extract only the workout title from "### Day X: [Title]" format
            final dayTitlePattern = r'### Day ' + _currentDayNum.toString() + r': ([^\n]+)';
            final dayTitleMatch = RegExp(dayTitlePattern).firstMatch(planData);
            
            if (dayTitleMatch != null && dayTitleMatch.groupCount >= 1) {
              _currentWorkoutType = dayTitleMatch.group(1)?.trim() ?? _currentWorkoutType;
              print("Extracted workout type from title: $_currentWorkoutType");
            }
          }
        }
        
        // Don't process the detailed plan data, just use a standard message
        _currentWorkoutContent = "";  // Empty string instead of the "Tap to see..." message
      } 
    } else {
      _currentWorkoutContent = "No workout plan found. Generate one from the Workout page.";
    }
  } catch (e) {
    print("ERROR in workout fetch: $e");
    _currentWorkoutContent = "Error loading workout";
  } finally {
    setState(() {
      _isWorkoutLoading = false;
    });
    print("------ WORKOUT DEBUG END ------");
  }
}

  // Function to extract all workout types from a workout plan document
  Future<List<String>> getWorkoutTypes() async {
    List<String> workoutTypes = [];
    
    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('workout')
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> workoutPlan = doc.data() as Map<String, dynamic>;
        
        // For each day, extract the workout type
        for (int i = 1; i <= 7; i++) {
          String dayKey = 'day$i';
          if (workoutPlan.containsKey(dayKey)) {
            var dayData = workoutPlan[dayKey];
            
            if (dayData is Map && dayData.containsKey('plan')) {
              var planData = dayData['plan'];
              
              if (planData is String) {
                // Extract workout title using regex
                final dayTitlePattern = r'### Day ' + i.toString() + r': ([^\n]+)';
                final dayTitleMatch = RegExp(dayTitlePattern).firstMatch(planData);
                
                if (dayTitleMatch != null && dayTitleMatch.groupCount >= 1) {
                  String workoutType = dayTitleMatch.group(1)?.trim() ?? '';
                  if (workoutType.isNotEmpty) {
                    workoutTypes.add(workoutType);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching workout types: $e");
    }
    
    return workoutTypes;
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<HomeDataProvider>(
      builder: (context, homeData, child) {
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          
          // Conditional AppBar based on scroll position
          appBar: _showAppBar 
            ? PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.5),
                      centerTitle: true,
                      title: Text(
                        "Home",
                        style: theme.textTheme.bodyLarge
                      ),
                      actions: [],
                    ),
                  ),
                ),
              ) 
            : PreferredSize(
                preferredSize: Size.fromHeight(0),
                child: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
                  ),
                ),
              ),
          
          body: Stack(
            children: [
              // Scrollable content
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [
                            Color(0xFF250050), // Dark purple
                            Color(0xFF160132), // Medium dark purple
                            Color(0xFF14022d), // Dark purple/indigo
                            Color(0xFF0e021d), // Very dark purple
                            Color(0xFF040109), // Almost black
                            Color(0xFF000000), // Black 
                          ]
                        : [
                            Color.fromARGB(255, 143, 143, 143), // Dark gray
                            Color(0xFF868686), // Darker medium gray
                            Color(0xFF9e9e9e), // Medium gray
                            Color(0xFFb6b6b6), // Medium gray
                            Color(0xFFcbcbcb), // Light/medium gray
                            Color(0xFFdcdcdc), // Light gray
                            Color(0xFFeeeeee), // Very light gray
                            Color(0xFFffffff), // White
                          ],
                    
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController, // Use the scroll controller here
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22, top: 60, left: 22, bottom: 22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Home text on the left side
                            Text(
                              "Home",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 34,
                              ),
                            ),
                            
                            // Avatar on the right side (keep existing code)
                            Consumer<UserProvider>(
                              builder: (context, userProvider, child) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      isDismissible: true,
                                      enableDrag: false, // Disable dragging
                                      builder: (context) => Container(
                                        height: MediaQuery.of(context).size.height * 0.85, // Increased from 0.6 to 0.85 (85% of screen)
                                        margin: EdgeInsets.only(top: 50), // Reduced top margin to allow more space for profile
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.background,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          child: ProfileScreen(
                                            scrollController: ScrollController(), // Provide a basic scroll controller
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    child: userProvider.getAvatarWidget(24),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Quote container (replaced BlurTheme)
                        Container(
                          decoration: BoxDecoration(
                            
                            borderRadius: BorderRadius.circular(16),
                            
                            color: theme.colorScheme.primary.withOpacity(0.9),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            height: 270,
                            width: double.infinity,
                            
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Icon(
                                    Icons.format_quote,
                                    color: Colors.deepPurpleAccent,
                                    size: 30,
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Icon(
                                    Icons.format_quote,
                                    color: Colors.deepPurple,
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
                                    
                                    child: Row(
                                      children: [
                                        
                                        SizedBox(width: 4),
                                        Text(
                                          'Quote',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: Colors.deepPurple,
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
                                    child: homeData.isQuoteLoading
                                        ? CircularProgressIndicator()
                                        : Container(
                                          constraints: BoxConstraints(
                                            minHeight: 120,
                                          ),
                                          child: Center(
                                            child: Text(
                                            homeData.quote,
                                            style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                            ),
                                          ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.primary.withOpacity(0.9),
                            
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 15,
                                  bottom: 15,
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.orangeAccent.withOpacity(0.5),
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
                                  alignment: Alignment.center,
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
                                        homeData.isGoalLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                homeData.userGoal,
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.bold,
                                                      
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

                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "My Plans",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                            
                          ],
                        ),
                        SizedBox(height: 16),
                        // Change from Row to Column for Workout and Meal containers
                        Column(
                          children: [
                            // Workout container (now full width)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const WorkoutPage()),
                                );
                              },
                              child: Container(
                                height: 150, // Match the meal container height
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.primary.withOpacity(0.9),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header row with label and day indicator
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          color: theme.colorScheme.error,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Workout',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: theme.colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      child: Text(
                                        'DAY $_currentDayNum',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 8),
                                
                                // Workout type heading
                                Text(
                                  homeData.workoutType,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                
                                // Workout content
                                
                                
                                // View more indicator
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View full workout plan',
                                          style: theme.textTheme.bodySmall
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: theme.colorScheme.secondary.withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16), // Space between containers
                        
                        // Meal container (now full width)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MealPage()),
                            );
                          },
                          child: Container(
                            height: 235, // Taller container for more content
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: theme.colorScheme.primary.withOpacity(0.9),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with label and day indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          color: const Color.fromARGB(255, 58, 196, 129),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Meal',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: const Color.fromARGB(255, 58, 196, 129),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'DAY ${homeData.currentDayNum}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 8),
                                
                                // Meal type heading
                                Text(
                                  homeData.mealType,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                
                                Divider(height: 16, color: theme.colorScheme.secondary.withOpacity(0.3)),
                                
                                // Meal content
                                Expanded(
                                  child: homeData.isMealLoading
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: const Color.fromARGB(255, 58, 196, 129),
                                            ),
                                            SizedBox(height: 8),
                                            Text('Loading your meal...', style: theme.textTheme.bodyMedium),
                                          ],
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        child: homeData.mealContent.contains("not found") 
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  homeData.mealContent,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                          )
                                          : Text(
                                              homeData.mealContent.replaceAll('*', ''),
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                      ),
                                ),
                                
                                // View more indicator
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View full meal plan',
                                          style: theme.textTheme.bodySmall
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: theme.colorScheme.secondary.withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      }
  );
  
  }
  
}
