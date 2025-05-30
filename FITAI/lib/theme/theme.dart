
import 'package:flutter/material.dart';
import 'dart:ui';


final lightTheme = ThemeData(

        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 255, 255, 255),
          secondary: const Color.fromARGB(255, 0, 0, 0),
          surface: const Color.fromARGB(255, 120, 180, 240),
          background: const Color.fromARGB(255, 249, 250, 251),
          error: const Color.fromARGB(255, 252, 75, 5),
          onPrimary: const Color.fromARGB(255, 252, 252, 252),
          onSecondary: const Color.fromARGB(255, 78, 127, 234),
          onSurface: const Color.fromARGB(255, 187, 187, 187),
          onBackground: const Color.fromARGB(255, 17, 24, 39),
          onError: const Color.fromARGB(255, 252, 252, 252),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 250, 251),
        primaryColor: Color(0xFF6f6f6f),
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
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), 
                enabledBorder: OutlineInputBorder(
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
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 17, 24, 39)),
            iconColor: WidgetStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              
            ),
            textStyle: WidgetStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: WidgetStateProperty.all(Size(double.infinity, 50)),
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
          onSecondary: Colors.deepPurple,
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
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),   
            floatingLabelStyle: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
            prefixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 229, 231, 235).withOpacity(0.7),
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), 
                enabledBorder: OutlineInputBorder(
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
            
            backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
            foregroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 229, 231, 235)),
            iconColor: WidgetStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            textStyle: WidgetStateProperty.all(
              TextStyle(
                color: const Color.fromARGB(255, 252, 252, 252),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: WidgetStateProperty.all(Size(double.infinity, 56)),
          ),
        ),
);