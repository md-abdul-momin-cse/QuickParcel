import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quick_parcel/driver/driver_bottomnav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quick_parcel/driver/driver_signup.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/widget_support.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  static const Color _primary = Color(0xFFF57C00); // Orange for Driver

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    try {
      setState(() => _loading = true);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final helper = SharedpreferenceHelper();
      final firebaseUid = cred.user?.uid ?? '';
      final email = cred.user?.email ?? _emailController.text.trim();

      String? resolvedUserDocId;
      Map<String, dynamic>? resolvedUserData;

      if (firebaseUid.isNotEmpty) {
        final byUid = await DatabaseMethods().getDriverByFirebaseUid(
          firebaseUid,
        );
        if (byUid.docs.isNotEmpty) {
          resolvedUserDocId = byUid.docs.first.id;
          resolvedUserData = byUid.docs.first.data();
        }
      }

      if (resolvedUserDocId != null && resolvedUserData != null) {
        await helper.saveUserId(resolvedUserDocId);
        await helper.saveUserName(resolvedUserData['Name'] ?? 'Driver');
        await helper.saveUserEmail(email);
        await helper.saveUserType('Driver');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DriverBottomNav()),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Driver profile not found. Please sign up.'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = 'Login failed';
        if (e.code == 'user-not-found') {
          errorMsg = 'No driver found with this email';
        } else if (e.code == 'wrong-password') {
          errorMsg = 'Incorrect password';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _loading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);

      final helper = SharedpreferenceHelper();
      final firebaseUid = userCred.user?.uid ?? '';

      final byUid = await DatabaseMethods().getDriverByFirebaseUid(firebaseUid);

      if (byUid.docs.isEmpty) {
        // Create new driver profile
        final String customId = userCred.user?.uid ?? '';
        final driverInfoMap = {
          'Id': customId,
          'FirebaseUid': firebaseUid,
          'Name': userCred.user?.displayName ?? 'Driver',
          'Email': userCred.user?.email ?? '',
          'UserType': 'Driver',
          'CreatedAt': DateTime.now().toIso8601String(),
          'IsVerified': false,
          'Rating': 5.0,
          'TotalDeliveries': 0,
        };

        await DatabaseMethods().addDriverDetail(driverInfoMap, customId);
        await helper.saveUserId(customId);
      } else {
        await helper.saveUserId(byUid.docs.first.id);
      }

      await helper.saveUserName(userCred.user?.displayName ?? 'Driver');
      await helper.saveUserEmail(userCred.user?.email ?? '');
      await helper.saveUserType('Driver');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DriverBottomNav()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Google login failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _primary,
      body: Column(
        children: [
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: Image.asset(
              "images/delivery-bike.png",
              fit: BoxFit.contain,
            ),
          ),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Start your delivery journey',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //r Email Field
                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter email';
                          final regex = RegExp(r'^.+@.+\..+$');
                          if (!regex.hasMatch(value)) return 'Invalid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter password' : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to forgot password
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: const Color(0xFFF57C00),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      AppWidget.primaryActionButton(
                        context: context,
                        label: 'Log in',
                        color: _primary,
                        loading: _loading,
                        onPressed: _loading ? null : _signInWithEmail,
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.dividerColor,
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or Log in with',
                              style: TextStyle(
                                color: Color(0xFFF57C00),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.dividerColor,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _signInWithGoogle,
                              icon: const FaIcon(
                                FontAwesomeIcons.google,
                                size: 20,
                                color: Color(0xFFF57C00),
                              ),
                              label: const Text(
                                'Google',
                                style: TextStyle(
                                  color: Color(0xFFF57C00),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(
                                  color: const Color(
                                    0xFFF57C00,
                                  ).withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Sign Up Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: const TextStyle(
                                  color: Color(0xFFF57C00),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DriverSignUpScreen(),
                                      ),
                                    );
                                  },
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
          ),
        ],
      ),
    );
  }
}
