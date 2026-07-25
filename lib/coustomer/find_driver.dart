import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/coustomer/billing_page.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:url_launcher/url_launcher.dart';

class FindDriverScreen extends StatefulWidget {
  final String orderId;
  final String pickupLat;
  final String pickupLng;
  final String dropoffLat;
  final String dropoffLng;
  final String pickupAddress;
  final String dropoffAddress;

  const FindDriverScreen({
    super.key,
    required this.orderId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  State<FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<FindDriverScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropoffMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;
  Brightness? _markerIconBrightness;
  bool _loadingMarkerIcons = false;
  bool _mapReady = false;
  bool _driverSheetOpen = false;
  bool _isAssigning = false;
  Map<String, dynamic>? _selectedDriver;

  static const Color _teal = Color(0xFF0D7D8F);
  static const Color _accentGreen = Color(0xFF2E7D32);
  static const Color _primary = Color(0xFF0D7D8F);
  static const Color _secondary = Color(0xFF00BCD4);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c2f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c2f"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

  @override
  void initState() {
    super.initState();
  }

  LatLng get _pickupLatLng => LatLng(
    double.tryParse(widget.pickupLat) ?? 0.0,
    double.tryParse(widget.pickupLng) ?? 0.0,
  );

  LatLng get _dropoffLatLng => LatLng(
    double.tryParse(widget.dropoffLat) ?? 0.0,
    double.tryParse(widget.dropoffLng) ?? 0.0,
  );

  void _ensureMarkerIcons(Brightness brightness) {
    if (_markerIconBrightness == brightness &&
        _pickupMarkerIcon != null &&
        _dropoffMarkerIcon != null &&
        _driverMarkerIcon != null) {
      return;
    }
    if (_loadingMarkerIcons) return;

    _loadingMarkerIcons = true;
    final isDark = brightness == Brightness.dark;

    Future.wait([
      _createLabeledMarker(
        label: 'Pickup',
        color: const Color(0xFF23C55E),
        icon: Icons.my_location_rounded,
        isDark: isDark,
      ),
      _createLabeledMarker(
        label: 'Dropoff',
        color: const Color(0xFFEF4444),
        icon: Icons.flag_rounded,
        isDark: isDark,
      ),
      _createLabeledMarker(
        label: 'Driver',
        color: const Color(0xFF22C7D8),
        icon: Icons.delivery_dining_rounded,
        isDark: isDark,
      ),
    ]).then((icons) {
      if (!mounted) return;
      setState(() {
        _pickupMarkerIcon = icons[0];
        _dropoffMarkerIcon = icons[1];
        _driverMarkerIcon = icons[2];
        _markerIconBrightness = brightness;
        _loadingMarkerIcons = false;
      });
    });
  }

  Future<BitmapDescriptor> _createLabeledMarker({
    required String label,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) async {
    const double width = 220;
    const double height = 122;
    const double centerX = width / 2;
    const double labelHeight = 42;
    const double labelTop = 6;
    const double pinRadius = 18;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.40 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final labelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(38, labelTop, width - 76, labelHeight),
      const Radius.circular(18),
    );
    canvas.drawRRect(labelRect.shift(const Offset(0, 3)), shadowPaint);

    final labelPaint = Paint()
      ..color = isDark ? const Color(0xFF162326) : Colors.white;
    canvas.drawRRect(labelRect, labelPaint);
    canvas.drawRRect(
      labelRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withOpacity(isDark ? 0.55 : 0.28),
    );

    final pointerPath = Path()
      ..moveTo(centerX - 9, labelTop + labelHeight - 1)
      ..lineTo(centerX + 9, labelTop + labelHeight - 1)
      ..lineTo(centerX, labelTop + labelHeight + 13)
      ..close();
    canvas.drawPath(pointerPath, labelPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF132D34),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 92);
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, labelTop + 11),
    );

    final pinCenter = Offset(centerX, 86);
    canvas.drawCircle(pinCenter.translate(0, 3), pinRadius + 4, shadowPaint);
    canvas.drawCircle(pinCenter, pinRadius + 5, Paint()..color = Colors.white);
    canvas.drawCircle(pinCenter, pinRadius, Paint()..color = color);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        pinCenter.dx - iconPainter.width / 2,
        pinCenter.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Set<Marker> _buildDriverMarkers(List<Map<String, dynamic>> drivers) {
    Set<Marker> markers = {};

    // Add pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon:
            _pickupMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.88),
        zIndex: 3,
      ),
    );

    // Add dropoff marker
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLatLng,
        infoWindow: const InfoWindow(title: 'Dropoff'),
        icon:
            _dropoffMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.88),
        zIndex: 3,
      ),
    );

    // Add driver markers - only if they have valid location
    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      final lat = (driver['CurrentLat'] as num?)?.toDouble() ?? 0.0;
      final lng = (driver['CurrentLng'] as num?)?.toDouble() ?? 0.0;

      // Only add marker if driver has valid location (not 0,0)
      if (lat != 0.0 && lng != 0.0) {
        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver['Id']}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'Driver',
              snippet: driver['Name'] ?? 'Driver',
            ),
            icon:
                _driverMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
            anchor: const Offset(0.5, 0.88),
            zIndex: 4,
            onTap: () => _selectDriver(driver),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildRoutePolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('pickup_dropoff_route'),
        points: [_pickupLatLng, _dropoffLatLng],
        color: const Color(0xFF2F80ED),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        geodesic: true,
      ),
    };
  }

  void _selectDriver(Map<String, dynamic> driver) {
    setState(() => _selectedDriver = driver);
    _showDriverDetailsBottomSheet(driver);
  }

  bool _isDriverOnline(Map<String, dynamic> driver) {
    final lastUpdate = _parseDriverDate(driver['LastLocationUpdate']);
    if (lastUpdate == null) return false;

    return driver['IsAvailable'] == true &&
        DateTime.now().difference(lastUpdate).inSeconds <= 45;
  }

  DateTime? _parseDriverDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _showDriverDetailsBottomSheet(Map<String, dynamic> driver) {
    _driverSheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetColor = isDark
            ? const Color(0xFF18191A)
            : theme.colorScheme.surface;
        final textColor = theme.colorScheme.onSurface;
        final mutedColor = theme.textTheme.bodySmall?.color;
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Info Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver['Name'] ?? 'Driver',
                            style: AppWidget.boldTextFieldStyle(18.0)
                                .copyWith(color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${driver['Rating']?.toString() ?? '5.0'} • ${driver['TotalDeliveries'] ?? 0} Deliveries',
                                style: AppWidget.LightTextFieldStyle(
                                  12.0,
                                ).copyWith(color: mutedColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Driver Details
                _buildDetailRowNew(
                  'License',
                  driver['LicenseNumber'] ?? 'N/A',
                  Icons.badge,
                ),
                const SizedBox(height: 12),
                _buildDetailRowNew(
                  'Vehicle',
                  driver['VehicleNumber'] ?? 'N/A',
                  Icons.directions_car,
                ),
                const SizedBox(height: 12),
                _buildPhoneDetailRow(driver['Phone'] ?? 'N/A'),
                const SizedBox(height: 24),

                // Assign Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isAssigning
                            ? null
                            : () => _assignOrderToDriver(driver),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _isAssigning
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Assign This Driver',
                                  style: AppWidget.boldTextFieldStyle(16.0)
                                      .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    ).whenComplete(() {
      _driverSheetOpen = false;
    });
  }

  void _dismissDriverProfile() {
    if (!mounted) return;

    if (_driverSheetOpen) {
      Navigator.of(context).maybePop();
      _driverSheetOpen = false;
    }

    setState(() {
      _selectedDriver = null;
      _isAssigning = false;
    });
  }

  Widget _buildDetailRowNew(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF242526)
        : theme.colorScheme.surface;
    final iconBg = isDark
        ? _primary.withOpacity(0.16)
        : _primary.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF353A3F) : _primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppWidget.LightTextFieldStyle(11.0).copyWith(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppWidget.boldTextFieldStyle(13.0).copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build phone detail row with clickable call functionality
  Widget _buildPhoneDetailRow(String phoneNumber) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _makePhoneCall(phoneNumber),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF242526)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF353A3F) : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone, color: _primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone',
                    style: AppWidget.LightTextFieldStyle(
                      11.0,
                    ).copyWith(color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    phoneNumber,
                    style: AppWidget.boldTextFieldStyle(
                      13.0,
                    ).copyWith(color: _primary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_outward, color: _primary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _assignOrderToDriver(Map<String, dynamic> driver) async {
    try {
      setState(() => _isAssigning = true);

      final driverId = driver['Id'];

      // Assign order to driver (sets status to 'Assigned')
      await DatabaseMethods().assignOrderToDriver(widget.orderId, driverId);

      if (mounted) {
        // Show notification that order was sent to driver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order sent to ${driver['Name']}. Waiting for acceptance...',
                    style: AppWidget.boldTextFieldStyle(
                      14.0,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait for driver response (30 second timeout)
        bool orderAccepted = false;
        int waitTime = 0;

        while (waitTime < 30 && !orderAccepted) {
          await Future.delayed(const Duration(seconds: 1));
          waitTime++;

          try {
            final order = await DatabaseMethods().getOrder(widget.orderId);
            if (order.exists) {
              final status = (order['Status'] ?? 'Assigned').toString();
              if (status == 'Accepted' ||
                  status == 'Confirmed' ||
                  status == 'Received' ||
                  status == 'In Transit' ||
                  status == 'Delivered') {
                orderAccepted = true;
              } else if (status == 'Pending') {
                // Driver declined - order went back to pending
                orderAccepted = false;
                break;
              }
            }
          } catch (e) {
            print('Error checking order status: $e');
          }
        }

        setState(() => _isAssigning = false);

        if (orderAccepted && mounted) {
          // Driver accepted - proceed to payment page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Driver ${driver['Name']} accepted your order!',
                    style: AppWidget.boldTextFieldStyle(
                      14.0,
                    ).copyWith(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: _accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              duration: const Duration(seconds: 2),
            ),
          );

          // Get order data and navigate to billing page
          try {
            final order = await DatabaseMethods().getOrder(widget.orderId);
            if (order.exists && mounted) {
              final orderData = order.data() as Map<String, dynamic>;
              final helper = SharedpreferenceHelper();
              final userEmail = await helper.getUserEmail();

              final paymentResult = await Navigator.of(context)
                  .push<BillingResult>(
                    MaterialPageRoute(
                      builder: (context) => BillingPage(
                        orderId: widget.orderId,
                        amount:
                            double.tryParse(
                              orderData['Price']?.toString() ?? '0',
                            ) ??
                            0.0,
                        customerName: orderData['SenderName'] ?? 'Customer',
                        customerPhone: orderData['SenderPhone'] ?? '',
                        customerEmail: userEmail ?? '',
                      ),
                    ),
                  );

              // Handle payment result and navigate to home
              if (paymentResult != null && mounted) {
                // Update order status in Firestore with payment info
                try {
                  await DatabaseMethods().updateOrderPaymentStatus(
                    userId: await helper.getUserId() ?? '',
                    orderId: paymentResult.orderId,
                    paymentStatus: paymentResult.paymentStatus,
                    paymentMethod: paymentResult.paymentMethod,
                    paymentProvider: paymentResult.paymentProvider,
                    paidAmount: paymentResult.paidAmount,
                    transactionId: paymentResult.transactionId,
                  );
                } catch (e) {
                  print('Error updating payment status: $e');
                }
              }

              // Always navigate to home page after payment interaction
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const BottomNav()),
                  (route) => false,
                );
              }
            }
          } catch (e) {
            print('Error navigating to billing: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: Could not load order details'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else if (mounted) {
          // Driver declined or timeout
          _dismissDriverProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.close, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      waitTime >= 30
                          ? 'Driver did not respond. Try another driver.'
                          : 'Driver declined your order. Try another driver.',
                      style: AppWidget.boldTextFieldStyle(
                        14.0,
                      ).copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _mapReady = true;
    _fitMarkersBounds();
  }

  Future<void> _fitMarkersBounds() async {
    if (!_mapReady || _markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      minLat = minLat > lat ? lat : minLat;
      maxLat = maxLat < lat ? lat : maxLat;
      minLng = minLng > lng ? lng : minLng;
      maxLng = maxLng < lng ? lng : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final secondaryText = theme.textTheme.bodySmall?.color;
    _ensureMarkerIcons(theme.brightness);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: Text(
          'Select Driver',
          style: AppWidget.boldTextFieldStyle(
            22.0,
          ).copyWith(color: theme.appBarTheme.foregroundColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 2,
        shadowColor: isDark ? Colors.black54 : _primary.withOpacity(0.3),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseMethods().getAvailableDriversStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Drivers',
                      style: AppWidget.boldTextFieldStyle(18.0).copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: AppWidget.LightTextFieldStyle(12.0).copyWith(
                        color: secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final drivers = docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['Id'] = doc.id;
                // Handle field names (try different variations)
                data['Name'] =
                    data['Name'] ??
                    data['name'] ??
                    data['FullName'] ??
                    data['full_name'] ??
                    'Driver';
                data['Phone'] =
                    data['Phone'] ??
                    data['phone'] ??
                    data['PhoneNumber'] ??
                    data['phone_number'] ??
                    'N/A';
                data['CurrentLat'] =
                    (data['CurrentLat'] as num?)?.toDouble() ?? 0.0;
                data['CurrentLng'] =
                    (data['CurrentLng'] as num?)?.toDouble() ?? 0.0;
                data['Rating'] = data['Rating'] ?? 5.0;
                data['TotalDeliveries'] = data['TotalDeliveries'] ?? 0;
                data['IsAvailable'] = data['IsAvailable'] ?? false;
                return data;
              })
              .where(
                (driver) =>
                    _isDriverOnline(driver) &&
                    (driver['CurrentLat'] as num) != 0.0 &&
                    (driver['CurrentLng'] as num) != 0.0,
              )
              .toList();

          if (drivers.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 60,
                      color: _teal.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Drivers Available',
                      style: AppWidget.boldTextFieldStyle(18.0).copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again in a few minutes',
                      style: AppWidget.LightTextFieldStyle(14.0).copyWith(
                        color: secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final currentMarkers = _buildDriverMarkers(drivers);
          final currentPolylines = _buildRoutePolylines();
          _markers
            ..clear()
            ..addAll(currentMarkers);
          _polylines
            ..clear()
            ..addAll(currentPolylines);

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                onMapCreated: _onMapCreated,
                style: isDark ? _darkMapStyle : null,
                initialCameraPosition: CameraPosition(
                  target: _pickupLatLng,
                  zoom: 14.0,
                ),
                markers: currentMarkers,
                polylines: _polylines,
              ),

              // Driver List (Bottom Sheet)
              if (drivers.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18191A) : surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2F3336)
                            : theme.dividerColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.45 : 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${drivers.length} Driver${drivers.length > 1 ? 's' : ''} Available',
                                style: AppWidget.boldTextFieldStyle(
                                  15.0,
                                ).copyWith(color: _primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 135,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: drivers.length,
                            itemBuilder: (context, index) {
                              final driver = drivers[index];
                              final isSelected =
                                  _selectedDriver?['Id'] == driver['Id'];
                              return _buildDriverCard(driver, isSelected);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phoneNumber = driver['Phone']?.toString() ?? '';
    final rating = (driver['Rating'] as num?)?.toDouble() ?? 5.0;

    return GestureDetector(
      onTap: () => _selectDriver(driver),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _primary.withOpacity(0.1),
                    _secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  isDark ? const Color(0xFF242526) : theme.colorScheme.surface,
                  isDark ? const Color(0xFF1F2022) : Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _primary
                : isDark
                ? const Color(0xFF353A3F)
                : theme.dividerColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primary.withOpacity(0.2)
                  : Colors.black.withOpacity(isDark ? 0.28 : 0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              driver['Name'] ?? 'Driver',
              style: AppWidget.boldTextFieldStyle(
                10.5,
              ).copyWith(color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(isDark ? 0.18 : 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 10),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppWidget.boldTextFieldStyle(
                      8.5,
                    ).copyWith(
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (phoneNumber.isNotEmpty)
              Flexible(
                child: GestureDetector(
                  onTap: () => _makePhoneCall(phoneNumber),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primary,
                          isDark ? const Color(0xFF087383) : _primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            phoneNumber,
                            style: AppWidget.LightTextFieldStyle(8.5).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Clean phone number - remove spaces, dashes, parentheses
      final cleanedNumber = phoneNumber
          .replaceAll(RegExp(r'[\s\-\(\)]+'), '')
          .trim();

      if (cleanedNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid phone number'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try tel: scheme first
      final Uri telUri = Uri(scheme: 'tel', path: cleanedNumber);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        // Fallback: try with +88 prefix for Bangladesh
        final Uri telUriWithCountry = Uri(
          scheme: 'tel',
          path:
              '+88${cleanedNumber.startsWith('0') ? cleanedNumber.substring(1) : cleanedNumber}',
        );

        if (await canLaunchUrl(telUriWithCountry)) {
          await launchUrl(telUriWithCountry);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Phone app not available. Number: $cleanedNumber',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Phone call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
