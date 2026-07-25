import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_parcel/coustomer/billing_page.dart';
import 'package:quick_parcel/coustomer/profile.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';
import 'package:quick_parcel/coustomer/my_packages.dart';
import 'package:quick_parcel/coustomer/live_tracking.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _trackingController = TextEditingController();

  String userName = 'User';
  String userType = 'Customer';
  String? profileImageUrl;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final helper = SharedpreferenceHelper();
      final name = await helper.getUserName();
      final userId = await helper.getUserId();

      if (mounted) {
        setState(() {
          userName = name ?? 'User';
        });
      }

      if (userId != null) {
        final doc = await DatabaseMethods().getUserDetail(userId);
        if (doc.exists && mounted) {
          setState(() {
            profileImageUrl = doc.data()?['PhotoUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _openBillingFromHome() async {
    try {
      final helper = SharedpreferenceHelper();
      final userId = await helper.getUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view billing.')),
        );
        return;
      }

      final ordersSnapshot = await DatabaseMethods()
          .getUserOrders(userId)
          .first;
      final unpaidBills = <UnpaidBillItem>[];

      for (final doc in ordersSnapshot.docs) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {};
        final paymentStatus = (data['PaymentStatus'] ?? '').toString();
        if (paymentStatus == 'Paid') {
          continue;
        }

        final orderId = (data['OrderId'] ?? doc.id).toString();
        final amount = _parseAmount(data['Price']);
        final senderName =
            (data['SenderName'] ?? data['ReceiverName'] ?? userName).toString();
        final senderPhone = (data['SenderPhone'] ?? data['ReceiverPhone'] ?? '')
            .toString();
        final receiverName =
            (data['ReceiverName'] ?? data['SenderName'] ?? 'Receiver')
                .toString();
        final receiverPhone =
            (data['ReceiverPhone'] ?? data['SenderPhone'] ?? '').toString();
        final pickupAddress = (data['PickupAddress'] ?? '').toString();
        final dropoffAddress = (data['DropoffAddress'] ?? '').toString();
        final packageSize = (data['PackageSize'] ?? '').toString();
        final packageDescription = (data['PackageDescription'] ?? '')
            .toString();
        final distance = (data['Distance'] ?? '').toString();
        final estimatedTime = (data['EstimatedTime'] ?? '').toString();
        final createdAt = (data['CreatedAt'] ?? '').toString();

        unpaidBills.add(
          UnpaidBillItem(
            orderId: orderId,
            amount: amount,
            senderName: senderName,
            senderPhone: senderPhone,
            receiverName: receiverName,
            receiverPhone: receiverPhone,
            pickupAddress: pickupAddress,
            dropoffAddress: dropoffAddress,
            packageSize: packageSize,
            packageDescription: packageDescription,
            distance: distance,
            estimatedTime: estimatedTime,
            createdAt: createdAt,
          ),
        );
      }

      if (!mounted) return;

      if (unpaidBills.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No unpaid bill found.')));
        return;
      }
      final customerEmail =
          FirebaseAuth.instance.currentUser?.email ??
          'customer@quickparcel.com';

      final result = await Navigator.push<BillingResult>(
        context,
        MaterialPageRoute(
          builder: (_) => BillingPage.unpaid(
            unpaidBills: unpaidBills,
            customerEmail: customerEmail,
          ),
        ),
      );

      if (!mounted || result == null) return;
      final orderId = result.orderId;

      final updateData = {
        'PaymentStatus': result.paymentStatus,
        'PaymentMethod': result.paymentMethod,
        'PaymentProvider': result.paymentProvider,
        'PaidAmount': result.paidAmount.toStringAsFixed(0),
        'TransactionId': result.transactionId ?? '',
        'UpdatedAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Order')
          .doc(orderId)
          .update(updateData);

      await FirebaseFirestore.instance
          .collection('Order')
          .doc(orderId)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.paymentStatus == 'Paid'
                ? 'Payment successful for bill $orderId'
                : 'Billing updated for order $orderId',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Billing failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _searchTrackingNumber() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracking number'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final userId = await SharedpreferenceHelper().getUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to track your package.')),
        );
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Order')
          .where('OrderId', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (!mounted) return;
      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No package found for $trackingNumber')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveTrackingPage(trackingId: trackingNumber),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tracking search failed: $e')));
    }
  }

  // profile pic
  Widget _buildProfilePicture(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _loadingProfile
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
            : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
            ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person,
                  size: 35,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : const Icon(Icons.person, size: 35, color: Color(0xFF0D7D8F)),
      ),
    );
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      // profile pic
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                          // refresh profile data when returning
                          _loadUserInfo();
                        },
                        child: _buildProfilePicture(context),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userType,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // search track
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Your Package',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Enter your tracking number to get live updates',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.14)
                                        : const Color(
                                            0xFF172F35,
                                          ).withOpacity(0.72),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.26 : 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _trackingController,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) => _searchTrackingNumber(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.color,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: 'Enter tracking number',
                                    hintStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: _searchTrackingNumber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/send_package.png',
                    label: 'Manage Parcels',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SendPackage()),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/my_package.png',
                    label: 'My package',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPackagesPage(),
                        ),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/live_traking.png',
                    label: 'Live tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveTrackingPage(),
                        ),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/billing.png',
                    label: 'Billing',
                    onTap: _openBillingFromHome,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
