import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/shared/order_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingPage extends StatefulWidget {
  final String? trackingId;

  const LiveTrackingPage({super.key, this.trackingId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  static const Color _primary = Color(0xFF0D7D8F);

  String? _userId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = await SharedpreferenceHelper().getUserId();
    if (mounted) {
      setState(() {
        _userId = uid;
        _loadingUser = false;
      });
    }
  }

  //  stream helpers ─

  Stream<QuerySnapshot<Map<String, dynamic>>> _parcelStream() {
    if (_userId == null) {
      return const Stream.empty();
    }
    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('Order');
    final trackingId = widget.trackingId?.trim();

    if (trackingId != null && trackingId.isNotEmpty) {
      return ordersRef
          .where('OrderId', isEqualTo: trackingId)
          .limit(1)
          .snapshots();
    }

    return ordersRef
        .orderBy('CreatedAt', descending: true)
        .snapshots();
  }

  //  status helpers ─

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'assigned':
      case 'accepted':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'received':
        return const Color(0xFF0D9488);
      case 'in transit':
        return _primary;
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    return _statusColor(status).withOpacity(0.14);
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'assigned':
      case 'accepted':
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'received':
        return Icons.inventory_2_outlined;
      case 'in transit':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  int _statusStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'assigned':
      case 'accepted':
      case 'confirmed':
        return 1;
      case 'received':
        return 2;
      case 'in transit':
        return 3;
      case 'delivered':
        return 4;
      default:
        return -1;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  //  build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          //  Header ─
          Container(
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
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Live Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
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
          ),

          //  Body ─
          Expanded(
            child: _loadingUser
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _userId == null
                ? _emptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Please log in to view live tracking',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _parcelStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _primary),
                        );
                      }
                      if (snapshot.hasError) {
                        return _emptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'Failed to load tracking data',
                        );
                      }
                      final allDocs = snapshot.data?.docs ?? [];
                      if (allDocs.isEmpty) {
                        final trackingId = widget.trackingId?.trim();
                        return _emptyState(
                          icon: Icons.inbox_outlined,
                          message: trackingId == null || trackingId.isEmpty
                              ? 'No active deliveries.\nSend a package to get started!'
                              : 'No package found for $trackingId',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: allDocs.length,
                        itemBuilder: (context, index) {
                          final data = allDocs[index].data();
                          return _trackingCard(data);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  //  tracking card ─

  Widget _trackingCard(Map<String, dynamic> data) {
    final orderId = (data['OrderId'] ?? '').toString();
    if (orderId.isEmpty) {
      return _trackingCardContent(data);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Order')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final latestData = snapshot.data?.data();
        final mergedData = latestData == null
            ? data
            : <String, dynamic>{...data, ...latestData, 'OrderId': orderId};
        return _trackingCardContent(mergedData);
      },
    );
  }

  Widget _trackingCardContent(Map<String, dynamic> data) {
    final status = data['Status'] ?? 'Pending';
    final orderId = data['OrderId'] ?? '';
    final createdAt = data['CreatedAt'] ?? '';
    final price = data['Price'] ?? '0';
    final pickup = data['PickupAddress'] ?? '';
    final dropoff = data['DropoffAddress'] ?? '';
    final sender = data['SenderName'] ?? '';
    final receiver = data['ReceiverName'] ?? '';
    final packageSize = data['PackageSize'] ?? '';
    final distance = data['Distance'] ?? '';
    final photoUrl = data['PackagePhoto'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppWidget.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: _trackingNumberRow(orderId.toString())),
                _statusBadge(status),
              ],
            ),
          ),

          if (photoUrl.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: MyPackagesWidgets.packageImage(photoUrl.toString()),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _routeRow(pickup.toString(), dropoff.toString()),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _detailChip(Icons.person_outline_rounded, sender.toString()),
                const SizedBox(width: 8),
                _detailChip(Icons.person_pin_outlined, receiver.toString()),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _detailChip(
                  Icons.inventory_2_outlined,
                  packageSize.toString(),
                ),
                const SizedBox(width: 8),
                _detailChip(Icons.route_outlined, distance.toString()),
              ],
            ),
          ),

          _driverInfoSection(data),

          if (status.toString().toLowerCase() != 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _progressTracker(status.toString()),
            ),

          if (_driverIdFromOrder(data).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openOrderChat(data),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat with Driver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppWidget.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    '৳ $price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingNumberRow(String orderId) {
    return Row(
      children: [
        Expanded(
          child: Text(
            orderId,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppWidget.textPrimaryColor,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _copyTrackingNumber(orderId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              Icons.copy_rounded,
              color: AppWidget.textSecondaryColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _driverInfoSection(Map<String, dynamic> data) {
    final driverId = _driverIdFromOrder(data);
    final cachedName = (data['DriverName'] ?? '').toString();
    final cachedPhone = (data['DriverPhone'] ?? '').toString();

    if (driverId.isEmpty && cachedName.isEmpty) {
      return const SizedBox.shrink();
    }

    if (cachedName.isNotEmpty || driverId.isEmpty) {
      return _driverChip(
        name: cachedName.isNotEmpty ? cachedName : 'Driver',
        phone: cachedPhone,
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: DatabaseMethods().getDriverDetail(driverId),
      builder: (context, snapshot) {
        final driver = snapshot.data?.data();
        final name = (driver?['Name'] ?? 'Driver').toString();
        final phone = (driver?['Phone'] ?? '').toString();
        return _driverChip(name: name, phone: phone);
      },
    );
  }

  Widget _driverChip({required String name, required String phone}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => _showDriverPhone(name, phone),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: _primary,
                  size: 14,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _driverIdFromOrder(Map<String, dynamic> data) {
    return (data['AcceptedBy'] ??
            data['AssignedDriver'] ??
            data['DriverId'] ??
            '')
        .toString();
  }

  Future<void> _openOrderChat(Map<String, dynamic> data) async {
    final orderId = (data['OrderId'] ?? '').toString();
    final driverId = _driverIdFromOrder(data);
    final userId = _userId ?? await SharedpreferenceHelper().getUserId() ?? '';

    if (orderId.isEmpty || userId.isEmpty || driverId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat will be available after driver assignment'),
        ),
      );
      return;
    }

    final helper = SharedpreferenceHelper();
    final savedName = await helper.getUserName();
    final customerName =
        (savedName ?? data['SenderName'] ?? data['CustomerName'] ?? 'Customer')
            .toString();
    final driverName = (data['DriverName'] ?? 'Driver').toString();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatPage(
          orderId: orderId,
          customerId: userId,
          driverId: driverId,
          customerName: customerName,
          driverName: driverName,
          currentUserId: userId,
          currentUserName: customerName,
          currentUserRole: 'Customer',
          primaryColor: _primary,
        ),
      ),
    );
  }

  Future<void> _copyTrackingNumber(String orderId) async {
    if (orderId.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: orderId));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tracking number copied')));
  }

  void _showDriverPhone(String name, String phone) {
    final cleanPhone = phone.trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: cleanPhone.isEmpty
            ? const Text('Driver phone number is not available yet.')
            : InkWell(
                onTap: () => _openDialer(cleanPhone),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, color: _primary),
                      const SizedBox(width: 10),
                      Text(
                        cleanPhone,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  Widget _progressTracker(String status) {
    final steps = ['Pending', 'Confirmed', 'Received', 'In Transit', 'Delivered'];
    final currentStep = _statusStep(status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone ? _primary : AppWidget.borderColor,
            ),
          );
        }

        final stepIdx = i ~/ 2;
        final isDone = stepIdx <= currentStep;
        final isCurrent = stepIdx == currentStep;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? _primary : AppWidget.surfaceAltColor,
                border: Border.all(
                  color: isDone ? _primary : AppWidget.borderColor,
                  width: isCurrent ? 2.5 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isDone ? Icons.check_rounded : _stepIcon(stepIdx),
                size: 13,
                color: isDone ? Colors.white : AppWidget.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIdx],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? _primary : AppWidget.textSecondaryColor,
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _stepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.access_time_rounded;
      case 1:
        return Icons.check_circle_outline_rounded;
      case 2:
        return Icons.inventory_2_outlined;
      case 3:
        return Icons.local_shipping_outlined;
      case 4:
        return Icons.done_all_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _routeRow(String pickup, String dropoff) =>
      MyPackagesWidgets.routeRow(pickup: pickup, dropoff: dropoff);

  Widget _detailChip(IconData icon, String label) =>
      MyPackagesWidgets.detailChip(icon: icon, label: label);

  //  status badge ─

  Widget _statusBadge(String status) {
    final safeStatus = status.isEmpty ? 'Pending' : status;
    return MyPackagesWidgets.statusBadge(
      status: safeStatus,
      statusColor: _statusColor(safeStatus),
    );
  }

  //  empty state

  Widget _emptyState({required IconData icon, required String message}) {
    return MyPackagesWidgets.emptyState(icon: icon, message: message);
  }
}
