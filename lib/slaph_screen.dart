import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:quick_parcel/driver/driver_bottomnav.dart';
import 'package:quick_parcel/introPage.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/admin/admin_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _goNext);
  }

  Future<void> _goNext() async {
    final user = FirebaseAuth.instance.currentUser;
    final helper = SharedpreferenceHelper();
    final userId = await helper.getUserId();
    final userType = await helper.getUserType();

    if (!mounted) return;

    Widget nextPage = const Intropage();
    if (user != null && userId != null && userId.isNotEmpty) {
      if (userType == 'Admin') {
        nextPage = const AdminShell();
      } else if (userType == 'Driver') {
        nextPage = const DriverBottomNav();
      } else {
        nextPage = const BottomNav();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D7D8F), Color(0xFF084A56)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo with circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(25),
                child: Image.asset('images/icon.png'),
              ),
              const SizedBox(height: 30),

              const Text(
                'Quick Parcel',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Lightning Fast Delivery 🚀',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
