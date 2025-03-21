// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

final lightTheme = ThemeData(

        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 255, 255, 255),
          secondary: const Color.fromARGB(255, 52, 211, 153),
          surface: const Color.fromARGB(255, 120, 180, 240),
          background: const Color.fromARGB(255, 249, 250, 251),
          error: const Color.fromARGB(255, 252, 75, 5),
          onPrimary: const Color.fromARGB(255, 252, 252, 252),
          onSecondary: const Color.fromARGB(255, 78, 127, 234),
          onSurface: const Color.fromARGB(255, 17, 24, 39),
          onBackground: const Color.fromARGB(255, 17, 24, 39),
          onError: const Color.fromARGB(255, 252, 252, 252),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 250, 251),
        primaryColor: const Color.fromARGB(255, 34, 58, 238),
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
            )
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
              fontFamily: 'Inter',
            ),
          bodyLarge: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w700, 
              fontSize: 28,
              fontFamily: 'Inter',
            ),
          bodyMedium: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39), 
              fontWeight: FontWeight.w500, 
              fontSize: 22,
              fontFamily: 'Inter',
            ),
          bodySmall: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7), 
              fontWeight: FontWeight.w400, 
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          labelSmall: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 17, 24, 39),
              decorationThickness: 1,
              fontFamily: 'Inter',
            ),
        ),
        inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),   
            floatingLabelStyle: TextStyle(
              color: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
            prefixIconColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 17, 24, 39).withOpacity(0.7),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color.fromARGB(255, 17, 24, 39)),
                ),
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: const Color.fromARGB(255, 17, 24, 39), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 252, 75, 5), width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 17, 24, 39), width: 2),
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
                  color: Colors.black,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)),
          ),
        ),
      );

final darktheme = ThemeData(

        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 70, 70, 73),
          secondary: const Color.fromARGB(255, 52, 211, 153),
          surface: const Color.fromARGB(255, 70, 70, 73),
          background: const Color.fromARGB(255, 249, 250, 251),
          error: const Color.fromARGB(255, 252, 75, 5),
          onPrimary: const Color.fromARGB(255, 252, 252, 252),
          onSecondary: const Color.fromARGB(255, 17, 24, 39),
          onSurface: const Color.fromARGB(255, 17, 24, 39),
          onBackground: const Color.fromARGB(255, 17, 24, 39),
          onError: const Color.fromARGB(255, 252, 252, 252),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color.fromARGB(255, 13, 17, 23),
        primaryColor: const Color.fromARGB(255, 52, 211, 153),
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
                fontFamily: 'Inter',
            )
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
              fontFamily: 'Inter',
            ),
          bodyLarge: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w700, 
              fontSize: 28,
              fontFamily: 'Inter',
            ),
          bodyMedium: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235), 
              fontWeight: FontWeight.w500, 
              fontSize: 22,
              fontFamily: 'Inter',
            ),
          bodySmall: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7), 
              fontWeight: FontWeight.w400, 
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          labelSmall: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 229, 231, 235),
              decorationThickness: 1,
              fontFamily: 'Inter',
            ),
        ),

        

        inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),   
            floatingLabelStyle: TextStyle(
              color: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
            prefixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
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
                  borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
            foregroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 229, 231, 235)),
            iconColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)),
          ),
        ),
);