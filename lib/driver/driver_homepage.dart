import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/services/driver_location_service.dart';
import 'package:quick_parcel/driver/driver_verified_badge.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const Color _primary = Color(0xFFF57C00);

  String driverName = 'Driver';
  String driverEmail = '';
  String driverId = '';
  double rating = 5.0;
  int totalDeliveries = 0;
  bool _loadingProfile = true;
  bool _loadingOrders = true;
  bool _isLocationEnabled = false;

  List<Map<String, dynamic>> availableOrders = [];
  List<Map<String, dynamic>> activeOrders = [];
  final Set<String> _updatingOrderIds = {};

  final DriverLocationService _locationService = DriverLocationService();

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _loadAvailableOrders();
    _loadActiveOrders();
  }

  @override
  void dispose() {
    // Stop location tracking when screen is disposed
    if (_isLocationEnabled) {
      _locationService.stopLocationTracking(driverId);
    }
    super.dispose();
  }

  Future<void> _toggleLocationTracking() async {
    try {
      if (_isLocationEnabled) {
        // Turn off location tracking
        try {
          await _locationService.stopLocationTracking(driverId);
        } catch (e) {
          print('Error stopping location: $e');
        }
        setState(() => _isLocationEnabled = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location sharing disabled'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (driverId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Driver ID not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Turn on location tracking
        try {
          await _locationService.startLocationTracking(driverId);
          setState(() => _isLocationEnabled = true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Location sharing enabled',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFF4CAF50),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDriverInfo() async {
    try {
      final helper = SharedpreferenceHelper();
      final name = await helper.getUserName();
      final email = await helper.getUserEmail();
      final userId = await helper.getUserId();

      if (mounted) {
        setState(() {
          driverName = name ?? 'Driver';
          driverEmail = email ?? '';
          driverId = userId ?? '';
        });
      }

      if (userId != null) {
        if (!_locationService.isTracking) {
          await DatabaseMethods().updateDriverAvailability(userId, false);
        }

        final doc = await DatabaseMethods().getDriverDetail(userId);
        if (doc.exists && mounted) {
          setState(() {
            rating = doc.data()?['Rating'] ?? 5.0;
            totalDeliveries = doc.data()?['TotalDeliveries'] ?? 0;
            _isLocationEnabled = _locationService.isTracking;
          });
        }
        await _loadActiveOrders();
      }
    } catch (e) {
      debugPrint('Error loading driver info: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _loadAvailableOrders() async {
    try {
      setState(() => _loadingOrders = true);

      final orders = await DatabaseMethods().getAvailableOrders();

      if (mounted) {
        setState(() {
          availableOrders = orders;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingOrders = false);
      }
    }
  }

  Future<void> _loadActiveOrders() async {
    try {
      if (driverId.isEmpty) return;

      final orders = await DatabaseMethods().getDriverActiveOrders(driverId);

      if (mounted) {
        setState(() {
          activeOrders = orders;
        });
      }
    } catch (e) {
      debugPrint('Error loading active orders: $e');
    }
  }

  String _shortOrderId(dynamic orderId) {
    final id = (orderId ?? '').toString();
    if (id.isEmpty) return 'N/A';
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await DatabaseMethods().acceptOrder(orderId, driverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Order accepted! Start navigation',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );

        _loadActiveOrders();
        _loadAvailableOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await DatabaseMethods().declineOrder(orderId, driverId: driverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // Reload orders
        _loadActiveOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptOrderFromCustomer(String orderId, String driverId) async {
    try {
      await _acceptOrder(orderId);
      _loadAvailableOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineOrderFromCustomer(String orderId) async {
    try {
      await _rejectOrder(orderId);
      _loadAvailableOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _orderId(Map<String, dynamic> order) {
    return (order['OrderId'] ?? order['id'] ?? '').toString();
  }

  String _orderText(
    Map<String, dynamic> order,
    List<String> keys, {
    String fallback = 'N/A',
  }) {
    for (final key in keys) {
      final value = (order[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  int _deliveryStep(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return 0;
      case 'received':
        return 1;
      case 'in transit':
        return 2;
      case 'delivered':
        return 3;
      default:
        return -1;
    }
  }

  String? _nextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return 'In Transit';
      case 'received':
        return 'In Transit';
      case 'in transit':
        return 'Delivered';
      default:
        return null;
    }
  }

  String _nextStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return 'Mark Received';
      case 'received':
        return 'Start Delivery';
      case 'in transit':
        return 'Mark Delivered';
      case 'delivered':
        return 'Completed';
      default:
        return 'Update Status';
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    if (orderId.isEmpty || driverId.isEmpty) return;

    setState(() => _updatingOrderIds.add(orderId));
    try {
      await DatabaseMethods().updateDeliveryStatus(
        orderId: orderId,
        driverId: driverId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $status'),
            backgroundColor: status == 'Delivered'
                ? const Color(0xFF22C55E)
                : _primary,
          ),
        );
      }

      await _loadActiveOrders();
      await _loadAvailableOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final orderId = _orderId(order);
    if (orderId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: DatabaseMethods().getOrderStream(orderId),
                builder: (context, snapshot) {
                  final liveData = snapshot.data?.data();
                  final data = liveData == null
                      ? <String, dynamic>{...order, 'OrderId': orderId}
                      : <String, dynamic>{
                          ...order,
                          ...liveData,
                          'OrderId': orderId,
                        };

                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    child: _orderDetailsContent(data),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _orderDetailsContent(Map<String, dynamic> order) {
    final orderId = _orderId(order);
    final status = _orderText(order, ['Status'], fallback: 'Confirmed');
    final nextStatus = _nextStatus(status);
    final updating = _updatingOrderIds.contains(orderId);
    final pickup = _orderText(order, ['PickupAddress', 'PickupLocation']);
    final dropoff = _orderText(order, ['DropoffAddress', 'DeliveryLocation']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppWidget.borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Order #${_shortOrderId(orderId)}',
                style: TextStyle(
                  color: AppWidget.textPrimaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _statusPill(status),
          ],
        ),
        const SizedBox(height: 18),
        _driverTimeline(status),
        const SizedBox(height: 22),
        _sectionTitle('Route'),
        const SizedBox(height: 10),
        _routeInfoCard(pickup: pickup, dropoff: dropoff),
        const SizedBox(height: 18),
        _sectionTitle('Parcel Details'),
        const SizedBox(height: 10),
        _detailRow(
          Icons.inventory_2_outlined,
          'Package',
          _orderText(order, ['PackageSize'], fallback: 'Package'),
        ),
        _detailRow(
          Icons.notes_outlined,
          'Description',
          _orderText(order, ['PackageDescription'], fallback: 'No description'),
        ),
        _detailRow(
          Icons.route_outlined,
          'Distance',
          _orderText(order, ['Distance'], fallback: 'N/A'),
        ),
        _detailRow(
          Icons.payments_outlined,
          'Fare',
          '৳ ${_orderText(order, ['Price'], fallback: '0')}',
        ),
        const SizedBox(height: 18),
        _sectionTitle('Customer'),
        const SizedBox(height: 10),
        _detailRow(
          Icons.person_outline,
          'Sender',
          _orderText(order, ['SenderName'], fallback: 'Customer'),
        ),
        _detailRow(
          Icons.phone_outlined,
          'Sender Phone',
          _orderText(order, ['SenderPhone'], fallback: 'N/A'),
        ),
        _detailRow(
          Icons.person_pin_circle_outlined,
          'Receiver',
          _orderText(order, ['ReceiverName'], fallback: 'Receiver'),
        ),
        _detailRow(
          Icons.call_outlined,
          'Receiver Phone',
          _orderText(order, ['ReceiverPhone'], fallback: 'N/A'),
        ),
        const SizedBox(height: 24),
        if (nextStatus != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: updating
                  ? null
                  : () => _updateOrderStatus(orderId, nextStatus),
              icon: updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      nextStatus == 'Delivered'
                          ? Icons.done_all_rounded
                          : nextStatus == 'Received'
                          ? Icons.inventory_2_outlined
                          : Icons.local_shipping_outlined,
                    ),
              label: Text(_nextStatusLabel(status)),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextStatus == 'Delivered'
                    ? const Color(0xFF22C55E)
                    : _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.35),
              ),
            ),
            child: const Center(
              child: Text(
                'Delivery Completed',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppWidget.textPrimaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _routeInfoCard({required String pickup, required String dropoff}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppWidget.borderColor),
      ),
      child: Column(
        children: [
          _routeLine(Icons.my_location_rounded, 'Pickup', pickup, _primary),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 22,
                color: AppWidget.borderColor,
              ),
            ),
          ),
          _routeLine(
            Icons.location_on_rounded,
            'Dropoff',
            dropoff,
            const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  Widget _routeLine(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppWidget.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: AppWidget.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppWidget.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppWidget.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppWidget.textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverTimeline(String status) {
    final steps = ['Confirmed', 'Received', 'In Transit', 'Delivered'];
    final currentStep = _deliveryStep(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppWidget.borderColor),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final connector = index ~/ 2;
            final done = connector < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? _primary : AppWidget.borderColor,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final done = stepIndex <= currentStep;
          final current = stepIndex == currentStep;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _primary : AppWidget.surfaceAltColor,
                  border: Border.all(
                    color: current ? _primary : AppWidget.borderColor,
                    width: current ? 2 : 1,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : _timelineIcon(stepIndex),
                  size: 16,
                  color: done ? Colors.white : AppWidget.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  color: done ? _primary : AppWidget.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  IconData _timelineIcon(int step) {
    switch (step) {
      case 0:
        return Icons.task_alt_outlined;
      case 1:
        return Icons.inventory_2_outlined;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.done_all_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _statusPill(String status) {
    final delivered = status.toLowerCase() == 'delivered';
    final transit = status.toLowerCase() == 'in transit';
    final received = status.toLowerCase() == 'received';
    final color = delivered
        ? const Color(0xFF22C55E)
        : transit
        ? const Color(0xFF0EA5E9)
        : received
        ? const Color(0xFF0D9488)
        : _primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // Header Section
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Location Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleLocationTracking,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLocationEnabled
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isLocationEnabled
                                        ? Colors.green
                                        : Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isLocationEnabled
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      color: _isLocationEnabled
                                          ? Colors.green
                                          : Colors.white.withOpacity(0.7),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isLocationEnabled ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: _isLocationEnabled
                                            ? Colors.green
                                            : Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Driver Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          driverName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      DriverVerifiedBadge(
                                        driverId: driverId,
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (driverEmail.isNotEmpty)
                                    Text(
                                      driverEmail,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$rating',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '$totalDeliveries Deliveries',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // White Curved Content Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pending Order Notifications (Real-time)
                          if (driverId.isNotEmpty)
                            StreamBuilder<QuerySnapshot>(
                              stream: DatabaseMethods()
                                  .getDriverPendingOrdersStream(driverId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }

                                final pendingOrders = snapshot.data?.docs ?? [];

                                if (pendingOrders.isEmpty) {
                                  return const SizedBox();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.notifications_active,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pending Orders (${pendingOrders.length})',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppWidget.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: pendingOrders.length,
                                      itemBuilder: (context, index) {
                                        final order =
                                            pendingOrders[index].data()
                                                as Map<String, dynamic>;
                                        final orderId = pendingOrders[index].id;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppWidget.surfaceColor,
                                            border: Border(
                                              left: BorderSide(
                                                color: Colors.red.shade400,
                                                width: 4,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppWidget.shadowColor,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Order ID: ${_shortOrderId(orderId)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppWidget
                                                          .textPrimaryColor,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'New',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Pickup: ${order['PickupAddress'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppWidget
                                                      .textSecondaryColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Dropoff: ${order['DropoffAddress'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppWidget
                                                      .textSecondaryColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        _acceptOrderFromCustomer(
                                                          orderId,
                                                          driverId,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.check,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        'Accept',
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () {
                                                        _declineOrderFromCustomer(
                                                          orderId,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.close,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        'Decline',
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                        side: const BorderSide(
                                                          color: Colors.red,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),

                          // Active Orders Section
                          if (activeOrders.isNotEmpty) ...[
                            Text(
                              'Active Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppWidget.textPrimaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeOrders.length,
                              itemBuilder: (context, index) {
                                final order = activeOrders[index];
                                final orderId = _orderId(order);
                                final status = _orderText(order, [
                                  'Status',
                                ], fallback: 'Confirmed');
                                final nextStatus = _nextStatus(status);
                                final updating = _updatingOrderIds.contains(
                                  orderId,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: AppWidget.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primary.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppWidget.shadowColor,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${_shortOrderId(orderId)}',
                                            style: AppWidget.boldTextFieldStyle(
                                              14.0,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _primary.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ).copyWith(color: _primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: _primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _orderText(order, [
                                                'PickupAddress',
                                                'PickupLocation',
                                              ], fallback: 'Pickup location'),
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_off,
                                            color: _primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _orderText(
                                                order,
                                                [
                                                  'DropoffAddress',
                                                  'DeliveryLocation',
                                                ],
                                                fallback: 'Delivery location',
                                              ),
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      _driverTimeline(status),
                                      const SizedBox(height: 12),
                                      if (order['Status'] == 'Assigned')
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _rejectOrder(orderId),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                    width: 1.5,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Reject',
                                                  style:
                                                      AppWidget.boldTextFieldStyle(
                                                        12.0,
                                                      ).copyWith(
                                                        color: Colors.red,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _acceptOrder(orderId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _primary,
                                                ),
                                                child: Text(
                                                  'Accept',
                                                  style:
                                                      AppWidget.boldTextFieldStyle(
                                                        12.0,
                                                      ).copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _showOrderDetails(order),
                                                icon: const Icon(
                                                  Icons.receipt_long_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text('Details'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: _primary,
                                                  side: BorderSide(
                                                    color: _primary.withOpacity(
                                                      0.7,
                                                    ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    nextStatus == null ||
                                                        updating
                                                    ? null
                                                    : () => _updateOrderStatus(
                                                        orderId,
                                                        nextStatus,
                                                      ),
                                                icon: updating
                                                    ? const SizedBox(
                                                        width: 15,
                                                        height: 15,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : Icon(
                                                        nextStatus ==
                                                                'Delivered'
                                                            ? Icons
                                                                  .done_all_rounded
                                                            : nextStatus ==
                                                                  'Received'
                                                            ? Icons
                                                                  .inventory_2_outlined
                                                            : Icons
                                                                  .local_shipping_outlined,
                                                        size: 18,
                                                      ),
                                                label: Text(
                                                  _nextStatusLabel(status),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      nextStatus == 'Delivered'
                                                      ? const Color(0xFF22C55E)
                                                      : _primary,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Available Orders Section
                          Text(
                            'Available Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppWidget.textPrimaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingOrders)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: _primary,
                                ),
                              ),
                            )
                          else if (availableOrders.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No available orders',
                                  style: AppWidget.LightTextFieldStyle(14.0),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availableOrders.length,
                              itemBuilder: (context, index) {
                                final order = availableOrders[index];
                                final orderId = _orderId(order);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: AppWidget.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _primary.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppWidget.shadowColor,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${_shortOrderId(orderId)}',
                                            style: AppWidget.boldTextFieldStyle(
                                              14.0,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _primary.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Available',
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ).copyWith(color: _primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: _primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _orderText(order, [
                                                'PickupAddress',
                                                'PickupLocation',
                                              ], fallback: 'Pickup'),
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_off,
                                            color: _primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _orderText(order, [
                                                'DropoffAddress',
                                                'DeliveryLocation',
                                              ], fallback: 'Delivery'),
                                              style:
                                                  AppWidget.LightTextFieldStyle(
                                                    12.0,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _acceptOrder(orderId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primary,
                                          ),
                                          child: Text(
                                            'Accept Order',
                                            style: AppWidget.boldTextFieldStyle(
                                              12.0,
                                            ).copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
