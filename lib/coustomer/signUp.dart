import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/find_driver.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/services/pending_order_service.dart';
import 'package:random_string/random_string.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/models/order_model.dart';

class SignUpScreen extends StatefulWidget {
  final OrderData? pendingOrderData;

  const SignUpScreen({super.key, this.pendingOrderData});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nidController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _autoFillOrderData();
  }

  void _autoFillOrderData() {
    if (widget.pendingOrderData != null) {
      final data = widget.pendingOrderData!;
      if (data.senderName != null && data.senderName!.isNotEmpty) {
        _nameController.text = data.senderName!;
      }
      if (data.senderPhone != null && data.senderPhone!.isNotEmpty) {
        _phoneController.text = data.senderPhone!;
      }
      if (data.senderEmail != null && data.senderEmail!.isNotEmpty) {
        _emailController.text = data.senderEmail!;
      }
      if (data.senderNid != null && data.senderNid!.isNotEmpty) {
        _nidController.text = data.senderNid!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nidController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateStrongPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Enter password';
    if (password.length < 8) return 'Password must be at least 8 characters';
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
          backgroundColor: Colors.orange,
          content: Text('Please fill all fields correctly'),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
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

      final userInfoMap = {
        'Id': customId,
        'FirebaseUid': credential.user?.uid ?? '',
        'Name': _nameController.text.trim(),
        'NID': _nidController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'CreatedAt': DateTime.now().toIso8601String(),
      };

      await DatabaseMethods().addUserDetail(userInfoMap, customId);

      await SharedpreferenceHelper().saveUserId(customId);
      await SharedpreferenceHelper().saveUserName(_nameController.text.trim());
      await SharedpreferenceHelper().saveUserEmail(
        _emailController.text.trim(),
      );
      await SharedpreferenceHelper().saveUserType('Customer');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Registration successful!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Check if there's a pending order
        if (widget.pendingOrderData != null) {
          // Place the pending order and navigate to Find Driver
          await _placePendingOrder(customId);
        } else {
          // No pending order, go to home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNav()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message =
              'Password is too weak. Use uppercase, lowercase, number and special character.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered. Try logging in.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          message = 'Email/Password authentication is not enabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _placePendingOrder(String userId) async {
    try {
      final orderData = widget.pendingOrderData!;
      final orderId = 'QP-${DateTime.now().millisecondsSinceEpoch}';

      final orderInfo = {
        'OrderId': orderId,
        'UserId': userId,
        'SenderName': orderData.senderName ?? '',
        'SenderPhone': orderData.senderPhone ?? '',
        'ReceiverName': orderData.recipientName ?? '',
        'ReceiverPhone': orderData.recipientPhone ?? '',
        'PickupAddress': orderData.pickupAddress,
        'DropoffAddress': orderData.dropoffAddress,
        'PackageSize': orderData.packageSize,
        'PackageDescription': orderData.packageDescription,
        'Distance': orderData.distance,
        'EstimatedTime': orderData.estimatedTime,
        'Price': orderData.estimatedPrice.toStringAsFixed(0),
        'PaymentStatus': 'Unpaid',
        'PaymentMethod': 'Pending',
        'PaymentProvider': '',
        'PaidAmount': 0,
        'TransactionId': '',
        'Status': 'Pending',
        'CreatedAt': DateTime.now().toIso8601String(),
      };

      await DatabaseMethods().addUserOrder(orderInfo, userId, orderId);
      await DatabaseMethods().addAdminOrder(orderInfo, orderId);

      // Clear the pending order from storage
      await PendingOrderService.clearPendingOrder();

      if (mounted) {
        // Navigate to Find Driver
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FindDriverScreen(
              orderId: orderId,
              pickupLat: orderData.pickupLat.toString(),
              pickupLng: orderData.pickupLng.toString(),
              dropoffLat: orderData.dropoffLat.toString(),
              dropoffLng: orderData.dropoffLng.toString(),
              pickupAddress: orderData.pickupAddress,
              dropoffAddress: orderData.dropoffAddress,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error placing pending order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error placing order: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Image.asset("images/Coustomer_signup.png", height: 200, 
          fit: BoxFit.contain),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const Text(
                  'Sign up',
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
                  'Faster deliveries start here',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
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
                        label: 'Name',
                        hint: 'Enter your name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // NID Number Field
                      CustomTextField(
                        label: 'NID Number',
                        hint: 'Enter your NID number',
                        prefixIcon: Icons.badge_outlined,
                        controller: _nidController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter NID number';
                          if (value.length < 10) return 'Invalid NID number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Phone Field
                      CustomTextField(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
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
                        validator: _validateStrongPassword,
                      ),

                      const SizedBox(height: 12),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Re-enter password',
                        hint: 'Confirm password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
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
                              activeColor: theme.primaryColor,
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
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      //  terms screen/url
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
                        loading: _loading,
                        onPressed: _loading ? null : _handleSignUp,
                      ),

                      const SizedBox(height: 12),

                      // Sign In
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Have an account? ',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: AppWidget.GreenTextfeildStyle(16.0),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
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
