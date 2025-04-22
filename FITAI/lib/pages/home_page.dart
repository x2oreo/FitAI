import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';
import 'package:hk11/pages/journal_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/quotes_service.dart';
import 'workout_page.dart';
import 'meal_page.dart';
import 'services/health_service.dart';

final health = Health();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
  PERMISSIONS_REVOKING,
  PERMISSIONS_REVOKED,
  PERMISSIONS_NOT_REVOKED,
}

class _MyHomePageState extends State<MyHomePage> {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final HealthService _healthService = HealthService();


  String _currentQuote = 'Loading quote...';
  String _userGoal = 'Loading goal...';
  int _currentDayNum = 1;
  bool _isLoading = true;
  bool _isLoadingGoal = true;
  

  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  List<RecordingMethod> recordingMethodsToFilter = [];

  static final types = [
    HealthDataType.WEIGHT,
    HealthDataType.STEPS,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WORKOUT,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    // Uncomment this line on iOS - only available on iOS
    // HealthDataType.AUDIOGRAM
  ];

  List<HealthDataAccess> get permissions => types
      .map((type) =>
          // can only request READ permissions to the following list of types on iOS
          [
            HealthDataType.STEPS,
            HealthDataType.ACTIVE_ENERGY_BURNED,
          ].contains(type)
              ? HealthDataAccess.READ
              : HealthDataAccess.READ_WRITE)
      .toList();

  @override
  void initState() {
    authorize();
    fetchData();
    health.configure();
    health.getHealthConnectSdkStatus();
    health.installHealthConnect();
    health.requestHealthDataHistoryAuthorization();
    _loadQuote();
    _fetchUserData();
    
    super.initState();
    // _fetchHealthData();
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

  Future<void> installHealthConnect() async =>
      await health.installHealthConnect();


  Future<void> authorize() async {
  await Permission.activityRecognition.request();

  bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);

  bool authorized = false;
  if (hasPermissions == false) {
    try {
      authorized = await health.requestAuthorization(types, permissions: permissions);
      await health.requestHealthDataHistoryAuthorization();
    } catch (error) {
      debugPrint("Exception in authorize: $error");
    }
  } else {
    authorized = true;
  }

  setState(() => _state = authorized ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
}


   Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    _healthDataList.clear();

    try {
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
        recordingMethodsToFilter: recordingMethodsToFilter,
      );

      print('Total number of data points: ${healthData.length}. '
          '${healthData.length > 100 ? 'Only showing the first 100.' : ''}');

      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));

      _healthDataList.addAll(
          (healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    } catch (error) {
      print("Exception in getHealthDataFromTypes: $error");
    }

    _healthDataList = health.removeDuplicates(_healthDataList);

    

    // update the UI to display the results
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  Future<void> fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission =
        await health.hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission =
          await health.requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now,
            includeManualEntry:
                !recordingMethodsToFilter.contains(RecordingMethod.manual));
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      print('Total number of steps: $steps');
      
      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Future<void> revokeAccess() async {
    setState(() => _state = AppState.PERMISSIONS_REVOKING);

    bool success = false;

    try {
      await health.revokePermissions();
      success = true;
    } catch (error) {
      debugPrint("Exception in revokeAccess: $error");
    }

    setState(() {
      _state = success
          ? AppState.PERMISSIONS_REVOKED
          : AppState.PERMISSIONS_NOT_REVOKED;
    });
  }

  // Future<void> _fetchHealthData() async {
  //   try {
  //     final healthData = await _healthService.fetchHealthData();
  //     setState(() {
  //       _healthData = healthData;
  //     });
  //   } catch (e) {
  //     print('Error fetching health data: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        constraints: BoxConstraints(
          minHeight: screenHeight,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Color(0xFF250050), // Dark purple
                    Color(0xFF24004e), // Dark purple
                    Color(0xFF210047), // Dark purple
                    Color(0xFF1d0040), // Medium dark purple
                    Color(0xFF1b003d), // Medium dark purple
                    Color(0xFF190039), // Dark purple
                    Color(0xFF170036), // Medium dark purple
                    Color(0xFF160132), // Medium dark purple
                    Color(0xFF14022d), // Dark purple/indigo
                    Color(0xFF120327), // Very dark purple with hint of blue
                    Color(0xFF110325), // Very dark purple
                    Color(0xFF0e021d), // Very dark purple
                    Color(0xFF090213), // Almost black with hint of purple
                    Color(0xFF040109), // Almost black
                    Color(0xFF000000), // Black 
                  ]
                : [
                    Color(0xFFffffff), // White
                    Color(0xFFeeeeee), // Very light gray
                    Color(0xFFdcdcdc), // Light gray
                    Color(0xFFcbcbcb), // Light/medium gray
                    Color(0xFFb6b6b6), // Medium gray
                    Color(0xFF9e9e9e), // Medium gray
                    Color(0xFF868686), // Darker medium gray
                    Color(0xFF6f6f6f), // Dark gray
                  ],
            stops: isDarkMode
                ? [0.0, 0.07, 0.14, 0.21, 0.28, 0.35, 0.42, 0.49, 0.56, 0.63, 0.7, 0.77, 0.84, 0.92, 1.0]
                : [0.0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.85, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 70),

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
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Container(
                                  constraints: BoxConstraints(
                                    minHeight: 120,
                                  ),
                                  child: Center(
                                    child: Text(
                                    _currentQuote,
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
                    height: 150,
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
                                _isLoadingGoal
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.directions_walk, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                '${fetchStepData()} steps',
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          // Row(
                                          //   children: [
                                          //     Icon(Icons.local_fire_department, size: 16),
                                          //     SizedBox(width: 4),
                                          //     Text(
                                          //       '${_healthData['calories']} cal',
                                          //       style: theme.textTheme.bodyMedium,
                                          //     ),
                                          //   ],
                                          // ),
                                        ],
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

                // Workout and meal containers in a row
                Row(
                  children: [
                    // Workout container
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WorkoutPage()),
                          );
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.primary.withOpacity(0.9),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 20,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Workout',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 45,
                                left: 55,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Day $_currentDayNum',
                                      style: theme.textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 16), // Space between containers
                    
                    // Meal container
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MealPage()),
                          );
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.primary.withOpacity(0.9),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 40,
                                child: Row(
                                  children: [
                                    
                                    Icon(
                                      Icons.restaurant,
                                      color: const Color.fromARGB(255, 58, 196, 129),
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      
                                      'Meal',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: const Color.fromARGB(255, 58, 196, 129),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 45,
                                left: 55,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Day $_currentDayNum',
                                      style: theme.textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                InkWell(
                  onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JournalPage()),
                          );
                        },
                  
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary.withOpacity(0.9),
                    
                  ),
                  padding: const EdgeInsets.all(2),
                    child: Stack(
                      children: [
                        
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
                                  Icons.book,
                                  color: theme.hintColor,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Journal',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                
                              ],
                              
                            ),
                            
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: 45,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'What did you do today?',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                SizedBox(height: 4),
                                    
                                ],
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
          ),
        ),
      ),
    );
  }
}
