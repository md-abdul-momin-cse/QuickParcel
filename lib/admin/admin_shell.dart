import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_assignments.dart';
import 'package:quick_parcel/admin/admin_dashboard.dart';
import 'package:quick_parcel/admin/admin_profile.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/admin/admin_users.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    AdminDashboard(onNavigate: _selectPage),
    const AdminAssignmentsPage(),
    const AdminUsersPage(),
    const AdminProfilePage(),
  ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdminStyle.isDark(context);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdminStyle.surface(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
            backgroundColor: AdminStyle.surface(context),
            indicatorColor: AdminStyle.primary.withOpacity(0.14),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_ind_outlined),
                selectedIcon: Icon(Icons.assignment_ind_rounded),
                label: 'Assign',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group_rounded),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
