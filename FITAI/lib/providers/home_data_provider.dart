import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/services/quotes_service.dart';
import 'dart:math';
import 'dart:async';

class HomeDataProvider with ChangeNotifier {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Auth listener
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;
  
  // Data variables
  String _quote = 'Loading quote...';
  String _userGoal = 'Loading goal...';
  int _currentDayNum = 1;
  String _mealType = '';
  String _mealContent = '';
  String _workoutType = '';
  String _workoutContent = '';
  String _avatarUrl = ''; // Added avatar URL property
  
  // Loading flags
  bool _isQuoteLoading = true;
  bool _isGoalLoading = true;
  bool _isMealLoading = true;
  bool _isWorkoutLoading = true;
  bool _isAvatarLoading = true; // Added avatar loading flag
  
  // Getters
  String get quote => _quote;
  String get userGoal => _userGoal;
  int get currentDayNum => _currentDayNum;
  String get mealType => _mealType;
  String get mealContent => _mealContent;
  String get workoutType => _workoutType;
  String get workoutContent => _workoutContent;
  String get avatarUrl => _avatarUrl; // Added avatar URL getter
  
  bool get isQuoteLoading => _isQuoteLoading;
  bool get isGoalLoading => _isGoalLoading;
  bool get isMealLoading => _isMealLoading;
  bool get isWorkoutLoading => _isWorkoutLoading;
  bool get isAvatarLoading => _isAvatarLoading; // Added avatar loading getter
  
  HomeDataProvider() {
    // Listen for auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      final newUserId = user?.uid;
      
      // If user ID changed, clear data and reload
      if (newUserId != _currentUserId) {
        print("User changed from $_currentUserId to $newUserId - reloading data");
        _currentUserId = newUserId;
        _clearData();
        initializeData();
      }
    });
  }
  
  // Clear all cached data
  void _clearData() {
    _quote = 'Loading quote...';
    _userGoal = 'Loading goal...';
    _currentDayNum = 1;
    _mealType = '';
    _mealContent = '';
    _workoutType = '';
    _workoutContent = '';
    _avatarUrl = ''; // Clear avatar URL
    
    _isQuoteLoading = true;
    _isGoalLoading = true;
    _isMealLoading = true;
    _isWorkoutLoading = true;
    _isAvatarLoading = true; // Reset avatar loading flag
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
  
  // Initialize data
  Future<void> initializeData() async {
    // Only fetch data if it hasn't been loaded yet or user changed
    await loadQuote();
    await fetchUserData();
    await fetchCurrentMeal();
    await fetchCurrentWorkout();
    await fetchUserAvatar(); // Added avatar fetching
  }
  
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
      print("Fetching meal plan for user: $userId, day: $_currentDayNum");
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('diet')
          .get();
      
      print("Diet doc exists: ${doc.exists}");
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> dietPlan = doc.data() as Map<String, dynamic>;
        print("Diet plan data: ${dietPlan.keys}");
        
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
          print("Day key '$dayKey' not found in diet plan");
          // Try a fallback approach - look for data without the 'day' prefix
          if (dietPlan.containsKey('$_currentDayNum')) {
            var dayData = dietPlan['$_currentDayNum'];
            if (dayData is Map && dayData.containsKey('plan')) {
              var planData = dayData['plan'];
              if (planData is String) {
                // Use same regex logic as before
                final pattern = r'\*\*' + _mealType + r'\*\*\s*([\s\S]*?)(?=\*\*\w+(?:\s+\w+)?\*\*|$)';
                RegExp mealRegex = RegExp(pattern, caseSensitive: false, multiLine: true, dotAll: true);
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
        }
      } else {
        print("No diet document found");
        _mealContent = "No meal plan found. Generate one from the Meal Plan page.";
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
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
      // Define default workout types
      List<String> workoutTypes = [
        "Strength Training",
        "Cardio",
        "Flexibility & Balance",
        "HIIT",
        "Core & Abs",
        "Full Body",
        "Rest Day"
      ];
      
      // Fetch workout plan data
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      print("Fetching workout plan for user: $userId, day: $_currentDayNum");
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plans')
          .doc('workout')
          .get();
      
      print("Workout doc exists: ${doc.exists}");
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> workoutPlan = doc.data() as Map<String, dynamic>;
        print("Workout plan data keys: ${workoutPlan.keys}");
        
        String dayKey = 'day$_currentDayNum';
        if (workoutPlan.containsKey(dayKey)) {
          // Default workout type from preset list
          _workoutType = workoutTypes[_currentDayNum - 1];
          
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
          
          _workoutContent = "";  // Empty string instead of the "Tap to see..." message
        } else {
          print("Day key '$dayKey' not found in workout plan");
          // Try a fallback approach - look for data without the 'day' prefix
          if (workoutPlan.containsKey('$_currentDayNum')) {
            var dayData = workoutPlan['$_currentDayNum'];
            _workoutType = workoutTypes[_currentDayNum - 1];
            
            if (dayData is Map && dayData.containsKey('plan')) {
              var planData = dayData['plan'];
              if (planData is String) {
                final dayTitlePattern = r'### Day ' + _currentDayNum.toString() + r': ([^\n]+)';
                final dayTitleMatch = RegExp(dayTitlePattern).firstMatch(planData);
                
                if (dayTitleMatch != null && dayTitleMatch.groupCount >= 1) {
                  _workoutType = dayTitleMatch.group(1)?.trim() ?? _workoutType;
                }
              }
            }
            _workoutContent = "";
          } else {
            _workoutType = "No Workout";
            _workoutContent = "No workout plan found for Day $_currentDayNum.";
          }
        }
      } else {
        print("No workout document found");
        _workoutType = "No Workout Plan";
        _workoutContent = "No workout plan found. Generate one from the Workout page.";
      }
    } catch (e) {
      print("Error fetching workout plan: $e");
      _workoutType = "Error";
      _workoutContent = "Error loading workout";
    } finally {
      _isWorkoutLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch user avatar with proper account change handling
  Future<void> fetchUserAvatar() async {
    _isAvatarLoading = true;
    // Always clear avatar before fetching new one
    _avatarUrl = '';
    notifyListeners();
    
    try {
      // Clear image cache to prevent stale images
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Check if there's a current user
      if (_auth.currentUser == null) {
        print("No current user found");
        _isAvatarLoading = false;
        notifyListeners();
        return;
      }
      
      // Force reload current user to get fresh data
      await _auth.currentUser!.reload();
      
      // Add small delay to ensure Firebase has updated
      await Future.delayed(const Duration(milliseconds: 300));
      
      String userId = _auth.currentUser!.uid;
      print("Fetching avatar for user ID: $userId, user email: ${_auth.currentUser!.email}");
      
      // Add a cache buster to ensure we're not getting cached data
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get(
        GetOptions(source: Source.server) // Force server fetch, not cache
      );
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String firebaseAvatar = userData['avatarUrl'] ?? '';
        
        if (firebaseAvatar.isNotEmpty) {
          print("Found avatar in Firestore: $firebaseAvatar");
          // Add cache buster to URL to prevent browser caching
          _avatarUrl = firebaseAvatar.contains('?') 
            ? '$firebaseAvatar&cacheBuster=${DateTime.now().millisecondsSinceEpoch}'
            : '$firebaseAvatar?cacheBuster=${DateTime.now().millisecondsSinceEpoch}';
        } else if (_auth.currentUser?.photoURL != null) {
          String photoUrl = _auth.currentUser!.photoURL!;
          print("Using photoURL from Auth: $photoUrl");
          // Add cache buster to URL
          _avatarUrl = photoUrl.contains('?') 
            ? '$photoUrl&cacheBuster=${DateTime.now().millisecondsSinceEpoch}'
            : '$photoUrl?cacheBuster=${DateTime.now().millisecondsSinceEpoch}';
          
          // Update Firestore with this URL for future reference
          try {
            await _firestore.collection('users').doc(userId).update({
              'avatarUrl': photoUrl, // Save original URL without cache buster
            });
          } catch (e) {
            print("Error updating avatar in Firestore: $e");
          }
        } else {
          print("No avatar found for user $userId");
        }
      } else {
        print("No user document found in Firestore");
        if (_auth.currentUser?.photoURL != null) {
          String photoUrl = _auth.currentUser!.photoURL!;
          // Add cache buster
          _avatarUrl = photoUrl.contains('?') 
            ? '$photoUrl&cacheBuster=${DateTime.now().millisecondsSinceEpoch}'
            : '$photoUrl?cacheBuster=${DateTime.now().millisecondsSinceEpoch}';
        }
      }
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
    
    _isAvatarLoading = false;
    notifyListeners();
  }
  
  // Optional: Add a manual refresh method
  Future<void> refreshAllData() async {
    _clearData();
    await initializeData();
  }
  
  // A more forceful refresh method for avatar issues
  Future<void> refreshAvatar() async {
    _isAvatarLoading = true;
    _avatarUrl = '';
    notifyListeners();
    
    try {
      // Clear image cache first
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Ensure we're completely clear of cached data
      if (_auth.currentUser != null) {
        await _auth.currentUser!.reload();
        
        // Add a small delay to ensure Firebase has updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force fetch fresh avatar
        await fetchUserAvatar();
        
        print("Avatar refreshed for user: ${_auth.currentUser!.uid}");
        print("Current avatar URL: $_avatarUrl");
      } else {
        print("Cannot refresh avatar - no current user");
      }
    } catch (e) {
      print("Error during avatar refresh: $e");
    }
    
    _isAvatarLoading = false;
    notifyListeners();
  }
}