import 'package:firebase_auth/firebase_auth.dart';

class AuthCheck {
  static bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
