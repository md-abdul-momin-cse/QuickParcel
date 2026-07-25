import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_parcel/driver/driver_login.dart';
import 'package:quick_parcel/driver/driver_verified_badge.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  static const Color _primary = Color(0xFFF57C00);

  // User data
  String _driverId = '';
  String _name = '';
  String _email = '';
  String _phone = '';
  String _licenseNumber = '';
  String _vehicleNumber = '';

  double _rating = 5.0;
  int _totalDeliveries = 0;
  String? _photoUrl;
  bool _loading = true;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  bool _savingInfo = false;
  bool _uploadingPhoto = false;
  bool _isEditing = false;
  String _originalName = '';
  String _originalPhone = '';
  String _originalLicense = '';
  String _originalVehicle = '';

  // Notification prefs
  bool _notifOrders = true;
  bool _notifPromos = false;
  bool _notifReminders = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
    _loadNotifPrefs();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDriverData() async {
    try {
      final helper = SharedpreferenceHelper();
      String? uid = await helper.getUserId();

      if (uid == null || uid.isEmpty) {
        final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUid != null && firebaseUid.isNotEmpty) {
          final byUid = await DatabaseMethods().getDriverByFirebaseUid(
            firebaseUid,
          );
          if (byUid.docs.isNotEmpty) {
            uid = byUid.docs.first.id;
            await helper.saveUserId(uid);
          }
        }
      }

      if (uid == null || uid.isEmpty) return;

      final doc = await DatabaseMethods().getDriverDetail(uid);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _driverId = uid ?? '';
          _name = data['Name'] ?? '';
          _email = data['Email'] ?? '';
          _phone = data['Phone'] ?? '';
          _licenseNumber = data['LicenseNumber'] ?? '';
          _vehicleNumber = data['VehicleNumber'] ?? '';
          _rating = (data['Rating'] ?? 5.0).toDouble();
          _totalDeliveries = data['TotalDeliveries'] ?? 0;
          _photoUrl = data['PhotoUrl'];

          _nameCtrl.text = _name;
          _phoneCtrl.text = _phone;
          _licenseCtrl.text = _licenseNumber;
          _vehicleCtrl.text = _vehicleNumber;

          _originalName = _name;
          _originalPhone = _phone;
          _originalLicense = _licenseNumber;
          _originalVehicle = _vehicleNumber;

          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadNotifPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notifOrders = prefs.getBool('notif_orders') ?? true;
        _notifPromos = prefs.getBool('notif_promos') ?? false;
        _notifReminders = prefs.getBool('notif_reminders') ?? true;
      });
    } catch (e) {
      debugPrint('Error loading notification prefs: $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      setState(() => _uploadingPhoto = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      final file = File(image.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('driver_photos')
          .child('$_driverId.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await DatabaseMethods().updateDriverPhoto(_driverId, downloadUrl);

      if (mounted) {
        setState(() => _photoUrl = downloadUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF57C00),
          content: Text('Photo updated successfully'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error uploading photo: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _savingInfo = true);

      final updateData = {
        'Name': _nameCtrl.text.trim(),
        'Phone': _phoneCtrl.text.trim(),
        'LicenseNumber': _licenseCtrl.text.trim(),
        'VehicleNumber': _vehicleCtrl.text.trim(),
      };

      await DatabaseMethods().updateDriverInfo(_driverId, updateData);

      if (mounted) {
        setState(() {
          _name = _nameCtrl.text.trim();
          _phone = _phoneCtrl.text.trim();
          _licenseNumber = _licenseCtrl.text.trim();
          _vehicleNumber = _vehicleCtrl.text.trim();
          _isEditing = false;

          _originalName = _name;
          _originalPhone = _phone;
          _originalLicense = _licenseNumber;
          _originalVehicle = _vehicleNumber;
        });

        await SharedpreferenceHelper().saveUserName(_nameCtrl.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFF57C00),
            content: Text('Profile updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error saving changes: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingInfo = false);
      }
    }
  }

  Future<void> _saveNotifPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_orders', _notifOrders);
      await prefs.setBool('notif_promos', _notifPromos);
      await prefs.setBool('notif_reminders', _notifReminders);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF57C00),
          content: Text('Notification settings updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error logging out: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: _loading
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
                              'Driver Profile',
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
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
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
                                                      Container(
                                                        color: Colors.white,
                                                        child: const Icon(
                                                          Icons.person,
                                                          color: _primary,
                                                          size: 40,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color: Colors.white,
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: _primary,
                                                    size: 40,
                                                  ),
                                                )),
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
                        // Driver name
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(
                                _name.isNotEmpty ? _name : 'Driver',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              DriverVerifiedBadge(driverId: _driverId),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Driver email
                        Center(
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
                        const SizedBox(height: 14),
                        // Stats chips
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
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
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.yellow,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_rating.toStringAsFixed(1)} Rating',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
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
                                child: Text(
                                  '$_totalDeliveries Deliveries',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
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

                // Bottom content area
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
                          // Personal Info Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppWidget.textPrimaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => _isEditing = !_isEditing);
                                  if (!_isEditing) {
                                    _nameCtrl.text = _originalName;
                                    _phoneCtrl.text = _originalPhone;
                                    _licenseCtrl.text = _originalLicense;
                                    _vehicleCtrl.text = _originalVehicle;
                                  }
                                },
                                child: Text(
                                  _isEditing ? 'Cancel' : 'Edit',
                                  style: TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name Field
                          _buildField(
                            label: 'Full Name',
                            controller: _nameCtrl,
                            icon: Icons.person,
                            hint: 'Enter your name',
                          ),
                          const SizedBox(height: 16),

                          // Email (Read-only)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppWidget.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppWidget.borderColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      color: _primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _email,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppWidget.textPrimaryColor,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          _buildField(
                            label: 'Phone Number',
                            controller: _phoneCtrl,
                            icon: Icons.phone,
                            hint: 'Enter your phone',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // License Number Field
                          _buildField(
                            label: 'License Number',
                            controller: _licenseCtrl,
                            icon: Icons.card_travel,
                            hint: 'Enter license number',
                          ),
                          const SizedBox(height: 16),

                          // Vehicle Number Field
                          _buildField(
                            label: 'Vehicle Number',
                            controller: _vehicleCtrl,
                            icon: Icons.directions_car,
                            hint: 'Enter vehicle number',
                          ),
                          const SizedBox(height: 24),

                          // Save/Logout Buttons
                          if (_isEditing)
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
                                onPressed: _savingInfo ? null : _saveChanges,
                                child: _savingInfo
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Logout',
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
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppWidget.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: _primary, size: 18),
            filled: true,
            fillColor: AppWidget.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppWidget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppWidget.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppWidget.borderColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintStyle: TextStyle(
              color: AppWidget.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
