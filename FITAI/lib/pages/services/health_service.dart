// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'package:permission_handler/permission_handler.dart';

// class HealthService {
//   // Create an instance of Health
//   final Health health = Health();
  
//   // Define types - only steps for simplicity
//   static final types = [
//     HealthDataType.STEPS,
//   ];

//   // Permissions to request from the user
//   List<HealthDataAccess> get permissions => 
//     types.map((type) => HealthDataAccess.READ).toList();

//   // Initialize and check Health Connect status
//   Future<void> initialize() async {
//     try {
//       await health.configure();
//       if (Platform.isAndroid) {
//         final status = await health.getHealthConnectSdkStatus();
//         print('Health Connect status: ${status?.name}');
        
//         if (status != HealthConnectSdkStatus.sdkAvailable) {
//           print('Health Connect not available. Attempting installation...');
//           await health.installHealthConnect();
//         }
//       }
//     } catch (e) {
//       print('Error initializing health service: $e');
//     }
//   }

//   Future<bool> requestPermissions() async {
//     try {
//       print('Requesting health permissions...');
      
//       // Request activity recognition permission first
//       if (Platform.isAndroid) {
//         print('Requesting activity recognition permission');
//         var status = await Permission.activityRecognition.request();
//         print('Activity recognition permission status: $status');
//       }
      
//       // Check if we have health permissions
//       print('Checking current health permissions');
//       bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
//       print('Current permission status: $hasPermissions');
      
//       // Always request authorization
//       print('Requesting health authorization');
//       bool authorized = await health.requestAuthorization(types, permissions: permissions);
//       print('Authorization result: $authorized');
      
//       if (authorized) {
//         // Request access to historic data
//         try {
//           print('Requesting history authorization');
//           await health.requestHealthDataHistoryAuthorization();
//         } catch (e) {
//           print('Error requesting history authorization: $e');
//         }
//       }
      
//       return authorized;
//     } catch (e) {
//       print('Error requesting health permissions: $e');
//       return false;
//     }
//   }

//   // Simplified method to fetch only step data
//   Future<Map<String, dynamic>> fetchStepsData() async {
//     Map<String, dynamic> healthData = {
//       'steps': 0,
//       'hasData': false,
//     };

//     try {
//       // Try to initialize if needed
//       await initialize();
      
//       // Request permissions
//       bool hasPermissions = await requestPermissions();
//       if (!hasPermissions) {
//         print('Health permissions not granted');
//         return healthData;
//       }
      
//       // Get time range for today
//       final now = DateTime.now();
//       final midnight = DateTime(now.year, now.month, now.day);

//       // Get steps using the getTotalStepsInInterval method
//       int? steps;
//       try {
//         print('Fetching steps data...');
//         steps = await health.getTotalStepsInInterval(midnight, now);
//         print('Steps retrieved: $steps');
        
//         return {
//           'steps': steps ?? 0,
//           'hasData': steps != null && steps > 0,
//         };
//       } catch (e) {
//         print('Error getting steps: $e');
        
//         // If direct method fails, try the generic method
//         try {
//           print('Trying alternative method to get steps...');
//           final stepsData = await health.getHealthDataFromTypes(
//             midnight, 
//             now, 
//             [HealthDataType.STEPS],
//           );
          
//           print('Steps data points: ${stepsData.length}');
          
//           int totalSteps = 0;
//           for (var step in stepsData) {
//             if (step.value is NumericHealthValue) {
//               totalSteps += (step.value as NumericHealthValue).numericValue.toInt();
//             }
//           }
          
//           return {
//             'steps': totalSteps,
//             'hasData': totalSteps > 0,
//           };
//         } catch (e2) {
//           print('Alternative method also failed: $e2');
//           return healthData;
//         }
//       }
//     } catch (e) {
//       print('Error fetching steps data: $e');
//       return healthData;
//     }
//   }
  
//   // Open Health Connect settings if needed
//   Future<void> openHealthConnectSettings() async {
//     if (!Platform.isAndroid) return;
    
//     try {
//       await health.openHealthConnect();
//     } catch (e) {
//       print('Error opening Health Connect settings: $e');
//     }
//   }
// }