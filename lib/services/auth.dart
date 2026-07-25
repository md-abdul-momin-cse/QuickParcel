import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<User?>? getCurrentUser() async {
    return auth.currentUser;
  }

  Future SignOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future deleteuser() async {
    User? user = FirebaseAuth.instance.currentUser;
    user?.delete();
  }
}
