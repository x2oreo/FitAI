// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';

// Blur effect constants for consistent usage across the app
// class BlurTheme {
//   static const double blurRadius = 30.0;  // Increased from 10.0 to 20.0
//   static const Color lightOverlayColor = Color.fromRGBO(0, 0, 0, 0.362);
//   static const Color darkOverlayColor = Color.fromRGBO(206, 196, 196, 0.2);
  
//   // Apply blur to any widget
//   static const double defaultLightOpacity = 0.1;  // Default opacity for light theme
//   static const double defaultDarkOpacity = 0.2;   // Default opacity for dark theme
  
//   // Method to get overlay color with custom opacity
//   static Color getOverlayColor(bool isDark, double? customOpacity) {
//     if (isDark) {
//       return darkOverlayColor.withOpacity(customOpacity ?? defaultDarkOpacity);
//     } else {
//       return lightOverlayColor.withOpacity(customOpacity ?? defaultLightOpacity);
//     }
//   }
//   static Widget applyBlur({
//     required Widget child,
//     required BuildContext context,
//     double? customBlurRadius,
//     Color? customOverlayColor,
//   }) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(
//           sigmaX: customBlurRadius ?? blurRadius,
//           sigmaY: customBlurRadius ?? blurRadius,
//         ),
//         child: Container(
//           decoration: BoxDecoration(
//             color: customOverlayColor ?? 
//                   (isDark ? darkOverlayColor : lightOverlayColor),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

final lightTheme = ThemeData(

        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 255, 255, 255),
          secondary: const Color.fromARGB(255, 0, 0, 0),
          surface: const Color.fromARGB(255, 120, 180, 240),
          background: const Color.fromARGB(255, 249, 250, 251),
          error: const Color.fromARGB(255, 252, 75, 5),
          onPrimary: const Color.fromARGB(255, 252, 252, 252),
          onSecondary: const Color.fromARGB(255, 78, 127, 234),
          onSurface: const Color.fromARGB(255, 168, 255, 176),
          onBackground: const Color.fromARGB(255, 17, 24, 39),
          onError: const Color.fromARGB(255, 252, 252, 252),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 250, 251),
        primaryColor: const Color.fromARGB(255, 34, 238, 126),
        hintColor: const Color.fromARGB(255, 58, 121, 255),
        
        dividerColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.1),
        listTileTheme: ListTileThemeData(iconColor: const Color.fromARGB(255, 17, 24, 39)),
        appBarTheme: AppBarTheme(
            backgroundColor: const Color.fromARGB(255, 249, 250, 251),
            centerTitle: true,
            iconTheme: IconThemeData(color: const Color.fromARGB(255, 17, 24, 39)),
            titleTextStyle: TextStyle(
                color: const Color.fromARGB(255, 17, 24, 39),
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                fontStyle: FontStyle.italic,
            )
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
              fontStyle: FontStyle.italic,
            ),
          bodyLarge: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w700, 
              fontSize: 28,
              fontStyle: FontStyle.italic,
            ),
          bodyMedium: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w500, 
              fontSize: 22,
              fontStyle: FontStyle.italic,
            ),
          bodySmall: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7), 
              fontWeight: FontWeight.w400, 
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          labelSmall: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 17, 24, 39),
              decorationThickness: 1,
              fontStyle: FontStyle.italic,
            ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),   
            floatingLabelStyle: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
            prefixIconColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 252, 75, 5), width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.05),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            foregroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 17, 24, 39)),
            iconColor: MaterialStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)),
          ),
        ),
      );

final darktheme = ThemeData(

        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 36, 36, 36),
          secondary: const Color.fromARGB(255, 255, 255, 255),
          surface: const Color.fromARGB(255, 70, 70, 73),
          background: const Color.fromARGB(255, 249, 250, 251),
          error: const Color.fromARGB(255, 252, 75, 5),
          onPrimary: const Color.fromARGB(255, 252, 252, 252),
          onSecondary: const Color.fromARGB(255, 88, 58, 255),
          onSurface: const Color.fromARGB(255, 6, 20, 48),
          onBackground: const Color.fromARGB(255, 17, 24, 39),
          onError: const Color.fromARGB(255, 252, 252, 252),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color.fromARGB(255, 13, 17, 23),
        primaryColor: const Color.fromARGB(255, 255, 255, 255),
        hintColor: const Color.fromARGB(255, 34, 211, 238),
        dividerColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.1),
        listTileTheme: ListTileThemeData(iconColor: const Color.fromARGB(255, 229, 231, 235)),
        appBarTheme: AppBarTheme(
            backgroundColor: const Color.fromARGB(255, 13, 17, 23),
            centerTitle: true,
            iconTheme: IconThemeData(color: const Color.fromARGB(255, 229, 231, 235)),
            titleTextStyle: TextStyle(
                color: const Color.fromARGB(255, 229, 231, 235),
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
            )
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
              fontStyle: FontStyle.italic,
            ),
          bodyLarge: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w700, 
              fontSize: 28,
              fontStyle: FontStyle.italic,
            ),
          bodyMedium: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w500, 
              fontSize: 22,
              fontStyle: FontStyle.italic,
            ),
          bodySmall: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7), 
              fontWeight: FontWeight.w400, 
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          labelSmall: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 229, 231, 235),
              decorationThickness: 1,
              fontStyle: FontStyle.italic,
            ),
        ),

        

        inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),   
            floatingLabelStyle: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
            prefixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white),
                ),
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.white, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 252, 75, 5), width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
            foregroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 229, 231, 235)),
            iconColor: MaterialStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.white,
                  
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)),
          ),
        ),
);