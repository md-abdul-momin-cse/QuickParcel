import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/driver/driver_bottomnav.dart';
import 'package:quick_parcel/driver/driver_login.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:random_string/random_string.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';

class DriverSignUpScreen extends StatefulWidget {
  const DriverSignUpScreen({super.key});

  @override
  State<DriverSignUpScreen> createState() => _DriverSignUpScreenState();
}

class _DriverSignUpScreenState extends State<DriverSignUpScreen> {
  static const Color _primary = Color(0xFFF57C00); // Orange for Driver

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  bool _agreeToTerms = false;
  bool _loading = false;
  final bool _showPassword = false;
  final bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Enter password';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]').hasMatch(password)) {
      return 'Password must contain special character';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final phone = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (phone.isEmpty) return 'Enter phone number';
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please fill all fields correctly'),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF57C00),
          content: Text('Please agree to the terms & policy'),
        ),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final String customId = randomAlphaNumeric(10);

      final driverInfoMap = {
        'Id': customId,
        'FirebaseUid': credential.user?.uid ?? '',
        'Name': _nameController.text.trim(),
        'LicenseNumber': _licenseController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'VehicleNumber': _vehicleNumberController.text.trim(),
        'UserType': 'Driver',
        'CreatedAt': DateTime.now().toIso8601String(),
        'IsVerified': false,
        'Rating': 5.0,
        'TotalDeliveries': 0,
      };

      await DatabaseMethods().addDriverDetail(driverInfoMap, customId);

      await SharedpreferenceHelper().saveUserId(customId);
      await SharedpreferenceHelper().saveUserName(_nameController.text.trim());
      await SharedpreferenceHelper().saveUserEmail(
        _emailController.text.trim(),
      );
      await SharedpreferenceHelper().saveUserType('Driver');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF57C00),
          content: Text('Sign up successful! Welcome Driver!'),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DriverBottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(e.message ?? 'Sign up failed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
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
          const SizedBox(height: 10),
          Image.asset(
            "images/fast-delivery.png",
            height: 190,
            fit: BoxFit.contain,
          ),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                const Text(
                  'Driver Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const Text(
                  'Join Quick Parcel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Start earning with deliveries',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                      // Name Field
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // License Number Field
                      CustomTextField(
                        label: 'License Number',
                        hint: 'Enter your license number',
                        prefixIcon: Icons.badge_outlined,
                        controller: _licenseController,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter license number'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Vehicle Number Field
                      CustomTextField(
                        label: 'Vehicle Number',
                        hint: 'Enter vehicle number (e.g., ABC-1234)',
                        prefixIcon: Icons.directions_car,
                        controller: _vehicleNumberController,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter vehicle number'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Phone Field
                      CustomTextField(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        primaryColor: const Color(0xFFF57C00),
                        validator: _validatePhoneNumber,
                      ),

                      const SizedBox(height: 12),

                      // Email Field
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

                      const SizedBox(height: 12),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        primaryColor: const Color(0xFFF57C00),
                        validator: _validatePassword,
                      ),

                      const SizedBox(height: 12),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        primaryColor: const Color(0xFFF57C00),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Confirm password';
                          if (value != _passwordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Terms Checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) => setState(
                                () => _agreeToTerms = value ?? false,
                              ),
                              activeColor: const Color(0xFFF57C00),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'terms & policy',
                                  style: const TextStyle(
                                    color: Color(0xFFF57C00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // terms screen/url
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Sign Up Button
                      AppWidget.primaryActionButton(
                        context: context,
                        label: 'Sign up',
                        color: _primary,
                        loading: _loading,
                        onPressed: _loading ? null : _handleSignUp,
                      ),

                      const SizedBox(height: 20),

                      // Login Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
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
                                            const DriverLoginScreen(),
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
