import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/services/database.dart';

class AdminAssignmentsPage extends StatefulWidget {
  const AdminAssignmentsPage({super.key});

  @override
  State<AdminAssignmentsPage> createState() => _AdminAssignmentsPageState();
}

class _AdminAssignmentsPageState extends State<AdminAssignmentsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _assigningOrders = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chooseDriver({
    required String orderId,
    required Map<String, dynamic> order,
  }) async {
    final driver = await showModalBottomSheet<_DriverChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _DriverPicker(),
    );
    if (driver == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm assignment'),
        content: Text('Assign parcel #${_shortId(orderId)} to ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminStyle.primary,
            ),
            child: const Text('Assign driver'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _assigningOrders.add(orderId));
    try {
      await DatabaseMethods().assignOrderToDriver(orderId, driver.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AdminStyle.success,
          content: Text('${driver.name} assigned successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AdminStyle.danger,
          content: Text('Could not assign this parcel. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _assigningOrders.remove(orderId));
    }
  }

  String _shortId(String id) {
    return id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
  }

  String _text(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  String _price(Map<String, dynamic> data) {
    final raw = data['Price'] ?? data['DeliveryCharge'] ?? data['Amount'];
    if (raw == null || raw.toString().trim().isEmpty) return '';
    return 'BDT ${raw.toString().trim()}';
  }

  String _packageLabel(Map<String, dynamic> data) {
    return _text(
      data,
      ['PackageSize', 'PackageType', 'PackageDescription'],
      'Standard parcel',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyle.appBarColor,
      appBar: const AdminAppBar(
        title: 'Assign Delivery Man',
        subtitle: 'Match pending parcels with drivers',
        icon: Icons.assignment_ind_rounded,
      ),
      body: AdminBodySurface(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                const AdminSectionHeader(
                  title: 'Pending parcels',
                  subtitle: 'Select a parcel and assign the best driver',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _query = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search order, customer or location',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: DatabaseMethods().getPendingOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const AdminEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load parcels',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders =
                    snapshot.data!.docs.where((doc) {
                      if (_query.isEmpty) return true;
                      final data = doc.data();
                      final haystack = [
                        doc.id,
                        data['OrderId'],
                        data['SenderName'],
                        data['ReceiverName'],
                        data['PickupAddress'],
                        data['DropoffAddress'],
                      ].join(' ').toLowerCase();
                      return haystack.contains(_query);
                    }).toList()..sort((a, b) {
                      final aDate = (a.data()['CreatedAt'] ?? '').toString();
                      final bDate = (b.data()['CreatedAt'] ?? '').toString();
                      return bDate.compareTo(aDate);
                    });

                if (orders.isEmpty) {
                  return const AdminEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No pending parcels',
                    message: 'New unassigned parcels will appear here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data();
                    final orderId = (data['OrderId'] ?? doc.id).toString();
                    final assigning = _assigningOrders.contains(orderId);
                    final customerName = _text(
                      data,
                      ['SenderName', 'ReceiverName'],
                      'Parcel customer',
                    );
                    final price = _price(data);
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AdminStyle.cardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AdminStyle.primary,
                                      AdminStyle.accent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${_shortId(orderId)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AdminStyle.textPrimary(
                                              context,
                                            ),
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AdminStyle.textSecondary(
                                              context,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminStyle.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AdminStyle.warning.withOpacity(0.35),
                                  ),
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    color: AdminStyle.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminStyle.primary.withOpacity(
                                AdminStyle.isDark(context) ? 0.09 : 0.045,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AdminStyle.primary.withOpacity(0.28),
                              ),
                            ),
                            child: Column(
                              children: [
                                _RouteRow(
                                  color: AdminStyle.success,
                                  title: 'PICKUP',
                                  address: _text(
                                    data,
                                    ['PickupAddress', 'PickupLocation'],
                                    'Pickup address unavailable',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 2,
                                      height: 24,
                                      color: AdminStyle.primary.withOpacity(
                                        0.28,
                                      ),
                                    ),
                                  ),
                                ),
                                _RouteRow(
                                  color: AdminStyle.danger,
                                  title: 'DROPOFF',
                                  address: _text(
                                    data,
                                    ['DropoffAddress', 'DeliveryLocation'],
                                    'Delivery address unavailable',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _OrderMeta(
                                  icon: Icons.widgets_outlined,
                                  label: _packageLabel(data),
                                ),
                              ),
                              if (price.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                _OrderMeta(
                                  icon: Icons.payments_outlined,
                                  label: price,
                                  emphasized: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: assigning
                                  ? null
                                  : () => _chooseDriver(
                                      orderId: orderId,
                                      order: data,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminStyle.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              icon: assigning
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.assignment_ind_rounded),
                              label: Text(
                                assigning
                                    ? 'Assigning driver...'
                                    : 'Assign delivery man',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Color color;
  final String title;
  final String address;

  const _RouteRow({
    required this.color,
    required this.title,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminStyle.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _OrderMeta({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AdminStyle.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AdminStyle.primary.withOpacity(emphasized ? 0.5 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AdminStyle.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: emphasized
                    ? AdminStyle.primary
                    : AdminStyle.textSecondary(context),
                fontSize: 11,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverChoice {
  final String id;
  final String name;

  const _DriverChoice({required this.id, required this.name});
}

class _DriverPicker extends StatefulWidget {
  const _DriverPicker();

  @override
  State<_DriverPicker> createState() => _DriverPickerState();
}

class _DriverPickerState extends State<_DriverPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.74,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a driver',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Online and verified drivers are shown first.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) {
                      setState(() => _query = value.trim().toLowerCase());
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search driver',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: DatabaseMethods().getAllDriversStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final drivers =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        if (data['IsActive'] == false) return false;
                        if (_query.isEmpty) return true;
                        return [
                          doc.id,
                          data['Name'],
                          data['Email'],
                          data['Phone'],
                        ].join(' ').toLowerCase().contains(_query);
                      }).toList()..sort((a, b) {
                        final aOnline = a.data()['IsAvailable'] == true ? 1 : 0;
                        final bOnline = b.data()['IsAvailable'] == true ? 1 : 0;
                        if (aOnline != bOnline) return bOnline - aOnline;
                        final aVerified = a.data()['IsVerified'] == true
                            ? 1
                            : 0;
                        final bVerified = b.data()['IsVerified'] == true
                            ? 1
                            : 0;
                        return bVerified - aVerified;
                      });

                  if (drivers.isEmpty) {
                    return const AdminEmptyState(
                      icon: Icons.delivery_dining_outlined,
                      title: 'No drivers found',
                      message: 'Try another search or activate a driver first.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: drivers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = drivers[index];
                      final data = doc.data();
                      final name = (data['Name'] ?? 'Driver').toString();
                      final online = data['IsAvailable'] == true;
                      final verified = data['IsVerified'] == true;
                      return ListTile(
                        onTap: () => Navigator.pop(
                          context,
                          _DriverChoice(id: doc.id, name: name),
                        ),
                        tileColor: AdminStyle.surface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: AdminStyle.primary.withOpacity(0.4),
                            width: 1.2,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AdminStyle.primary.withOpacity(0.12),
                          foregroundColor: AdminStyle.primary,
                          child: Text(
                            name.isEmpty ? 'D' : name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AdminStyle.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (verified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: AdminStyle.primary,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${data['TotalDeliveries'] ?? 0} deliveries'
                          '  |  ${data['Rating'] ?? 5.0} rating',
                          style: TextStyle(
                            color: AdminStyle.textSecondary(context),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (online ? AdminStyle.success : Colors.blueGrey)
                                    .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            online ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: online
                                  ? AdminStyle.success
                                  : Colors.blueGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
