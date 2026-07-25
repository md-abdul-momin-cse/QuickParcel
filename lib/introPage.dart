import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';
import 'package:quick_parcel/driver/driver_login.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/admin/admin_login.dart';

class Intropage extends StatefulWidget {
  const Intropage({super.key});

  @override
  State<Intropage> createState() => _IntropageState();
}

class _IntropageState extends State<Intropage> {
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToDriverLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }

  void _showRoleSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppWidget.surfaceColor,
        title: Text(
          'Choose Your Role',
          style: AppWidget.boldTextFieldStyle(22.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Are you here to send packages or deliver them?',
              style: AppWidget.LightTextFieldStyle(14.0),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin(context);
              },
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('Continue as Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7D8F),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToDriverLogin(context);
              },
              icon: const Icon(Icons.delivery_dining_rounded),
              label: const Text('Continue as Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToAdminLogin(context);
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Continue as Admin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0B7285),
                side: const BorderSide(color: Color(0xFF0B7285)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
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
            colors: [Color(0xFF0D7D8F), Color(0xFF0A5F6D), Color(0xFF084A56)],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.electric_bolt,
                          color: Colors.amber,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Quick Parcel",
                          style: AppWidget.WhiteHeadlineTextStyle(30),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    "Lightning Fast Delivery 🚀",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.amber.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // lottie Animation
                  SizedBox(
                    height: 180,
                    child: Lottie.network(
                      "https://lottie.host/1fa15ee0-de39-4204-b521-8596beea2086/pjxFE3sdzL.json",
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // offers section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppWidget.surfaceColor,
                          AppWidget.surfaceAltColor,
                        ],
                      ),
                      border: Border.all(color: AppWidget.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: AppWidget.shadowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "HOT DEALS & OFFERS",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendPackage(),
                                    ),
                                  );
                                },
                                child: AppWidget.buildPremiumOfferItem(
                                  icon: Icons.celebration_rounded,
                                  title: "MEGA DISCOUNT",
                                  subtitle: "50% OFF First Delivery",
                                  description:
                                      "New users get flat 50% off on first order!",
                                  gradient: const [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8E53),
                                  ],
                                  badge: "LIMITED",
                                ),
                              ),
                              const SizedBox(height: 15),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendPackage(),
                                    ),
                                  );
                                },
                                child: AppWidget.buildPremiumOfferItem(
                                  icon: Icons.card_giftcard_rounded,
                                  title: "CASHBACK OFFER",
                                  subtitle: "Get ৳200 Cashback",
                                  description:
                                      "On orders above ৳500 - Valid for 7 days",
                                  gradient: const [
                                    Color(0xFF11998E),
                                    Color(0xFF38EF7D),
                                  ],
                                  badge: "HOT",
                                ),
                              ),
                              const SizedBox(height: 15),
                              AppWidget.buildPremiumOfferItem(
                                icon: Icons.rocket_launch_rounded,
                                title: "EXPRESS FREE",
                                subtitle: "Free Express Delivery",
                                description:
                                    "Get items delivered within 2 hours - FREE!",
                                gradient: const [
                                  Color(0xFF4E54C8),
                                  Color(0xFF8F94FB),
                                ],
                                badge: "NEW",
                              ),
                              const SizedBox(height: 15),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendPackage(),
                                    ),
                                  );
                                },
                                child: AppWidget.buildPremiumOfferItem(
                                  icon: Icons.loyalty_rounded,
                                  title: "LOYALTY BONUS",
                                  subtitle: "Send 3, Get 1 Free",
                                  description:
                                      "Complete 3 deliveries, get next one FREE!",
                                  gradient: const [
                                    Color(0xFFFFB75E),
                                    Color(0xFFED8F03),
                                  ],
                                  badge: "SAVE",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // get started button
                  GestureDetector(
                    onTap: () => _showRoleSelectionDialog(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.7,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppWidget.surfaceColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF0D7D8F).withOpacity(0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppWidget.shadowColor,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              "Get Started Now",
                              style: AppWidget.BoldGreenTextfeildStyle(20),
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF0D7D8F),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // trust indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppWidget.buildTrustBadge(Icons.verified_user, "Secure"),
                      const SizedBox(width: 20),
                      AppWidget.buildTrustBadge(Icons.speed, "Fast"),
                      const SizedBox(width: 20),
                      AppWidget.buildTrustBadge(Icons.thumb_up, "Trusted"),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
