import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:hk11/utils/calendar.dart';
import 'package:http/io_client.dart';

class AuthService {
  static final auth = FirebaseAuth.instance;

  Future<UserCredential?> loginWithGoogle() async {
    var clientId =
        "914180725286-d7043kn3k4haaau6rtcpgubqv1oocla7.apps.googleusercontent.com";

    var serverClientId =
        "914180725286-7opicuf0nhplgsi7fd8luk82f0a69oca.apps.googleusercontent.com";

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: serverClientId,
      scopes: <String>[
        cal.CalendarApi.calendarScope,
        cal.CalendarApi.calendarEventsScope,
      ],
    );

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleAPIClient httpClient = GoogleAPIClient(
        await googleSignInAccount.authHeaders,
      );
      CalendarClient.calendar = cal.CalendarApi(httpClient);

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential userCredential = await auth.signInWithCredential(
          credential,
        );
        return userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          customSnackBar(
            content: 'The account already exists with a different credential',
          );
        } else if (e.code == 'invalid-credential') {
          customSnackBar(
            content: 'Error occurred while accessing credentials. Try again.',
          );
        }
      } catch (e) {
        customSnackBar(
          content: 'Error occurred using Google Sign In. Try again.',
        );
      }
    }
    return null;
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }
}

class GoogleAPIClient extends IOClient {
  final Map<String, String> _headers;

  GoogleAPIClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(request) =>
      super.send(request..headers.addAll(_headers));
}
