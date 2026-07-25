import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/services/database.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleAccount({
    required String collection,
    required String id,
    required bool isActive,
  }) async {
    setState(() => _updating.add('$collection/$id'));
    try {
      await DatabaseMethods().updateAccountStatus(
        collection: collection,
        id: id,
        isActive: !isActive,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AdminStyle.danger,
            content: Text('Could not update this account.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove('$collection/$id'));
    }
  }

  Future<void> _toggleVerification({
    required String id,
    required bool verified,
  }) async {
    setState(() => _updating.add('verify/$id'));
    try {
      await DatabaseMethods().updateDriverVerification(id, !verified);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AdminStyle.danger,
            content: Text('Could not update driver verification.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove('verify/$id'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyle.appBarColor,
      appBar: AdminAppBar(
        title: 'Manage Users',
        subtitle: 'Customers, drivers and account access',
        icon: Icons.manage_accounts_rounded,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            height: 42,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: AdminStyle.primaryDark,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              tabs: const [
                Tab(text: 'Customers'),
                Tab(text: 'Drivers'),
              ],
            ),
          ),
        ),
      ),
      body: AdminBodySurface(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _query = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search name, email or phone',
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
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(
                  stream: DatabaseMethods().getAllUsersStream(),
                  collection: 'users',
                  isDriver: false,
                ),
                _buildUserList(
                  stream: DatabaseMethods().getAllDriversStream(),
                  collection: 'drivers',
                  isDriver: true,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required String collection,
    required bool isDriver,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AdminEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load accounts',
            message: 'Check your connection and try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users =
            snapshot.data!.docs.where((doc) {
              if (_query.isEmpty) return true;
              final data = doc.data();
              return [
                doc.id,
                data['Name'],
                data['Email'],
                data['Phone'],
              ].join(' ').toLowerCase().contains(_query);
            }).toList()..sort((a, b) {
              final aName = (a.data()['Name'] ?? '').toString().toLowerCase();
              final bName = (b.data()['Name'] ?? '').toString().toLowerCase();
              return aName.compareTo(bName);
            });

        if (users.isEmpty) {
          return AdminEmptyState(
            icon: isDriver
                ? Icons.delivery_dining_outlined
                : Icons.people_outline_rounded,
            title: isDriver ? 'No drivers found' : 'No customers found',
            message: 'Accounts matching your search will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data();
            final name = (data['Name'] ?? (isDriver ? 'Driver' : 'Customer'))
                .toString();
            final email = (data['Email'] ?? 'No email').toString();
            final isActive = data['IsActive'] != false;
            final verified = data['IsVerified'] == true;
            final accountUpdating = _updating.contains('$collection/${doc.id}');
            final verificationUpdating = _updating.contains('verify/${doc.id}');

            return Container(
              padding: const EdgeInsets.all(15),
              decoration: AdminStyle.cardDecoration(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        (isActive ? AdminStyle.primary : Colors.blueGrey)
                            .withOpacity(0.12),
                    foregroundColor: isActive
                        ? AdminStyle.primary
                        : Colors.blueGrey,
                    backgroundImage:
                        (data['PhotoUrl'] ?? '').toString().isNotEmpty
                        ? NetworkImage(data['PhotoUrl'].toString())
                        : null,
                    child: (data['PhotoUrl'] ?? '').toString().isEmpty
                        ? Text(
                            name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AdminStyle.textPrimary(context),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            if (isDriver && verified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: AdminStyle.primary,
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminStyle.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              label: isActive ? 'Active' : 'Suspended',
                              color: isActive
                                  ? AdminStyle.success
                                  : AdminStyle.danger,
                            ),
                            if (isDriver)
                              _StatusChip(
                                label: verified ? 'Verified' : 'Unverified',
                                color: verified
                                    ? AdminStyle.primary
                                    : AdminStyle.warning,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !accountUpdating && !verificationUpdating,
                    onSelected: (value) {
                      if (value == 'status') {
                        _toggleAccount(
                          collection: collection,
                          id: doc.id,
                          isActive: isActive,
                        );
                      } else if (value == 'verify') {
                        _toggleVerification(id: doc.id, verified: verified);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.block_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: isActive
                                  ? AdminStyle.danger
                                  : AdminStyle.success,
                            ),
                            const SizedBox(width: 10),
                            Text(isActive ? 'Suspend account' : 'Activate'),
                          ],
                        ),
                      ),
                      if (isDriver)
                        PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: AdminStyle.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(verified ? 'Remove verification' : 'Verify'),
                            ],
                          ),
                        ),
                    ],
                    icon: accountUpdating || verificationUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.more_vert_rounded,
                            color: AdminStyle.textSecondary(context),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
