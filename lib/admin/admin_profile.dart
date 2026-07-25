import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/admin/admin_login.dart';
import 'package:quick_parcel/admin/admin_style.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String _name = 'Administrator';
  String _email = '';
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final helper = SharedpreferenceHelper();
    final name = await helper.getUserName();
    final email = await helper.getUserEmail();
    if (!mounted) return;
    setState(() {
      _name = name?.trim().isNotEmpty == true ? name!.trim() : 'Administrator';
      _email = email ?? '';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access the admin dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminStyle.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      await SharedpreferenceHelper().clearUserData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyle.appBarColor,
      appBar: const AdminAppBar(
        title: 'Admin Account',
        subtitle: 'Profile, security and session controls',
        icon: Icons.admin_panel_settings_rounded,
      ),
      body: AdminBodySurface(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AdminStyle.headerGradient(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.78)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'QUICK PARCEL ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: AdminStyle.cardDecoration(context),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.shield_outlined,
                    color: AdminStyle.primary,
                  ),
                  title: Text('Access level'),
                  subtitle: Text('Administrator'),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const ListTile(
                  leading: Icon(
                    Icons.security_rounded,
                    color: AdminStyle.primary,
                  ),
                  title: Text('Security'),
                  subtitle: Text('Firebase authenticated admin session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _loggingOut ? null : _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminStyle.danger,
                side: const BorderSide(color: AdminStyle.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _loggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(_loggingOut ? 'Logging out...' : 'Log out'),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
