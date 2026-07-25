import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/driver/driver_all_orders.dart';
import 'package:quick_parcel/driver/driver_chat_inbox.dart';
import 'package:quick_parcel/driver/driver_homepage.dart';
import 'package:quick_parcel/driver/driver_profile.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class DriverBottomNav extends StatefulWidget {
  const DriverBottomNav({super.key});

  @override
  State<DriverBottomNav> createState() => _DriverBottomNavState();
}

class _DriverBottomNavState extends State<DriverBottomNav> {
  static const Color _primary = Color(0xFFF57C00);

  int _selectedIndex = 0;
  String? _driverId;

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const DriverAllOrdersPage(),
    const DriverChatInboxPage(),
    const DriverProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverId();
  }

  Future<void> _loadDriverId() async {
    final id = await SharedpreferenceHelper().getUserId();
    if (!mounted) return;
    setState(() => _driverId = id);
  }

  Widget _chatIcon({required bool active}) {
    final icon = Icon(
      active ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
      size: 40,
    );
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty) return icon;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DatabaseMethods().getDriverOrderChats(driverId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final customerKeys = <String>{};
        for (final doc in docs) {
          final data = doc.data();
          final lastMessage = (data['LastMessage'] ?? '').toString().trim();
          if (lastMessage.isEmpty) continue;

          final customerId = (data['CustomerId'] ?? '').toString();
          final chatId = (data['ChatId'] ?? '').toString();
          if (chatId != DatabaseMethods().accountChatId(customerId, driverId)) {
            continue;
          }

          final sentByCustomer =
              (data['LastSenderRole'] ?? '').toString().toLowerCase() ==
              'customer';
          if (!sentByCustomer) continue;

          final customerName = (data['CustomerName'] ?? '').toString();
          customerKeys.add(
            customerId.isNotEmpty
                ? customerId
                : customerName.isNotEmpty
                ? customerName
                : (data['OrderId'] ?? doc.id).toString(),
          );
        }
        final unreadCount = customerKeys.length;

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
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 40),
                activeIcon: Icon(Icons.home, size: 40),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined, size: 40),
                activeIcon: Icon(Icons.receipt_long, size: 40),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _chatIcon(active: false),
                activeIcon: _chatIcon(active: true),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined, size: 40),
                activeIcon: Icon(Icons.person, size: 40),
                label: 'Profile',
              ),
            ],
            selectedItemColor: _primary,
            unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
            backgroundColor: Theme.of(context).colorScheme.surface,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
