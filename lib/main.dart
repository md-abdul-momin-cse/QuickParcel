import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:quick_parcel/introPage.dart';
import 'package:quick_parcel/slaph_screen.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/signup.dart';
import 'package:quick_parcel/services/app_theme.dart';
import 'package:quick_parcel/admin/admin_login.dart';

// Driver app imports (commented out)
// import 'package:quick_parcel/driver/driver_login.dart';
// import 'package:quick_parcel/driver/driver_signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Parcel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: SplashScreen(),
      routes: {
        '/intro': (context) => const Intropage(),
        // Customer app routes
        '/customer-login': (context) => const LoginScreen(),
        '/customer-signup': (context) => const SignUpScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),

        // Driver app routes (commented out)
        // '/driver-login': (context) => const DriverLoginScreen(),
        // '/driver-signup': (context) => const DriverSignUpScreen(),
      },
    );
  }
}
