import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_shell.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'admin-login-failed');
      }

      final admin = await DatabaseMethods().findAdminProfile(
        firebaseUid: user.uid,
        email: user.email ?? _emailController.text.trim(),
      );
      if (admin == null || admin['IsActive'] == false) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'not-admin',
          message: 'This account does not have active admin access.',
        );
      }

      final helper = SharedpreferenceHelper();
      await helper.saveUserId((admin['Id'] ?? user.uid).toString());
      await helper.saveUserName((admin['Name'] ?? 'Administrator').toString());
      await helper.saveUserEmail(
        (admin['Email'] ?? user.email ?? '').toString(),
      );
      await helper.saveUserType('Admin');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      var message = error.message ?? 'Unable to sign in.';
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        message = 'Email or password is incorrect.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AdminStyle.danger, content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AdminStyle.danger,
          content: Text('Admin login failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final height = media.size.height;
    final isCompact = height < 760;
    final horizontalPadding = media.size.width < 380 ? 20.0 : 28.0;
    final imageHeight = isCompact ? 140.0 : 190.0;
    final titleSize = isCompact ? 32.0 : 38.0;

    return Scaffold(
      backgroundColor: AdminStyle.surface(context),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: AdminStyle.surface(context))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: isCompact ? 330 : 390,
            child: Container(
              decoration: BoxDecoration(
                gradient: AdminStyle.headerGradient(context),
              ),
            ),
          ),
          SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 12 : 22,
                          horizontalPadding,
                          isCompact ? 12 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: imageHeight,
                              child: Image.asset(
                                'images/admin.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: isCompact ? 10 : 14),
                            Text(
                              'Admin Portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage deliveries, drivers and users',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              imageHeight -
                              (isCompact ? 98 : 132),
                        ),
                        decoration: BoxDecoration(
                          color: AdminStyle.surface(context),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isCompact ? 22 : 30,
                            horizontalPadding,
                            24 + media.padding.bottom,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in with your authorized admin account.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 26),
                          CustomTextField(
                            label: 'Email address',
                            hint: 'enter your email',
                            prefixIcon: Icons.alternate_email_rounded,
                            controller: _emailController,
                            primaryColor: AdminStyle.primary,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Enter your email';
                              if (!RegExp(r'^.+@.+\..+$').hasMatch(email)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            primaryColor: AdminStyle.primary,
                            isPassword: true,
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Enter your password'
                                : null,
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminStyle.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign in to dashboard',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.arrow_forward_rounded),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 17,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Authorized personnel only',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}
