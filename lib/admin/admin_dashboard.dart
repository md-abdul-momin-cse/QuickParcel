import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class AdminDashboard extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const AdminDashboard({super.key, required this.onNavigate});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _adminName = 'Administrator';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final name = await SharedpreferenceHelper().getUserName();
    if (mounted && name != null && name.trim().isNotEmpty) {
      setState(() => _adminName = name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = DatabaseMethods();
    return Scaffold(
      backgroundColor: AdminStyle.appBarColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: AdminBodySurface(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  children: [
                const AdminSectionHeader(
                  title: 'Operations overview',
                  subtitle: 'Live activity across Quick Parcel',
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: database.getAllOrdersStream(),
                  builder: (context, orderSnapshot) {
                    final orders = orderSnapshot.data?.docs ?? [];
                    final pending = orders.where((doc) {
                      final status = (doc.data()['Status'] ?? '')
                          .toString()
                          .toLowerCase();
                      return status == 'pending';
                    }).length;
                    final active = orders.where((doc) {
                      final status = (doc.data()['Status'] ?? '')
                          .toString()
                          .toLowerCase();
                      return const {
                        'assigned',
                        'confirmed',
                        'received',
                        'in transit',
                      }.contains(status);
                    }).length;
                    final delivered = orders.where((doc) {
                      return (doc.data()['Status'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'delivered';
                    }).length;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Pending',
                                value: pending.toString(),
                                icon: Icons.pending_actions_rounded,
                                color: AdminStyle.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Active',
                                value: active.toString(),
                                icon: Icons.local_shipping_rounded,
                                color: AdminStyle.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Delivered',
                                value: delivered.toString(),
                                icon: Icons.task_alt_rounded,
                                color: AdminStyle.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Total parcels',
                                value: orders.length.toString(),
                                icon: Icons.inventory_2_rounded,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                AdminSectionHeader(
                  title: 'Quick actions',
                  subtitle: 'Keep daily operations moving',
                  trailing: Icon(Icons.bolt_rounded, color: AdminStyle.warning),
                ),
                const SizedBox(height: 14),
                _ActionCard(
                  icon: Icons.assignment_ind_rounded,
                  title: 'Assign delivery man',
                  subtitle: 'Match pending parcels with available drivers',
                  color: AdminStyle.primary,
                  onTap: () => widget.onNavigate(1),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Manage users',
                  subtitle: 'Review customers, drivers and account status',
                  color: const Color(0xFF7C3AED),
                  onTap: () => widget.onNavigate(2),
                ),
                const SizedBox(height: 26),
                const AdminSectionHeader(
                  title: 'Network',
                  subtitle: 'Current customer and driver totals',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CollectionCountCard(
                        stream: database.getAllUsersStream(),
                        icon: Icons.people_alt_rounded,
                        label: 'Customers',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CollectionCountCard(
                        stream: database.getAllDriversStream(),
                        icon: Icons.delivery_dining_rounded,
                        label: 'Drivers',
                      ),
                    ),
                  ],
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

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 50, 22, 28),
      decoration: BoxDecoration(
        color: AdminStyle.appBarColor,
        boxShadow: [
          BoxShadow(
            color: AdminStyle.primary.withOpacity(0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.26)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMIN CONSOLE  |  $greeting',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.55,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _adminName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Admin account',
              onPressed: () => widget.onNavigate(3),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.14),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AdminStyle.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: AdminStyle.cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionCountCard extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final IconData icon;
  final String label;

  const _CollectionCountCard({
    required this.stream,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AdminStyle.cardDecoration(context),
          child: Row(
            children: [
              Icon(icon, color: AdminStyle.primary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (snapshot.data?.docs.length ?? 0).toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
