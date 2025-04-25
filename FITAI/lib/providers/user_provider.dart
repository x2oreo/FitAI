import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  UserProvider() {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading = true;
    notifyListeners();

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        userData = doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Widget getAvatarWidget(double radius) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        
        if (isLoading) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primary,
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
          );
        }
        
        return CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: _getAvatarImage(),
          child: _shouldShowDefaultIcon() 
              ? Icon(
                  Icons.person,
                  color: theme.primaryColor,
                  size: radius,
                )
              : null,
        );
      }
    );
  }

  ImageProvider? _getAvatarImage() {
    if (userData != null && userData!['localImagePath'] != null) {
      try {
        return FileImage(File(userData!['localImagePath']));
      } catch (e) {
        print('Error loading local image: $e');
      }
    }
    
    if (_auth.currentUser?.photoURL != null) {
      try {
        return NetworkImage(_auth.currentUser!.photoURL!);
      } catch (e) {
        print('Error loading network image: $e');
      }
    }
    
    return null;
  }

  bool _shouldShowDefaultIcon() {
    return (userData == null || userData!['localImagePath'] == null) && 
           _auth.currentUser?.photoURL == null;
  }
}