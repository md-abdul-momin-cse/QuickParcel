import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/shared/order_chat_page.dart';

class DriverChatInboxPage extends StatefulWidget {
  const DriverChatInboxPage({super.key});

  @override
  State<DriverChatInboxPage> createState() => _DriverChatInboxPageState();
}

class _DriverChatInboxPageState extends State<DriverChatInboxPage> {
  static const Color _primary = Color(0xFFF57C00);

  String? _driverId;
  String _driverName = 'Driver';
  bool _loadingDriver = true;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    final helper = SharedpreferenceHelper();
    final id = await helper.getUserId();
    final name = await helper.getUserName();
    if (!mounted) return;

    setState(() {
      _driverId = id;
      _driverName = name ?? 'Driver';
      _loadingDriver = false;
    });
  }

  DateTime _chatTime(Map<String, dynamic> data) {
    final value = data['LastMessageAt'] ?? data['UpdatedAt'] ?? data['CreatedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    return DateTime(1970);
  }

  String _formatChatTime(Map<String, dynamic> data) {
    final dt = _chatTime(data);
    if (dt.year == 1970) return '';

    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    }

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<Map<String, dynamic>> _customerChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final latestByCustomer = <String, Map<String, dynamic>>{};

    for (final doc in docs) {
      final data = doc.data();
      final lastMessage = (data['LastMessage'] ?? '').toString().trim();
      if (lastMessage.isEmpty) continue;

      final customerId = (data['CustomerId'] ?? '').toString();
      final driverId = (data['DriverId'] ?? _driverId ?? '').toString();
      final chatId = (data['ChatId'] ?? '').toString();
      if (chatId != DatabaseMethods().accountChatId(customerId, driverId)) {
        continue;
      }

      final customerName = (data['CustomerName'] ?? '').toString();
      final key = customerId.isNotEmpty
          ? customerId
          : customerName.isNotEmpty
          ? customerName
          : (data['OrderId'] ?? doc.id).toString();
      final existing = latestByCustomer[key];

      if (existing == null || _chatTime(data).isAfter(_chatTime(existing))) {
        latestByCustomer[key] = data;
      }
    }

    final chats = latestByCustomer.values.toList();
    chats.sort((a, b) => _chatTime(b).compareTo(_chatTime(a)));
    return chats;
  }

  bool _hasCustomerMessage(Map<String, dynamic> data) {
    return (data['LastSenderRole'] ?? '').toString().toLowerCase() == 'customer';
  }

  Future<void> _openChat(Map<String, dynamic> data) async {
    final orderId = (data['OrderId'] ?? '').toString();
    final driverId = (_driverId ?? data['DriverId'] ?? '').toString();
    final customerId = (data['CustomerId'] ?? '').toString();
    final customerName = (data['CustomerName'] ?? 'Customer').toString();
    final driverName = (data['DriverName'] ?? _driverName).toString();

    if (orderId.isEmpty || driverId.isEmpty || customerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat is not available for this order')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatPage(
          orderId: orderId,
          customerId: customerId,
          driverId: driverId,
          customerName: customerName,
          driverName: driverName,
          currentUserId: driverId,
          currentUserName: driverName,
          currentUserRole: 'Driver',
          primaryColor: _primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _loadingDriver
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : (_driverId == null || _driverId!.isEmpty)
                    ? _emptyState(
                        icon: Icons.person_off_outlined,
                        message: 'Driver profile not found',
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: DatabaseMethods().getDriverOrderChats(_driverId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: _primary),
                            );
                          }
                          if (snapshot.hasError) {
                            return _emptyState(
                              icon: Icons.error_outline_rounded,
                              message: 'Failed to load chats',
                            );
                          }

                          final chats = _customerChats(
                            snapshot.data?.docs ?? [],
                          );
                          if (chats.isEmpty) {
                            return _emptyState(
                              icon: Icons.chat_bubble_outline_rounded,
                              message: 'No customer messages yet',
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              return _chatTile(chats[index]);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Customer Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Inbox',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatTile(Map<String, dynamic> data) {
    final customerName = (data['CustomerName'] ?? 'Customer').toString();
    final lastMessage = (data['LastMessage'] ?? '').toString();
    final hasCustomerMessage = _hasCustomerMessage(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCustomerMessage
              ? _primary.withOpacity(0.45)
              : AppWidget.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppWidget.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_outline_rounded, color: _primary),
            ),
            if (hasCustomerMessage)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppWidget.surfaceColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          customerName,
          style: TextStyle(
            color: AppWidget.textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account conversation',
                style: TextStyle(
                  color: AppWidget.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                style: TextStyle(
                  color: hasCustomerMessage
                      ? AppWidget.textPrimaryColor
                      : AppWidget.textSecondaryColor,
                  fontSize: 13,
                  fontWeight: hasCustomerMessage ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatChatTime(data),
              style: TextStyle(
                color: AppWidget.textSecondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Icon(Icons.chevron_right_rounded, color: AppWidget.textSecondaryColor),
          ],
        ),
        onTap: () => _openChat(data),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return MyPackagesWidgets.emptyState(icon: icon, message: message);
  }
}
