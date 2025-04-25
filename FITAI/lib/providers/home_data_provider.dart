import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/services/quotes_service.dart';
import 'dart:math';

class HomeDataProvider with ChangeNotifier {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Data variables
  String _quote = 'Loading quote...';
  String _userGoal = 'Loading goal...';
  int _currentDayNum = 1;
  String _mealType = '';
  String _mealContent = '';
  String _workoutType = '';
  String _workoutContent = '';
  
  // Loading flags
  bool _isQuoteLoading = true;
  bool _isGoalLoading = true;
  bool _isMealLoading = true;
  bool _isWorkoutLoading = true;
  
  // Getters
  String get quote => _quote;
  String get userGoal => _userGoal;
  int get currentDayNum => _currentDayNum;
  String get mealType => _mealType;
  String get mealContent => _mealContent;
  String get workoutType => _workoutType;
  String get workoutContent => _workoutContent;
  
  bool get isQuoteLoading => _isQuoteLoading;
  bool get isGoalLoading => _isGoalLoading;
  bool get isMealLoading => _isMealLoading;
  bool get isWorkoutLoading => _isWorkoutLoading;
  
  // Initialize data
  Future<void> initializeData() async {
    // Only fetch data if it hasn't been loaded yet
    if (_isQuoteLoading) await loadQuote();
    if (_isGoalLoading) await fetchUserData();
    if (_isMealLoading) await fetchCurrentMeal();
    if (_isWorkoutLoading) await fetchCurrentWorkout();
  }
  
  // Implement the four data fetching methods here
  // Copy your existing methods but update the state variables
  // And use notifyListeners() instead of setState()
  
  Future<void> loadQuote() async {
    _isQuoteLoading = true;
    notifyListeners();
    
    try {
      final quote = await _quotesService.getRandomQuote();
      _quote = quote;
    } catch (e) {
      _quote = 'Failed to load quote';
    }
    
    _isQuoteLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchUserData() async {
    _isGoalLoading = true;
    notifyListeners();

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String goal = userData['goal'] ?? '10.000 steps';
        Timestamp? createdAtTimestamp = userData['createdAt'] as Timestamp?;
        int storedDayNum = userData['dayNum'] ?? 1;

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

        _userGoal = goal;
        _currentDayNum = calculatedDayNum;
      } else {
        _userGoal = '10.000 steps';
        _currentDayNum = 1;
      }
    } catch (e) {
      _userGoal = '10.000 steps';
      _currentDayNum = 1;
      print('Error fetching user data: $e');
    } 
    
    _isGoalLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchCurrentMeal() async {
    _isMealLoading = true;
    notifyListeners();
    
    try {
      // Determine current meal type based on time of day
      final now = DateTime.now();
      final hour = now.hour;
      
      if (hour >= 5 && hour < 11) {
        _mealType = "Breakfast";
      } else if (hour >= 11 && hour < 16) {
        _mealType = "Lunch";
      } else if (hour >= 16 && hour < 22) {
        _mealType = "Dinner";
      } else {
        _mealType = "Late Night Snack";
      }
      
      // Fetch meal plan data
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('diet')
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> dietPlan = doc.data() as Map<String, dynamic>;
        
        String dayKey = 'day$_currentDayNum';
        if (dietPlan.containsKey(dayKey)) {
          var dayData = dietPlan[dayKey];
          
          if (dayData is Map && dayData.containsKey('plan')) {
            var planData = dayData['plan'];
            
            if (planData is String) {
              // Debug what meal sections are available
              final allMeals = RegExp(r'\*\*(\w+\s*\w*)\*\*').allMatches(planData).map((m) => m.group(1)).toList();
              
              // Create a regex pattern that matches exactly how your meals are formatted
              final pattern = r'\*\*' + _mealType + r'\*\*\s*([\s\S]*?)(?=\*\*\w+(?:\s+\w+)?\*\*|$)';
              
              RegExp mealRegex = RegExp(
                pattern,
                caseSensitive: false,
                multiLine: true,
                dotAll: true,
              );
              
              Match? match = mealRegex.firstMatch(planData);
              if (match != null && match.groupCount >= 1) {
                String rawContent = match.group(1) ?? '';
                _mealContent = rawContent.trim();
              } else {
                _mealContent = "Details for $_mealType not found in your meal plan.";
              }
            } else {
              _mealContent = "Your meal plan format isn't recognized.";
            }
          } else {
            _mealContent = "No meal plan data found for today.";
          }
        } else {
          _mealContent = "No meal plan found for today (Day $_currentDayNum).";
        }
      } else {
        _mealContent = "No meal plan found. Generate one from the Meal Plan page.";
      }
    } catch (e) {
      _mealContent = "Error loading meal plan: ${e.toString()}";
    } finally {
      _isMealLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchCurrentWorkout() async {
    _isWorkoutLoading = true;
    notifyListeners();
    
    try {
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
      _workoutType = workoutTypes[_currentDayNum - 1];
      
      // Fetch just the workout day data
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('workout')
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> workoutPlan = doc.data() as Map<String, dynamic>;
        
        String dayKey = 'day$_currentDayNum';
        if (workoutPlan.containsKey(dayKey)) {
          var dayData = workoutPlan[dayKey];
          
          // Try to extract just the workout title if available
          if (dayData is Map && dayData.containsKey('plan')) {
            var planData = dayData['plan'];
            if (planData is String) {
              // Extract only the workout title from "### Day X: [Title]" format
              final dayTitlePattern = r'### Day ' + _currentDayNum.toString() + r': ([^\n]+)';
              final dayTitleMatch = RegExp(dayTitlePattern).firstMatch(planData);
              
              if (dayTitleMatch != null && dayTitleMatch.groupCount >= 1) {
                _workoutType = dayTitleMatch.group(1)?.trim() ?? _workoutType;
              }
            }
          }
          
          // Don't process the detailed plan data, just use a standard message
          _workoutContent = "";  // Empty string instead of the "Tap to see..." message
        } else {
          _workoutContent = "No workout plan found for Day $_currentDayNum.";
        }
      } else {
        _workoutContent = "No workout plan found. Generate one from the Workout page.";
      }
    } catch (e) {
      _workoutContent = "Error loading workout";
    } finally {
      _isWorkoutLoading = false;
      notifyListeners();
    }
  }
  
  // Optional: Add a manual refresh method
  Future<void> refreshAllData() async {
    _isQuoteLoading = true;
    _isGoalLoading = true;
    _isMealLoading = true;
    _isWorkoutLoading = true;
    notifyListeners();
    
    await loadQuote();
    await fetchUserData();
    await fetchCurrentMeal();
    await fetchCurrentWorkout();
  }
}