import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _primary = Color(0xFF0D7D8F);

  // user data
  String _userId = '';
  String _name = '';
  String _email = '';
  String _phone = '';
  String _nid = '';
  String _createdAt = '';
  String? _photoUrl;
  bool _loading = true;

  // controllers
  final _nameCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _savingInfo = false;
  bool _uploadingPhoto = false;
  bool _isEditing = false;
  String _originalName = '';
  String _originalNid = '';
  String _originalPhone = '';
  // notification prefs
  bool _notifOrders = true;
  bool _notifPromos = false;
  bool _notifReminders = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadNotifPrefs();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nidCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  //  data loading
  Future<void> _fetchUserData() async {
    try {
      final helper = SharedpreferenceHelper();
      String? uid = await helper.getUserId();
      if (uid == null || uid.isEmpty) {
        final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUid != null && firebaseUid.isNotEmpty) {
          final byUid = await DatabaseMethods().getUserByFirebaseUid(
            firebaseUid,
          );
          if (byUid.docs.isNotEmpty) {
            uid = byUid.docs.first.id;
            await helper.saveUserId(uid);
          }
        }
      }

      if (uid == null || uid.isEmpty) return;

      var doc = await DatabaseMethods().getUserDetail(uid);
      if (!doc.exists) {
        final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUid != null && firebaseUid.isNotEmpty) {
          final byUid = await DatabaseMethods().getUserByFirebaseUid(
            firebaseUid,
          );
          if (byUid.docs.isNotEmpty) {
            uid = byUid.docs.first.id;
            await helper.saveUserId(uid);
            doc = await DatabaseMethods().getUserDetail(uid);
          }
        }
      }

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final resolvedUid = uid;
        if (resolvedUid.isEmpty) return;

        final fetchedName = data['Name'] ?? '';
        final fetchedEmail = data['Email'] ?? '';
        final fetchedNid = data['NID'] ?? '';
        final fetchedPhone = data['Phone'] ?? '';

        // Cache in SharedPreferences for offline access
        await SharedpreferenceHelper().saveUserName(fetchedName);
        await SharedpreferenceHelper().saveUserEmail(fetchedEmail);
        await SharedpreferenceHelper().saveUserNid(fetchedNid);
        await SharedpreferenceHelper().saveUserPhone(fetchedPhone);

        if (mounted) {
          setState(() {
            _userId = resolvedUid;
            _name = fetchedName;
            _email = data['Email'] ?? '';
            _phone = fetchedPhone;
            _nid = fetchedNid;
            _createdAt = data['CreatedAt'] ?? '';
            _photoUrl = data['PhotoUrl'];
            _nameCtrl.text = _name;
            _nidCtrl.text = _nid;
            _phoneCtrl.text = _phone;
          });
        }
      }
    } catch (e) {
      _snack('Failed to load profile: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Email verification
  String? _validateProfileInputs({
    required String name,
    required String nid,
    required String phone,
  }) {
    final nidRegex = RegExp(r'^[0-9]{10,17}$');
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

    if (name.isEmpty) return 'Name cannot be empty';
    if (nid.isEmpty) return 'NID number cannot be empty';
    if (!nidRegex.hasMatch(nid)) {
      return 'Enter a valid NID number (10-17 digits)';
    }
    if (phone.isEmpty) return 'Phone number cannot be empty';
    if (!phoneRegex.hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  bool _isProfileVerified() {
    return _nid.isNotEmpty && _phone.isNotEmpty;
  }

  void _showVerificationRequirementsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Complete Verification',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To get verified, you need:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _verificationRequirement('NID Number', _nid.isNotEmpty),
            const SizedBox(height: 8),
            _verificationRequirement('Phone Number', _phone.isNotEmpty),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  Widget _verificationRequirement(String label, bool isComplete) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isComplete ? Colors.green : AppWidget.textPrimaryColor,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  //  photo picker & upload

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$_userId.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await DatabaseMethods().updateUserDetail(_userId, {'PhotoUrl': url});
      await SharedpreferenceHelper().saveUserProfileUrl(url);

      if (mounted) setState(() => _photoUrl = url);
      _snack('Profile photo updated!');
    } catch (e) {
      _snack('Failed to upload photo: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // save name & nid & phone

  Future<void> _saveInfo() async {
    final newName = _nameCtrl.text.trim();
    final newNid = _nidCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    final validationMessage = _validateProfileInputs(
      name: newName,
      nid: newNid,
      phone: newPhone,
    );
    if (validationMessage != null) {
      _snack(validationMessage, error: true);
      return;
    }

    setState(() => _savingInfo = true);
    try {
      await DatabaseMethods().updateUserDetail(_userId, {
        'Name': newName,
        'NID': newNid,
        'Phone': newPhone,
      });
      await SharedpreferenceHelper().saveUserName(newName);
      await SharedpreferenceHelper().saveUserNid(newNid);
      await SharedpreferenceHelper().saveUserPhone(newPhone);
      setState(() {
        _name = newName;
        _nid = newNid;
        _phone = newPhone;
      });
      _snack('Profile updated successfully!');
    } catch (e) {
      _snack('Failed to update: $e', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _savingInfo = false;
          _isEditing = false;
        });
      }
    }
  }

  void _startEdit() {
    _originalName = _nameCtrl.text;
    _originalNid = _nidCtrl.text;
    _originalPhone = _phoneCtrl.text;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    _nameCtrl.text = _originalName;
    _nidCtrl.text = _originalNid;
    _phoneCtrl.text = _originalPhone;
    setState(() => _isEditing = false);
  }

  //  change password
  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool saving = false;
    bool showOld = false, showNew = false, showConf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              decoration: BoxDecoration(
                color: AppWidget.surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppWidget.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline, color: _primary),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ProfilePageWidgets.pwField(
                    ctrl: oldCtrl,
                    label: 'Current Password',
                    show: showOld,
                    toggle: () => setLocal(() => showOld = !showOld),
                  ),
                  const SizedBox(height: 14),
                  ProfilePageWidgets.pwField(
                    ctrl: newCtrl,
                    label: 'New Password',
                    show: showNew,
                    toggle: () => setLocal(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 14),
                  ProfilePageWidgets.pwField(
                    ctrl: confCtrl,
                    label: 'Confirm New Password',
                    show: showConf,
                    toggle: () => setLocal(() => showConf = !showConf),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              if (newCtrl.text != confCtrl.text) {
                                _snack('Passwords do not match', error: true);
                                return;
                              }
                              if (newCtrl.text.length < 6) {
                                _snack(
                                  'Min 6 characters required',
                                  error: true,
                                );
                                return;
                              }
                              setLocal(() => saving = true);
                              try {
                                final user = FirebaseAuth.instance.currentUser!;
                                final cred = EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: oldCtrl.text,
                                );
                                await user.reauthenticateWithCredential(cred);
                                await user.updatePassword(newCtrl.text);
                                if (mounted) Navigator.pop(ctx);
                                _snack('Password updated!');
                              } on FirebaseAuthException catch (e) {
                                _snack(
                                  e.code == 'wrong-password'
                                      ? 'Current password is wrong'
                                      : e.message ?? 'Failed',
                                  error: true,
                                );
                              } finally {
                                setLocal(() => saving = false);
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
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
    );
  }

  // logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              await SharedpreferenceHelper().clearUserData();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  //  notifications
  Future<void> _loadNotifPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifOrders = p.getBool('notif_orders') ?? true;
        _notifPromos = p.getBool('notif_promos') ?? false;
        _notifReminders = p.getBool('notif_reminders') ?? true;
      });
    }
  }

  Future<void> _saveNotifPref(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          decoration: BoxDecoration(
            color: AppWidget.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppWidget.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFFE65100),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppWidget.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Choose what you want to be notified about',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppWidget.textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ProfilePageWidgets.notifTile(
                ctx: ctx,
                setLocal: setLocal,
                icon: Icons.local_shipping_outlined,
                iconColor: _primary,
                title: 'Order Updates',
                subtitle: 'Track your parcel in real-time',
                value: _notifOrders,
                onChanged: (v) {
                  setLocal(() => _notifOrders = v);
                  setState(() => _notifOrders = v);
                  _saveNotifPref('notif_orders', v);
                },
              ),
              const Divider(height: 1),
              ProfilePageWidgets.notifTile(
                ctx: ctx,
                setLocal: setLocal,
                icon: Icons.local_offer_outlined,
                iconColor: const Color(0xFFE65100),
                title: 'Promotions & Offers',
                subtitle: 'Deals and discount alerts',
                value: _notifPromos,
                onChanged: (v) {
                  setLocal(() => _notifPromos = v);
                  setState(() => _notifPromos = v);
                  _saveNotifPref('notif_promos', v);
                },
              ),
              const Divider(height: 1),
              ProfilePageWidgets.notifTile(
                ctx: ctx,
                setLocal: setLocal,
                icon: Icons.alarm_outlined,
                iconColor: const Color(0xFF1565C0),
                title: 'Delivery Reminders',
                subtitle: 'Upcoming delivery alerts',
                value: _notifReminders,
                onChanged: (v) {
                  setLocal(() => _notifReminders = v);
                  setState(() => _notifReminders = v);
                  _saveNotifPref('notif_reminders', v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  privacy policy

  void _showPrivacyPolicySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: AppWidget.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppWidget.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Color(0xFF1565C0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppWidget.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Last updated: Feb 2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppWidget.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    ProfilePageWidgets.privacySection(
                      'Information We Collect',
                      'We collect information you provide during registration, such as your name, email address, phone number, and profile photo. We also collect data about how you use our app, including delivery requests and tracking history.',
                    ),
                    ProfilePageWidgets.privacySection(
                      'How We Use Your Information',
                      'Your personal information is used to:\n• Process and track your parcel deliveries\n• Send real-time delivery notifications\n• Improve our services and user experience\n• Communicate important account updates',
                    ),
                    ProfilePageWidgets.privacySection(
                      'Data Storage & Security',
                      'Your data is securely stored using Firebase (Google Cloud). We use industry-standard encryption to protect your personal information. Profile photos are stored in Firebase Storage with access controls.',
                    ),
                    ProfilePageWidgets.privacySection(
                      'Third-Party Services',
                      'We use Google Maps for location services and Firebase for backend services. These services have their own privacy policies. We do not sell your personal data to third parties.',
                    ),
                    ProfilePageWidgets.privacySection(
                      'Your Rights',
                      'You have the right to:\n• Access your personal data at any time\n• Update or correct your information\n• Delete your account and associated data\n• Opt out of promotional communications',
                    ),
                    ProfilePageWidgets.privacySection(
                      'Contact Us',
                      'For any privacy-related concerns, please contact us at privacy@quickparcel.app or use the Help & Support section in your profile.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  help & support

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: AppWidget.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppWidget.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF6A1B9A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppWidget.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                      child: Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppWidget.textSecondaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ProfilePageWidgets.faqTile(
                      context,
                      question: 'How do I track my parcel?',
                      answer:
                          'Go to the Home screen and enter your tracking ID in the search bar. You will see real-time updates on your delivery status.',
                    ),
                    ProfilePageWidgets.faqTile(
                      context,
                      question: 'How do I cancel a delivery?',
                      answer:
                          'You can cancel a delivery from the My Orders section as long as it has not been picked up yet. Contact support if the parcel is already in transit.',
                    ),
                    ProfilePageWidgets.faqTile(
                      context,
                      question: 'How do I change my delivery address?',
                      answer:
                          'Address changes are only possible before the order is confirmed. Please contact our support team immediately if you need to update the address.',
                    ),
                    ProfilePageWidgets.faqTile(
                      context,
                      question: 'What payment methods are accepted?',
                      answer:
                          'We accept cash on delivery, mobile banking (bKash, Nagad, Rocket), and major debit/credit cards.',
                    ),
                    ProfilePageWidgets.faqTile(
                      context,
                      question: 'My parcel is delayed. What should I do?',
                      answer:
                          'Delays can occur due to weather or high demand. Use the tracking feature to check the latest status. If no update for 24h, please contact support.',
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                      child: Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppWidget.textSecondaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ProfilePageWidgets.contactTile(
                      icon: Icons.email_outlined,
                      iconColor: _primary,
                      label: 'Email Support',
                      value: 'support@quickparcel.app',
                    ),
                    const SizedBox(height: 8),
                    ProfilePageWidgets.contactTile(
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFF1565C0),
                      label: 'Call Us',
                      value: '+880 1800-PARCEL',
                    ),
                    const SizedBox(height: 8),
                    ProfilePageWidgets.contactTile(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFFE65100),
                      label: 'Support Hours',
                      value: 'Sat – Thu, 9 AM – 9 PM',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  date formatter

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
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  //  helpers

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  //  build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                //  Header Section
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button + title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'My Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Avatar section
                        Center(
                          child: GestureDetector(
                            onTap: _pickAndUploadPhoto,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.5),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _uploadingPhoto
                                        ? Container(
                                            color: Colors.white,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: _primary,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          )
                                        : (_photoUrl != null &&
                                                  _photoUrl!.isNotEmpty
                                              ? Image.network(
                                                  _photoUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      _defaultAvatar(),
                                                )
                                              : _defaultAvatar()),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: _primary,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // User name
                        Center(
                          child: Text(
                            _name.isNotEmpty ? _name : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // User email with verification badge
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _email,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Stats chips
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statChip(
                                icon: Icons.calendar_today_outlined,
                                label: _createdAt.isNotEmpty
                                    ? 'Since ${_formatDate(_createdAt)}'
                                    : 'Member',
                              ),
                              const SizedBox(width: 10),
                              if (_isProfileVerified())
                                _statChip(
                                  icon: Icons.verified_user_outlined,
                                  label: 'Verified Profile',
                                )
                              else
                                GestureDetector(
                                  onTap: () {
                                    _showVerificationRequirementsDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tap to Verify',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //  Bottom Sheet Content ─
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
                          //  Personal Info Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionTitle(
                                'Personal Information',
                                Icons.person_outline_rounded,
                              ),
                              if (!_isEditing)
                                GestureDetector(
                                  onTap: _startEdit,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _primary.withOpacity(0.25),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: _primary,
                                          size: 13,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            color: _primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _card(
                            child: Column(
                              children: [
                                // Full Name
                                _isEditing
                                    ? ProfilePageWidgets.editField(
                                        ctrl: _nameCtrl,
                                        label: 'Full Name',
                                        icon: Icons.person_outline_rounded,
                                      )
                                    : ProfilePageWidgets.infoDisplayTile(
                                        label: 'Full Name',
                                        value: _name.isNotEmpty ? _name : '—',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                const SizedBox(height: 12),
                                // NID Number
                                _isEditing
                                    ? ProfilePageWidgets.editField(
                                        ctrl: _nidCtrl,
                                        label: 'NID Number',
                                        icon: Icons.badge_outlined,
                                        keyboardType: TextInputType.number,
                                      )
                                    : ProfilePageWidgets.infoDisplayTile(
                                        label: 'NID Number',
                                        value: _nid.isNotEmpty ? _nid : '—',
                                        icon: Icons.badge_outlined,
                                      ),
                                const SizedBox(height: 12),
                                // Email
                                ProfilePageWidgets.readonlyField(
                                  value: _email,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 12),
                                // Phone
                                _isEditing
                                    ? ProfilePageWidgets.editField(
                                        ctrl: _phoneCtrl,
                                        label: 'Phone Number',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      )
                                    : ProfilePageWidgets.infoDisplayTile(
                                        label: 'Phone Number',
                                        value: _phone.isNotEmpty ? _phone : '—',
                                        icon: Icons.phone_outlined,
                                      ),

                                if (_isEditing) ...[
                                  const SizedBox(height: 20),
                                  _editActions(),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          //  Account Settings Section ─
                          _sectionTitle('Account Settings', Icons.tune_rounded),
                          const SizedBox(height: 18),
                          _card(
                            child: Column(
                              children: [
                                _settingsTile(
                                  icon: Icons.lock_outline_rounded,
                                  iconBg: _primary.withOpacity(0.14),
                                  iconColor: _primary,
                                  title: 'Change Password',
                                  subtitle: 'Update your login password',
                                  onTap: _showChangePasswordSheet,
                                ),
                                _divider(),
                                _settingsTile(
                                  icon: Icons.notifications_outlined,
                                  iconBg: const Color(
                                    0xFFE65100,
                                  ).withOpacity(0.14),
                                  iconColor: const Color(0xFFE65100),
                                  title: 'Notifications',
                                  subtitle: 'Manage your alert preferences',
                                  onTap: _showNotificationsSheet,
                                ),
                                _divider(),
                                _settingsTile(
                                  icon: Icons.privacy_tip_outlined,
                                  iconBg: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.14),
                                  iconColor: const Color(0xFF1565C0),
                                  title: 'Privacy Policy',
                                  subtitle: 'Read our privacy policy',
                                  onTap: _showPrivacyPolicySheet,
                                ),
                                _divider(),
                                _settingsTile(
                                  icon: Icons.help_outline_rounded,
                                  iconBg: const Color(
                                    0xFF9C27B0,
                                  ).withOpacity(0.14),
                                  iconColor: const Color(0xFF6A1B9A),
                                  title: 'Help & Support',
                                  subtitle: 'Get help or report an issue',
                                  onTap: _showHelpSupportSheet,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          //  Logout Button
                          GestureDetector(
                            onTap: _confirmLogout,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFC62828),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Color(0xFFC62828),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  //  small widget builders ─

  Widget _defaultAvatar() => ProfilePageWidgets.defaultAvatar();

  Widget _statChip({required IconData icon, required String label}) =>
      ProfilePageWidgets.statChip(icon: icon, label: label);

  Widget _sectionTitle(String title, IconData icon) =>
      ProfilePageWidgets.sectionTitle(title, icon);

  Widget _card({required Widget child}) =>
      ProfilePageWidgets.card(child: child);

  Widget _editActions() => Row(
    children: [
      // Cancel button
      Expanded(
        child: GestureDetector(
          onTap: _savingInfo ? null : _cancelEdit,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppWidget.surfaceAltColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppWidget.borderColor),
            ),
            child: Center(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppWidget.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Save button
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: _savingInfo ? null : _saveInfo,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              gradient: _savingInfo
                  ? null
                  : const LinearGradient(
                      colors: [_primary, Color(0xFF0A9BAF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: _savingInfo ? AppWidget.borderColor : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _savingInfo
                  ? []
                  : [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _savingInfo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                const SizedBox(width: 8),
                Text(
                  _savingInfo ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _settingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ProfilePageWidgets.settingsTile(
    icon: icon,
    iconBg: iconBg,
    iconColor: iconColor,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
  );

  Widget _divider() => ProfilePageWidgets.divider();
}
