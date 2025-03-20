
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

final darktheme = ThemeData(
      
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        dividerColor: Colors.white10,
        listTileTheme: ListTileThemeData(iconColor: Colors.white),
        appBarTheme: AppBarTheme(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
            )
        ),
        
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
            ),

          bodyLarge: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w700, 
              fontSize: 28,
            ),

          bodyMedium: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w500, 
              fontSize: 22,
            ),
          bodySmall: TextStyle(
            color: Colors.white.withOpacity(0.7), 
              fontWeight: FontWeight.w400, 
              fontSize: 16,
            ),
          
          labelSmall: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 255, 255, 255 ),
              decorationThickness: 1,)
        ),
        
        

        inputDecorationTheme: InputDecorationTheme(
          
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),   

            floatingLabelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            ),

            prefixIconColor: Colors.white70,
            suffixIconColor: Colors.white70,
          
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12), enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white),
                ),
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 252, 75, 5), width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
        ),

        

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
            backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 48, 47, 47)),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
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

final lightTheme = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  primaryColor: Colors.blue,
  dividerColor: Colors.black12,
  listTileTheme: ListTileThemeData(iconColor: Colors.black),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    iconTheme: IconThemeData(color: Colors.black),
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  ),
  textTheme: TextTheme(

    headlineLarge: TextStyle(
              color: Colors.black, 
              fontWeight: FontWeight.w700, 
              fontSize: 22,
            ),

    bodyLarge: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w700,
      fontSize: 28,
    ),

    bodyMedium: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontSize: 22,
    ),

    bodySmall: TextStyle(
      color: Colors.black.withOpacity(0.7),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),

    labelSmall: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: const Color.fromARGB(255, 0, 0, 0),
              decorationThickness: 1,)
  ),

        inputDecorationTheme: InputDecorationTheme(
          
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),   

            floatingLabelStyle: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            ),

            prefixIconColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
            suffixIconColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),

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
            iconColor: MaterialStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
            
            backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
            foregroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
            
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
                fontWeight: FontWeight.w700,
              ),
            ),
            minimumSize: MaterialStateProperty.all(Size(double.infinity, 50)),
          ),
        ),
);