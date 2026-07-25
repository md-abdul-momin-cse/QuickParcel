import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/shared/order_chat_page.dart';

class DriverAllOrdersPage extends StatefulWidget {
  const DriverAllOrdersPage({super.key});

  @override
  State<DriverAllOrdersPage> createState() => _DriverAllOrdersPageState();
}

class _DriverAllOrdersPageState extends State<DriverAllOrdersPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFFF57C00);
  static const Color _success = Color(0xFF22C55E);

  final Set<String> _updatingOrderIds = {};
  late final TabController _tabController;
  String? _driverId;
  bool _loadingDriver = true;

  final List<String> _tabs = ['All', 'In Transit', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadDriver();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDriver() async {
    final id = await SharedpreferenceHelper().getUserId();
    if (!mounted) return;
    setState(() {
      _driverId = id;
      _loadingDriver = false;
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int tabIndex,
  ) {
    final activeDocs = docs.where((doc) {
      return _isDriverOrderStatus(doc.data()['Status']);
    }).toList()..sort(_compareDocsByCreatedAtDesc);

    final filter = _tabs[tabIndex].toLowerCase();
    if (filter == 'all') {
      return activeDocs.where((doc) {
        final status = (doc.data()['Status'] ?? '').toString().toLowerCase();
        return status != 'delivered';
      }).toList();
    }

    return activeDocs.where((doc) {
      final status = (doc.data()['Status'] ?? '').toString().toLowerCase();
      if (filter == 'in transit') {
        return status == 'received' || status == 'in transit';
      }
      return status == filter;
    }).toList();
  }

  bool _isDriverOrderStatus(dynamic status) {
    switch ((status ?? '').toString().toLowerCase()) {
      case 'accepted':
      case 'confirmed':
      case 'received':
      case 'in transit':
      case 'delivered':
        return true;
      default:
        return false;
    }
  }

  IconData _tabIcon(String tab) {
    switch (tab.toLowerCase()) {
      case 'in transit':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _orderTabs() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final selectedColor = isDark
            ? Color.lerp(theme.colorScheme.surface, _primary, 0.18)!
            : Colors.white;
        final selectedTextColor = isDark
            ? theme.colorScheme.onSurface
            : _primary;
        final selectedIconColor = isDark ? const Color(0xFFFFB15D) : _primary;
        final unselectedColor = isDark
            ? theme.colorScheme.onSurface.withOpacity(0.66)
            : Colors.white70;

        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.14)
                : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.16)
                  : Colors.white.withOpacity(0.22),
            ),
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final selected = _tabController.index == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.18 : 0.10,
                                ),
                                blurRadius: isDark ? 8 : 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabIcon(tab),
                          size: 17,
                          color: selected ? selectedIconColor : unselectedColor,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            tab,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? selectedTextColor
                                  : unselectedColor,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  int _compareDocsByCreatedAtDesc(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aCreated = (a.data()['CreatedAt'] ?? '').toString();
    final bCreated = (b.data()['CreatedAt'] ?? '').toString();
    return bCreated.compareTo(aCreated);
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

  String _shortOrderId(String orderId) {
    if (orderId.isEmpty) return 'N/A';
    return orderId.length > 10 ? orderId.substring(0, 10) : orderId;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
      case 'accepted':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'received':
        return const Color(0xFF0D9488);
      case 'in transit':
        return _primary;
      case 'delivered':
        return _success;
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  bool _canMarkReceived(String status) {
    final value = status.toLowerCase();
    return value == 'accepted' || value == 'confirmed' || value == 'received';
  }

  bool _canMarkDelivered(String status) {
    return status.toLowerCase() == 'in transit';
  }

  Future<void> _acceptOrder(String orderId) async {
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty || orderId.isEmpty) return;

    setState(() => _updatingOrderIds.add(orderId));
    try {
      await DatabaseMethods().acceptOrder(orderId, driverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final driverId = _driverId;
    if (driverId == null || driverId.isEmpty || orderId.isEmpty) return;

    setState(() => _updatingOrderIds.add(orderId));
    try {
      await DatabaseMethods().updateDeliveryStatus(
        orderId: orderId,
        driverId: driverId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked $status'),
          backgroundColor: status == 'Delivered' ? _success : _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _openOrderChat(Map<String, dynamic> order) async {
    final orderId = (order['OrderId'] ?? '').toString();
    final driverId =
        _driverId ?? await SharedpreferenceHelper().getUserId() ?? '';
    final customerId = (order['UserId'] ?? order['CustomerId'] ?? '')
        .toString();

    if (orderId.isEmpty || driverId.isEmpty || customerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer chat is not available yet')),
      );
      return;
    }

    final helper = SharedpreferenceHelper();
    final savedName = await helper.getUserName();
    final driverName = (savedName ?? order['DriverName'] ?? 'Driver')
        .toString();
    final customerName = _orderText(order, [
      'SenderName',
      'CustomerName',
    ], fallback: 'Customer');

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
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : (_driverId == null || _driverId!.isEmpty)
                ? _emptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Driver profile not found',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: DatabaseMethods().getDriverActiveOrdersStream(
                      _driverId!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _primary),
                        );
                      }
                      if (snapshot.hasError) {
                        return _emptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'Failed to load orders',
                        );
                      }

                      final docs =
                          snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      return TabBarView(
                        controller: _tabController,
                        children: List.generate(_tabs.length, (index) {
                          final orders = _filteredOrders(docs, index);
                          if (orders.isEmpty) {
                            return _emptyState(
                              icon: Icons.assignment_outlined,
                              message: index == 0
                                  ? 'No received orders yet'
                                  : 'No ${_tabs[index].toLowerCase()} orders',
                            );
                          }
                          return RefreshIndicator(
                            color: _primary,
                            onRefresh: () async => setState(() {}),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                              itemCount: orders.length,
                              itemBuilder: (context, orderIndex) {
                                final doc = orders[orderIndex];
                                final data = {...doc.data(), 'OrderId': doc.id};
                                return _orderCard(data);
                              },
                            ),
                          );
                        }),
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'All Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _orderTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final orderId = (order['OrderId'] ?? '').toString();
    final status = _orderText(order, ['Status'], fallback: 'Received');
    final pickup = _orderText(order, ['PickupAddress', 'PickupLocation']);
    final dropoff = _orderText(order, ['DropoffAddress', 'DeliveryLocation']);
    final customer = _orderText(order, ['SenderName'], fallback: 'Customer');
    final receiver = _orderText(order, ['ReceiverName'], fallback: 'Receiver');
    final packageSize = _orderText(order, ['PackageSize'], fallback: 'Package');
    final price = _orderText(order, ['Price'], fallback: '0');
    final updating = _updatingOrderIds.contains(orderId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppWidget.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppWidget.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${_shortOrderId(orderId)}',
                  style: TextStyle(
                    color: AppWidget.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _routeLine(
            icon: Icons.my_location_rounded,
            label: 'Pickup',
            value: pickup,
            color: _primary,
          ),
          const SizedBox(height: 8),
          _routeLine(
            icon: Icons.location_on_rounded,
            label: 'Dropoff',
            value: dropoff,
            color: _success,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoChip(Icons.person_outline, customer)),
              const SizedBox(width: 8),
              Expanded(child: _infoChip(Icons.person_pin_outlined, receiver)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoChip(Icons.inventory_2_outlined, packageSize),
              ),
              const SizedBox(width: 8),
              Expanded(child: _infoChip(Icons.payments_outlined, 'Tk $price')),
            ],
          ),
          const SizedBox(height: 14),
          if (status.toLowerCase() == 'assigned') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: updating ? null : () => _acceptOrder(orderId),
                icon: updating
                    ? _smallLoader(color: _primary)
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Accept Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: BorderSide(color: _primary.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statusActionButton(
                    width: constraints.maxWidth,
                    updating: updating,
                    enabled: _canMarkReceived(status),
                    label: 'Received',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0D9488),
                    outlined: true,
                    onPressed: () => _updateStatus(orderId, 'In Transit'),
                  ),
                  _statusActionButton(
                    width: constraints.maxWidth,
                    updating: updating,
                    enabled: _canMarkDelivered(status),
                    label: 'Delivered',
                    icon: Icons.done_all_rounded,
                    color: _success,
                    outlined: false,
                    onPressed: () => _updateStatus(orderId, 'Delivered'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusActionButton({
    required double width,
    required bool updating,
    required bool enabled,
    required String label,
    required IconData icon,
    required Color color,
    required bool outlined,
    required VoidCallback onPressed,
  }) {
    final loader = _smallLoader(color: outlined ? color : Colors.white);
    if (outlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: updating || !enabled ? null : onPressed,
          icon: updating ? loader : Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.7)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: updating || !enabled ? null : onPressed,
        icon: updating ? loader : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _routeLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppWidget.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppWidget.surfaceAltColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppWidget.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppWidget.textSecondaryColor),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label.isEmpty ? 'N/A' : label,
              style: TextStyle(
                color: AppWidget.textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _smallLoader({required Color color}) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppWidget.textSecondaryColor, size: 54),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppWidget.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
