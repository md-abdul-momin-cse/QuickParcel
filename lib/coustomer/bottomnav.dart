import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_parcel/coustomer/customer_chat_inbox.dart';
import 'package:quick_parcel/coustomer/homepage.dart';
import 'package:quick_parcel/coustomer/my_packages.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  String? _customerId;

  final List<Widget> _screens = const [
    HomeScreen(),
    SendPackage(),
    CustomerChatInboxPage(),
    MyPackagesPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    final id = await SharedpreferenceHelper().getUserId();
    if (!mounted) return;
    setState(() => _customerId = id);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _chatIcon({required bool active}) {
    final icon = Icon(
      active ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
      size: 40,
    );
    final customerId = _customerId;
    if (customerId == null || customerId.isEmpty) return icon;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DatabaseMethods().getCustomerOrderChats(customerId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final driverKeys = <String>{};
        final database = DatabaseMethods();

        for (final doc in docs) {
          final data = doc.data();
          final lastMessage = (data['LastMessage'] ?? '').toString().trim();
          if (lastMessage.isEmpty) continue;

          final driverId = (data['DriverId'] ?? '').toString();
          final chatId = (data['ChatId'] ?? '').toString();
          if (chatId != database.accountChatId(customerId, driverId)) {
            continue;
          }

          final sentByDriver =
              (data['LastSenderRole'] ?? '').toString().toLowerCase() ==
              'driver';
          if (!sentByDriver) continue;

          final driverName = (data['DriverName'] ?? '').toString();
          driverKeys.add(
            driverId.isNotEmpty
                ? driverId
                : driverName.isNotEmpty
                ? driverName
                : (data['OrderId'] ?? doc.id).toString(),
          );
        }

        final unreadCount = driverKeys.length;
        if (unreadCount == 0) return icon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              top: -2,
              right: -7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.1),
              blurRadius: isDark ? 20 : 14,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 40),
                activeIcon: Icon(Icons.home, size: 40),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/send_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                activeIcon: Image.asset(
                  'images/send_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Send',
              ),
              BottomNavigationBarItem(
                icon: _chatIcon(active: false),
                activeIcon: _chatIcon(active: true),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/my_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                activeIcon: Image.asset(
                  'images/my_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Packages',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Packages Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
